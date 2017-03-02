class Tokenizer
  require 'engtagger'

  attr_accessor :review, :sentences, :tagger, :tagged

  def initialize(review = nil, movie_id = 10)
    @review = get_review
    @tagger = EngTagger.new
    @tagged = @tagger.add_tags(@review)
  end

  def get_review
    f = File.open("test.txt", "r")
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
