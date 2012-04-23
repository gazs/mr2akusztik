#!/usr/bin/env python
from functools import partial

import re
from time import time
from urlparse import urlparse

import requests
from pyquery import PyQuery as pq

USER_AGENT = ("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:11.0) "
              "Gecko/20100101 Firefox/11.0")

#REFERER = "http://www.mr2.hu/akusztikplaya/player_mp3_js.swf"
REFERER = "http://www.mr2.hu/akusztikplaya"

base_url = "http://www.mr2.hu/"
endpoints = {
        "session": "splash.php?reload=L2luZGV4LnBocA==",
        "performers":"akusztikplaya/ajax.php?func=loadperformers&divid=akusztik",
        "tracks": "akusztikplaya/ajax.php?func=loadtracks&perf={0}"
        }

s = requests.session()
headers = {
    'User-Agent': USER_AGENT,
    'Referer': REFERER,
    'Accept-Encoding': "gzip,deflate",
    'Accept-Language': "en-US,en;q=0.8",
}

#s.get(base_url.format(endpoints["session"]), headers=headers)
s.get(base_url + endpoints["session"], headers=headers)

def get_performers():
    r = s.get(base_url + endpoints['performers'])
    d = pq(r.text)
    return [el.text for el in d(".ak_performer")]


class Akusztik(object):
    def __init__(self, performer):
        self.performer = performer

    def _get_xml(self):
        if not hasattr(self, "_xml"):
            r = s.get(base_url + endpoints['tracks'].format(self.performer))
            self._xml = pq(r.text.encode("utf8"))
            return self._xml
        else:
            return self._xml

    @property
    def tracks(self):
        xml = self._get_xml()
        return [(el.attrib["position"], el.attrib["name"]) for el in xml("Cue")]

    @property
    def albumart_url(self):
        xml = self._get_xml()
        return xml("PerformerPicture").attr("value")

    def _get_urlprefix(self):
        xml = self._get_xml()
        return xml("UrlPrefix").attr("value")

    def _get_ssdcode(self):
        url = self._get_urlprefix() + ".mp3.js?hashid={0}".format(int(time()*1000))
        r = s.get(url, headers=headers)
        return re.search('{([0-9A-Z-]*)}', r.text).group(0)

    def download(self):
        url = "{0}-{1}.mp3?ssdcode={2}".format(self._get_urlprefix(),
                                               0,
                                               self._get_ssdcode())

        print url

        r = s.get(url, headers=headers)
        print r.request.headers
        #print r.status_code
        pass

def main():
    #get_performers()
    #get_tracks("30Y")
    a = Akusztik("30Y")
    a.download()
    

if __name__ == '__main__':
    main()
