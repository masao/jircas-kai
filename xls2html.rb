#!/usr/bin/env ruby

require "erb"
require 'flickraw'
require "roo"
require "yaml"

# Flickr embed code:
#    <a data-flickr-embed="true" data-header="true" data-footer="true" data-context="true"  href="https://www.flickr.com/photos/jircas/36856617175/in/dateposted/" title="果物屋"><img src="https://farm5.staticflickr.com/4399/36856617175_793f6931f1_k.jpg" width="2048" height="1425" alt="果物屋"></a><script async src="//embedr.flickr.com/assets/client-code.js" charset="utf-8"></script>

class PageTemplate
  include ERB::Util
  def initialize(template)
    @template = template
  end
  def to_html(param)
    tmpl = open(@template){|io| io.read }
    erb = ERB.new(tmpl, $SAFE, "-")
    erb.filename = @template
    param[:content] = erb.result(binding)
    layout = open("template/layout.html.erb"){|io| io.read }
    erb = ERB.new(layout, $SAFE, "-")
    erb.filename = "template/layout.html.erb"
    erb.result(binding)
  end
end

apikey = YAML.load(open("flickr-key.yml"){|io| io.read })
FlickRaw.api_key = apikey["KEY"]
FlickRaw.shared_secret = apikey["SECRET"]

template = PageTemplate.new("template/album.html.erb")

album_list = {}
xlsx = Roo::Excelx.new(ARGV[0])
xlsx.each_row_streaming(pad_cells: true) do |row|
  flickr_id, slide_no, url, auther, author_en, affliation, date, project, title, title_en, country, country_en, area, area_en, category, keywords, description, = row
  #p slide_no.value
  category_id = slide_no.value.split(/-/)[0,2].join("-")
  if category_id == "01-001"
    album_list[category_id] ||= []
    album_list[category_id] << row
  end
end

album_list.each do |category, album|
  photos ||= []
  album.each do |photo|
    info = flickr.photos.getInfo(photo_id: photo[0].value)
    photos << {
      flickr_id: photo[0].value,
      title: photo[8].value,
      secret: info["secret"],
    }
  end
  data = {
    category: category,
    photos: photos,
  }
  open("#{category}.html", "w") do |io|
    io.print template.to_html(data)
  end
end
