class FeatureIdentifier
  require "byebug"
  require "stemmer"
  require_relative "tokenizer"

  attr_accessor :tokenizer, :features, :aspect_hash
  alias :f :features
  alias :t :tokenizer

  def initialize(tokenizer)
    @aspect_hash = {}
    @tokenizer = tokenizer
    clean
    extract_aspects
  end


  def remove_punctuations
    @features.map! do |phrase|
      temp = phrase.dup
      temp.slice! /\p{P}/ =~ phrase if /\p{P}/ =~ phrase
      temp
    end
    byebug
    # @features.map! { |phrase| phrase.slice! /\p{P}/ =~ phrase if /\p{P}/ =~ phrase }
  end

  private

  def clean
    # redundancy pruning: remove single world proper nouns
    @features = t.phrases - t.proper_nouns
    puts "features size after redundancy pruning: #{@features.size}"
    remove_punctuations
    puts "features size after removing punctuations: #{@features.size}"
    clean_stop_words
    puts "features size after cleaning stop words: #{@features.size}"
    stem
    puts "features size after porter stemming: #{@features.size}"
    clean_duplicates
    puts "features size after duplicacy pruning: #{@features.size}"
  end

  def extract_aspects
    t.get_sentences.each do |line|
      a = line.split(" ") & t.adjectives
      if !a.nil?
        p =  line.match(/.*\s#{@features.join("|")}.*/i).to_a
        if !p.empty? && !p.nil?
          aspect_sentence = line
          p.each do |phrase|
            @aspect_hash[phrase.to_sym] = {}
            @aspect_hash[phrase.to_sym][:opinions] = a
            @aspect_hash[phrase.to_sym][:sentences] = aspect_sentence
          end
        end
      end
    end
    @aspect_hash
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

  def map_proper_nouns
    #code
  end

  def clean_stop_words
    File.open("stopwords.txt", "r") do |file|
      stop_word = file.readline
      @features.delete(stop_word) if @features.include? stop_word
    end
  end

  def stem
    @features.map! { |phrase| phrase.stem if t.proper_nouns.include? phrase }
  end
end
