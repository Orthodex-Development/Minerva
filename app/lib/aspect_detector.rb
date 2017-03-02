module AspectDetector
  attr_accessor :aspects

  def initialize(aspect_hash = {})
    @aspects = aspect_hash
    merge_aspects
  end

  def merge_aspects
    # TODO: Merge aspects based on opinion set match
  end
end
