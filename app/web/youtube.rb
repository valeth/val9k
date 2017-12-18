require "nokogiri"
require "date"

# String -> DateTime
def parse_date(date_str)
  if date_str.empty?
    DateTime.now
  else
    DateTime.parse(date_str)
  end
end

# XML -> Hash
def build_hash(xml)
  {
    title:     xml.css("title").text,
    id:        xml.xpath("yt:videoId").text,
    url:       xml.css("link[rel='alternate']").attribute("href").value,
    author:    xml.css("author > name").text,
    channel:   xml.xpath("yt:channelId").text,
    published: parse_date(xml.css("published").text),
    updated:   parse_date(xml.css("updated").text)
  }
end

# XML -> Hash|nil
def process_youtube_xml(xml)
  doc = Nokogiri::XML(xml)
  entry = doc.at("entry")
  return unless entry
  build_hash(entry)
end
