module WordSearchable
  extend ActiveSupport::Concern

  class_methods do
    # Every word in term must appear somewhere in column, in any order, ignoring accents and punctuation.
    # "Friends Gr" matches "Friends Monroe Grill". A blank term matches everything.
    # column is interpolated, so only pass trusted column names.
    def words_match_sql(column, term)
      words = term.to_s.split
      return "TRUE" if words.empty?

      # The trigram index can't narrow results by words under 3 characters, so if every word is
      # that short, match the whole phrase instead of scanning the table.
      words = [ term.to_s ] if words.all? { |word| word.length < 3 }

      words.map { |word| sanitize_sql_array([ "clean_items(#{column}) ilike '%' || clean_items(?) || '%'", word ]) }.join(" AND ")
    end

    def matching_words(column, term)
      where(words_match_sql(column, term))
    end
  end
end
