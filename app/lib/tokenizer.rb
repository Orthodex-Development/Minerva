class Tokenizer
  require 'engtagger'

  attr_accessor :review, :sentences, :tagger

  def initialize(review)
    # For development
    @review = get_review
    #@review = review
    @tagger = EngTagger.new
    @tagged = @tagger.add_tags(@review)
  end

  def get_review
    f = File.open("text2.txt", "r")
    review = f.read
    f.close
    review
  end

  def phrases
    @tagger.get_words(@review).keys
  end

  def get_sentences
    @tagger.get_sentences(@review)
  end

  def nouns
    @tagger.get_nouns(@tagged).keys
  end

  def proper_nouns
    @tagger.get_proper_nouns(@tagged).keys
  end

  def adjectives
    @tagger.get_adjectives(@tagged).keys
  end
end
