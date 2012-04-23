#!/usr/bin/env python


import sys
import re
import shutil
import argparse

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
    return [el.text for el in pq(response)(".ak_performer")]


class Akusztik(object):
    def __init__(self, performer):
        self.performer = performer

        xml = pq(_get("tracks", self.performer))

        if xml("Performer").attr("value") != performer:
            raise KeyError("Performer not found")

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
    parser = argparse.ArgumentParser(description="Download mr2 akusztik")
    parser.add_argument('-p', '--performer')
    parser.add_argument('-l', '--list', action='store_true')
    parser.add_argument('-o', '--output', help="file name") 
    args = parser.parse_args()
    
    if args.list:
        for performer in get_performers():
            print performer
        return
    
    if args.performer:
        try:
            ak = Akusztik(args.performer)
            ak.download(args.output)
        except KeyError:
            print >> sys.stderr, "Performer not found."


if __name__ == '__main__':
    main()
