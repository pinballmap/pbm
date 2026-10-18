class SearchController < ApplicationController
  def autocomplete
    term = params[:term].to_s
    return render json: [] if term.length < 3

    locations = Location
      .autocomplete_by_name(term)
      .map do |l|
        {
          label: "#{l.name} (#{[ l.city, l.state ].reject(&:blank?).join(', ')})",
          name: l.name,
          id: l.id,
          type: "location"
        }
      end

    cities = Location
      .matching_words(:city, term)
      .select("DISTINCT ON (city, state) city, state")
      .order("city, state")
      .map { |l| { label: l.city_and_state, city: l.city, state: l.state, type: "city" } }

    render json: locations + cities
  end
end
