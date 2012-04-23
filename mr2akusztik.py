#!/usr/bin/env python
from functools import partial

import re
import shutil

import requests
from pyquery import PyQuery as pq

requests.defaults.defaults['encode_uri'] = False # TODO: better way?


base_url = "http://www.mr2.hu/"
endpoints = {
        "performers":"akusztikplaya/ajax.php?func=loadperformers&divid=akusztik",
        "tracks": "akusztikplaya/ajax.php?func=loadtracks&perf={0}"
}


def _get(endpoint, param=None):
    r = requests.get(base_url + endpoints[endpoint].format(param))
    response = r.text.encode("utf8")
    return response

def get_performers():
    response = _get("performers")
    d = pq(response)
    return [el.text for el in d(".ak_performer")]


class Akusztik(object):
    def __init__(self, performer):
        self.performer = performer

        xml = pq(_get("tracks", self.performer))
        self.tracks = [(el.attrib["position"], el.attrib["name"]) for el in xml("Cue")]
        self.albumart_url = xml("PerformerPicture").attr("value")
        self.urlprefix = xml("UrlPrefix").attr("value")

    def _get_ssdcode(self):
        url = self.urlprefix + ".mp3.js?hashid={0}".format(0)
        r = requests.get(url) 
        return re.search('{([0-9A-Z-]*)}', r.text).group(0)

    def download(self, destination=None):
        url = "{0}-{1}.mp3?ssdcode={2}".format(self.urlprefix, 0, self._get_ssdcode())

        r = requests.get(url)

        with open(destination, 'wb') as fp:
            shutil.copyfileobj(r.raw, fp)



def main():
    a = Akusztik("30Y")
    a.download("/home/gazs/Desktop/30yakusztik.mp3")
    

if __name__ == '__main__':
    main()
