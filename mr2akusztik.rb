#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require 'net/http'
require 'nokogiri'
require 'uri'
require 'progressbar'
require "getopt/long"

$http = Net::HTTP.new('www.mr2.hu')

def get_session
  path = '/index.php'
  resp, data = $http.get(path, nil)
  cookie = resp.response['set-cookie']
  return cookie
end

def loadperformers(session_cookie)
  path = '/akusztikplaya/ajax.php?func=loadperformers&divid=akusztik'
  headers = { 'Cookie' => session_cookie }
  resp, data = $http.get(path, headers)
  Nokogiri::HTML(data).css(".ak_performer").each do |perf|
    puts perf.content
  end
end

def loadtracks(session_cookie, performer)
  path = '/akusztikplaya/ajax.php?func=loadtracks&perf=' + URI.escape(performer)
  headers = { 'Cookie' => session_cookie }
  resp, data = $http.get(path, headers)
  return Nokogiri::XML(data)

end

def get_albumart(xml)
  return xml.xpath("Cuelist/PerformerPicture/@value")
end

def get_urlprefix(xml)
  return xml.xpath("/Cuelist/UrlPrefix/@value").to_s
end

def get_ssdcode(urlprefix)
  scheme, userinfo, host, port, registry, path, opaque, query, fragment = URI.split(urlprefix)
  http = Net::HTTP.new(host,port)
  url =  path + ".mp3.js?hashid=" + (Time.now.to_i * 1000).to_s
  resp, data = http.get(url, nil)
  return data[/\{[0-9A-Z-]*\}/]
end

def download(performer, outfile, dialogness)
  user_agent = "Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.1 (KHTML, like Gecko) Chrome/6.0.422.0 Safari/534.1"
  referer = "http://www.mr2.hu/akusztikplaya/player_mp3_js.swf"

  session_cookie = get_session()
  xml = loadtracks(session_cookie,performer)

  puts get_albumart(xml)
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
    f = open("#{outfile}", 'wb')
    tempvar = 0
    http.request_get(path + "?ssdcode=" + ssdcode, headers) do |response|
      size = response['Content-Length']
      pbar = ProgressBar.new("Downloading", size.to_i) 
      response.read_body do |segment|
        f.write(segment)
        pbar.inc(segment.size.to_i) if !dialogness
        if dialogness
          tempvar += segment.size.to_i
          # miért nem inkrementálja a pbar.currentet??
          #puts "#{tempvar}/#{size} = #{(tempvar.to_f/size.to_f)*100}%\tpbar.current=#{pbar.current}"
          # ----- addig is. WORK, AROUND THE WORKAROUND, THE WORK, AROUND THE WORKAROUND
          # http://www.youtube.com/watch?v=JFwQoqbWgSs&feature=avmsc2
          puts "#{((tempvar.to_f/size.to_f)*100)}"
        end
      end
      pbar.finish
    end
    f.close
  end
end

opt = Getopt::Long.getopts(
      ["--list", "-l", Getopt::BOOLEAN],
      ["--performer", "-p", Getopt::OPTIONAL],
      ["--output", "-o", Getopt::OPTIONAL],
      ["--help", "-h", Getopt::BOOLEAN],
      ["--dialog", "-d", Getopt::BOOLEAN],
      ["--cue", "-c", Getopt::BOOLEAN]
)

if opt["list"]
  session = get_session()
  loadperformers(session)
end
if opt["performer"] && !opt["cue"]
  download(opt["performer"], opt["output"] ||= opt["performer"] + ".mp3", opt["dialog"])
end

if opt["performer"] &&opt["cue"]
  session = get_session()
  xml = loadtracks(session, opt["performer"])
  puts "TITLE \"MR2 Akusztik\""
  puts "PERFORMER \"#{xml.xpath('/Cuelist/Performer/@value')}\""
  puts "FILE \"#{opt["output"] ||= opt["performer"] + ".mp3" }\" MP3" 
  tracknum = 0
  xml.css("Cue").each do |track|
	tracknum += 1
    puts "  TRACK #{"%02d" % tracknum} AUDIO"
    puts "    TITLE \"#{track["name"]}\""
    puts "    PERFORMER \"#{opt["performer"]}\""
    puts "    INDEX 01 #{Time.at(track["position"].to_i).gmtime.strftime('%M:%S')}"
  end
end

if opt["help"] || opt.length == 0
  puts """
MR2 Akusztik letöltő

Használat: mr2akusztik.rb [-p|--performer ELŐADÓ] [-o|--output KIMENET (opcionális)]

Egyéb lehetőségek:
  -l, --list      Összes elérhető előadó listázása
  -h, --help      Ez a szöveg
  -c, --cue       Cuesheet generálása STDOUT-ra
  -d, --dialog    Zenity vagy hasonlóhoz használható folyamatkiköpő
  """
end
