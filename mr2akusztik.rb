require 'rubygems'
require 'net/http'
require 'nokogiri'
require 'uri'

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
  puts "letöltöm, nemtomhova, nemtommiért."
  Net::HTTP.start(host,port) { |http|
    resp = http.get(path + "?ssdcode=" + ssdcode, headers)
    open("akusztik.mp3", "wb") { |file|
      file.write(resp.body)
    }
  }    
end


download("30Y")
