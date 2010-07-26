require 'rubygems'
require 'net/http'
require 'nokogiri'
require 'uri'
require 'progressbar'
require 'pp'

$http = Net::HTTP.new('www.mr2.hu')

def get_session
  path = '/index.php'
  resp, data = $http.get(path, nil)
  cookie = resp.response['set-cookie'].split('; ')[0]
  return cookie
end

def loadperformers(session_cookie)
  # TODO: valami hasnzálható formában adja vissza
  path = '/akusztikplaya/ajax.php?func=loadperformers&divid=akusztik'
  headers = { 'Cookie' => session_cookie }
  resp, data = $http.get(path, headers)
  return Nokogiri::HTML(data).css(".ak_performer")
end

def loadtracks(session_cookie, performer)
  path = '/akusztikplaya/ajax.php?func=loadtracks&perf=' + URI.escape(performer)
  headers = { 'Cookie' => session_cookie }
  resp, data = $http.get(path, headers)
  return Nokogiri::XML(data)
end

def get_urlprefix(xml)
  xml.xpath("/Cuelist/UrlPrefix/@value").to_s
end

def get_ssdcode(urlprefix)
  scheme, userinfo, host, port, registry, path, opaque, query, fragment = URI.split(urlprefix)
  http = Net::HTTP.new(host,port)
  url =  path + ".mp3.js?hashid=" + (Time.now.to_i * 1000).to_s
  resp, data = http.get(url, nil)
  return data[/\{[0-9A-Z-]*\}/]
end

def download(performer)
  user_agent = "Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.1 (KHTML, like Gecko) Chrome/6.0.422.0 Safari/534.1"
  referer = "http://www.mr2.hu/akusztikplaya/player_mp3_js.swf"

  session_cookie = get_session()
  xml = loadtracks(session_cookie,performer)
  urlprefix = get_urlprefix(xml)
  ssdcode = get_ssdcode(urlprefix)
  
  scheme, userinfo, host, port, registry, path, opaque, query, fragment = URI.split(urlprefix)
  http = Net::HTTP.new(host,port)
  headers = {
    'Cookie'=> session_cookie,
    'User-agent' => user_agent,
    'Referer'=> referer
  }
  Net::HTTP.start(host,port) do |http|
    f = open("#{ARGV[0]}.mp3", 'wb')
    http.request_get(path + "?ssdcode=" + ssdcode, headers) do |response|
      size = response['Content-Length']
      pbar = ProgressBar.new("Downloading", size.to_i) 
      response.read_body do |segment|
        f.write(segment)
        pbar.inc(segment.size.to_i)
      end
    end
    f.close
    pbar.finish
  end
end


download(ARGV[0])
