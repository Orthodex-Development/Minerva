class FeatureIdentifier

  attr_accessor :tokenizer, :features, :aspect_hash
  alias :f :features
  alias :t :tokenizer

  def initialize(tokenizer)
    @aspect_hash = {}
    @tokenizer = tokenizer
    prune
    extract_aspects
  end

  private

  def prune
    # redundancy pruning: remove single world proper nouns
    @features = t.phrases - t.proper_nouns
    # TODO find more pruning methods
  end

  def extract_aspects
    t.get_sentences.each do |s|
      a = s.split(" ") & t.adjectives
      if !a.nil?
        p =  s.match(/.*\s#{f.join("|")}.*/i).to_a
        if !p.empty? && !p.nil?
          aspect_sentence = s
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
end
