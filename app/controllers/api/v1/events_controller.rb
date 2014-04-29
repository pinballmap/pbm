module Api
  module V1
    class EventsController < InheritedResources::Base
      respond_to :xml, :json
      has_scope :region

      def index
        events = apply_scopes(Event)

        events.select! {|e| e.end_date ? (e.end_date >= Date.today - 7) : e}
        events.select! {|e| (e.start_date && !e.end_date) ? (e.start_date >= Date.today - 7) : e}

        if (params[:sorted] && events.size > 0)
          sorted_events = Hash.new
          events.each {|e|
            category = e.category.blank? ? 'General' : e.category
            (sorted_events[category] ||= []) << e
          }
          respond_with [sorted_events], root: false
        else
          respond_with events, root: false
        end
      end

    end
  end
end