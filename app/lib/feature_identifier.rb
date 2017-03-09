class FeatureIdentifier
  include AspectDetector

  attr_accessor :tokenizer, :features, :aspect_hash, :adjectives
  alias :f :features
  alias :t :tokenizer

  def initialize(tokenizer)
    @aspect_hash = {}
    @tokenizer = tokenizer
    @adjectives = t.adjectives
    clean
    extract_features
    classify_aspects
  end

  private

  def clean
    # redundancy pruning: remove single world proper nouns
    @features = t.phrases - t.proper_nouns
    puts "features size after redundancy pruning: #{@features.size}"
    clean_stop_words
    puts "features size after cleaning stop words: #{@features.size}"
    clean_duplicates
    puts "features size after duplicacy pruning: #{@features.size}"
    remove_punctuations
    puts "features size after removing punctuations: #{@features.size}"
    #stem
    #puts "features size after porter stemming: #{@features.size}"
  end

  def extract_features
    t.get_sentences.each do |line|
      # For each sentence
      p =  line.scan(/(#{@features.join("|")})/i).flatten
      if !p.empty? && !p.nil?
        # If it containes a feature, extract all adjectives
        a = line.split(" ") & @adjectives
        if !a.nil? && !a.empty?
          # For each feature in the sentence
          p.each do |phrase|
            # the nearby adjective is recorded as its effective
            # opinion. A nearby adjective refers to the adjacent
            # adjective that modifies the noun/noun phrase that is a
            # frequent feature.
            opinion_phrase = line.split(/#{p.join("|")}/i)[p.find_index phrase]
            opinions = opinion_phrase.scan(/(#{a.join("|")})/i).flatten

            if !opinions.empty?
              @aspect_hash[phrase.to_sym] = {}
              @aspect_hash[phrase.to_sym][:opinions] = opinions
              @aspect_hash[phrase.to_sym][:sentences] = opinion_phrase
            end
          end
        end
      end
    end
    puts "FeatureIdentifier: No of extracted features are: #{aspect_hash.keys.size}"
    map_proper_nouns
  end

  def map_proper_nouns
    # TODO: Map pronouns to proper nouns
  end

  def clean_duplicates
    @features.each do |phrase|
      match_data = @features.select { |feature| feature.match /\s?(?=[a-z])#{phrase}(?![a-z])\s?/i }

      if !match_data.empty?
        imp_feature = match_data.max_by do |element|
          element.size
        end

        # puts "\nMatching phrase for #{phrase} found: #{match_data}"
        @features -= match_data
        @features << imp_feature
      end
    end
  end

  def remove_punctuations
    @features.map! do |phrase|
      temp = phrase.dup
      match = temp.scan /\p{P}/
      match.each do |char|
        temp.slice! temp.index char
      end
      temp
    end
  end

  def clean_stop_words
    stop_word_dir = Rails.root.join "app/lib/stopwords.txt"
    # stop_word_dir = "stopwords.txt"
    File.open(stop_word_dir, "r").each do |line|
      stop_word = line.chomp
      @features.delete(stop_word) if @features.include? stop_word
      @adjectives.delete(stop_word) if @adjectives.include? stop_word
    end
  end

  def stem
    # User Porter Stemming on all phrases except those containing capitalized words.
    # It is safe to assume that capitalized words either are or refer to proper nouns.
    @features.map! { |phrase| /[[:upper:]]/.match(phrase) ? phrase : phrase.stem }
  end
end
