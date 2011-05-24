require "rails_admin/application_controller"

module RailsAdmin
  class ApplicationController < ::ApplicationController
    filter_access_to :all
  end

  class History < ActiveRecord::Base
    set_table_name :histories

    IGNORED_ATTRS = Set[:id, :created_at, :created_on, :deleted_at, :updated_at, :updated_on, :deleted_on]

    scope :most_recent, lambda {|table|
      where("#{retrieve_connection.quote_column_name(:table)} = ?", table).order("updated_at")
    }

    def self.get_history_for_dates(mstart, mstop, ystart, ystop)
      sql_in = ""
      if mstart > mstop
        # fix by Dan Choi
        #sql_in = (mstart + 1..12).to_a.join(", ") <== possible culprit May month bug
        sql_in = (mstart..12).to_a.join(", ")
        sql_in_two = (1..mstop).to_a.join(", ")

        results = History.find_by_sql("select count(*) as number, year, month from histories where month IN (#{sql_in}) and year = #{ystart} group by year, month")
        results_two = History.find_by_sql("select count(*) as number, year, month from histories where month IN (#{sql_in_two}) and year = #{ystop} group by year, month")

        results.concat(results_two)
      else
        #sql_in =  (mstart + 1..mstop).to_a.join(", ")  <=== may be defective too
        sql_in =  (mstart..mstop).to_a.join(", ")

        results = History.find_by_sql("select count(*) as number, year, month from histories where month IN (#{sql_in}) and year = #{ystart} group by year, month")
      end

      results.each do |result|
        result.number = result.number.to_i
      end

      add_blank_results(results, mstart, ystart)
    end

    def self.add_blank_results(results, mstart, ystart)
      # fill in an array with BlankHistory
      blanks = Array.new(5) { |i| BlankHistory.new(((mstart+i) % 12)+1, ystart + ((mstart+i)/12)) }
      # replace BlankHistory array entries with the real History entries that were provided
      blanks.each_index do |i|
        if results[0] && results[0].year == blanks[i].year && results[0].month == blanks[i].month
          blanks[i] = results.delete_at 0
        end
      end
    end
  end
end

RailsAdmin.config do |config|
  config.excluded_models << User << LocationMachineXref << MachineScoreXref

  config.model Region do
    list do
      field :motd
    end
  end
end

RailsAdmin::Adapters::ActiveRecord.module_eval do
  def all(options = {})
    if (model.name == 'Region')
      model.all(merge_order(options)).select{|v| v.id == Authorization.current_user.region_id}
    elsif (model.column_names.include?('region_id'))
      model.all(merge_order(options)).select{|v| v.region_id == Authorization.current_user.region_id}
    elsif (model.name == 'Machine')
      if (Authorization.current_user.region_id != Region.find_by_name('portland').id)
        Array.new
      else
        model.all(merge_order(options))
      end
    else
      model.all(merge_order(options))
    end
  end
end
