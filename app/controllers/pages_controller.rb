class PagesController < ApplicationController
  respond_to :html, only: %i[set_activities]
  before_action :authenticate_user!, only: %i[submitted_new_location]
  rate_limit to: 5, within: 10.minutes, only: :contact_sent
  rate_limit to: 100, within: 5.minutes, only: :recent_activity

  def contact_sent
    user = current_user.nil? ? nil : current_user
    return if is_bot? || params["contact_msg"].blank? || (!user && params["contact_email"].blank?) || params["contact_msg"].match?(/vape/) || params["contact_msg"].match?(/seo/)

    if user
      @contact_thanks = "Thanks for contacting us! If you are expecting a reply, check your spam folder or whitelist admin@pinballmap.com".freeze
      send_admin_notification({ email: params["contact_email"], name: params["contact_name"], message: params["contact_msg"] }, @region, user)
    else
      if params["security_question"] =~ /pinball/i
        @contact_thanks = "Thanks for contacting us! If you are expecting a reply, check your spam folder or whitelist admin@pinballmap.com".freeze
        send_admin_notification({ email: params["contact_email"], name: params["contact_name"], message: params["contact_msg"] }, @region, user)
      else
        flash.now[:alert] = "You failed the security test. Please go back and try again."
      end
    end
  end

  def about
    @links = {}
    @region.region_link_xrefs.each do |rlx|
      (@links[rlx.category && !rlx.category.blank? ? rlx.category : "Links"] ||= []) << rlx
    end

    @top_machines = LocationMachineXref
                    .includes(:machine)
                    .region(@region.name)
                    .select("machine_id, count(*) as machine_count")
                    .group(:machine_id)
                    .order("machine_count desc")
                    .limit(10)

    render "#{@region.name}/about" if lookup_context.find_all("#{@region.name}/about").any?
  end

  def stats
    @top_25 = ActiveRecord::Base.connection.exec_query("
select
  left(m.opdb_id,5) as opdb_id,
  split_part(min(m.name), ' (', 1) as machine_name,
  (array_agg(m.manufacturer ORDER BY m.year ASC))[1] as manufacturer,
  min(m.year) as year,
  min(m.id) as id,
  count(*) as machine_count
from
  location_machine_xrefs lmx inner join machines m on m.id=lmx.machine_id
  where m.opdb_id is not null
group by 1
order by 6 desc
limit 25")

    @locations_count_total = Location.all.count
    @machines_count_total = LocationMachineXref.all.count
    @users_count_total = User.all.count
    @user_submissions_total = UserSubmission.all.count
    @user_submissions_all = UserSubmission.where(created_at: "2019-01-01T00:00:00.00-07:00"..Date.today.end_of_day).select("created_at")

    @user_submissions_week = UserSubmission.where("created_at >= ?", 1.week.ago).count

    @top_cities = Location.select(
          [
            :city, :state, Arel.star.count.as("location_count")
          ]
        ).order(:location_count).reverse_order.group(:city, :state).limit(10)

    xid = Arel::Table.new("location_machine_xrefs")
    lid = Arel::Table.new("locations")
    @top_cities_by_machine = Location.select(
      [
        :city, :state, Arel.star.count.as("machines_count")
      ]
    ).joins(
      Location.arel_table.join(LocationMachineXref.arel_table).on(xid[:location_id].eq(lid[:id])).join_sources
    ).order(:machines_count).reverse_order.group(:city, :state).limit(10)

    @top_users = User.where("user_submissions_count > 0").select([ "username", "user_submissions_count" ]).order(user_submissions_count: :desc).limit(25)

    @this_year = Time.now.year
    @last_year = (Time.now - 1.year).year

    @machines_this_year = Machine.where(year: @this_year)
    @machines_last_year = Machine.where(year: @last_year)

    @machine_adds_this_year = UserSubmission.joins(:machine).where(machine_id: @machines_this_year, submission_type: %w[new_lmx], created_at: Time.now.beginning_of_year..Time.now.end_of_year).select([ "created_at" ])

    @machine_adds_last_year = UserSubmission.joins(:machine).where(machine_id: @machines_last_year, submission_type: %w[new_lmx], created_at: (Time.now - 1.year).beginning_of_year..Time.now.end_of_year).select([ "created_at" ])
  end

  def links
    redirect_to about_path
  end

  def high_rollers
    @high_rollers = @region.n_high_rollers(10)
  end

  def submitted_new_location
    @submit_thanks = "Thanks for your submission! Please allow us 0-7 days to review and add it. No need to re-submit it or remind us (unless it's opening day!). Note that you usually won't get a message from us confirming that it's been added.".freeze

    user = current_user
    send_new_location_notification(params, @region, user)
  end

  def suggest_new_location
    @operators = []
    @zones = []
    @states = []

    if @region
      @states = Location.where([ "region_id = ?", @region.id ]).where.not(state: [ nil, "" ]).map(&:state).uniq.sort
      @states.unshift("")

      @operators = Operator.where([ "region_id = ?", @region.id ]).map(&:name).uniq.sort
      @operators.unshift("")

      @zones = Zone.where([ "region_id = ?", @region.id ]).map(&:name).uniq.sort
      @zones.unshift("")
    end

    @location_types = LocationType.all.map(&:name).uniq.sort
    @location_types.unshift("")
  end

  def robots
    robots = File.read(Rails.root.join("config", "robots.#{Rails.env}.txt"))
    render plain: robots
  end

  def apple_app_site_association
    aasa = File.read(Rails.root + ".well-known/apple-app-site-association")
    render json: aasa
  end

  def app; end

  def privacy; end

  def store; end

  def faq; end

  def donate; end

  def profile; end

  def set_activities
    submission_type = params[:submission_type].blank? ? %w[new_lmx remove_machine new_condition new_msx confirm_location] : params[:submission_type]

    if @region && params[:submission_type]
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, region_id: @region.id, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).order("created_at DESC"), params: { submission_type: submission_type })
    elsif @region
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, region_id: @region.id, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).order("created_at DESC"))
    elsif params[:submission_type]
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).order("created_at DESC"), params: { submission_type: submission_type })
    else
      @pagy, @recent_activity = pagy(UserSubmission.where(submission_type: submission_type, created_at: "2019-05-03T07:00:00.00-07:00"..Date.today.end_of_day, deleted_at: nil).order("created_at DESC"))
    end

    if @region
      @region_fullname = "the " + @region.full_name
      @region_name = @region.name
    else
      @region_fullname = ""
      @region_name = "map"
    end
    respond_to do |format|
      format.html
    end
  end

  def recent_activity
    set_activities
    case request.request_method
    when "GET"
      render "pages/activity"
    when "POST"
      render partial: "pages/render_activity", object: @recent_activity
    else
      p "unknown request_method: #{request.request_method}"
    end
  end

  def contact
    redirect_to about_path
  end

  def flier; end

  def home
    @locations_count_total = Location.all.count
    @machines_count_total = LocationMachineXref.all.count
    @all_regions = Region.order(:state, :full_name)

    @last_updated_time = Location.maximum(:updated_at)
  end

  def inspire_profile
    user = current_user.nil? ? nil : current_user

    redirect_to profile_user_path(user.id) if user
  end
end
