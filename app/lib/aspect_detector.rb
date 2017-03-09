module AspectDetector
  def classify_aspects
    hash = @aspect_hash.map do |key, value|
      response = HTTParty.get("http://rtw.ml.cmu.edu/rtw/api/json0?ent1=&lit1=#{key.to_s.split.join("+")}&predicate=*&ent2=&lit2=&agent=KI%2CKB%2CCKB%2COPRA%2COCMC")
      json = JSON.parse(response)
      if json["kind"] == "NELLQueryDemoJSON0"
        begin
          concept_array = json["items"][0]["ent1"]
          concept_array ||= json["items"][0]["predicate"]
          concept_array = concept_array.split ":"
          next [concept_array[0], value]
        rescue NoMethodError => e
          puts "AspectDetector: NoMethodError occurred for key : #{key}"
          puts "#{e.message}"
          next
        end
      else
        puts "AspectDetector: An Error ocurred: #{json["message"]}"
        @aspect_hash.delete(key)
      end
    end
    @aspect_hash = hash.compact.to_h
    puts "AspectDetector: aspect_hash => #{aspect_hash}"
  end
end
