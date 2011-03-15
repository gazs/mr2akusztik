# MR2 letöltőszkript

_Kérlek, csak magáncélra, és főleg semmi gonosz dologra ne használd ezt az eszközt. Szeretném, ha a Rádió továbbra is megosztaná a kincseit velünk, s ugye te is?_

## Ruby 1.9.2-vel

Nem jó a default Getopt gem, ezen a forkon ki van javítva  hiba, használd ezt: https://github.com/shurizzle/getopt/


## Egyszerűen összecsapott, de működő "GUI":

Zenity felhasználásával

    mr2.sh

## Parancssorból

    mr2akusztik.rb [-p|--performer ELŐADÓ] [-o|--output KIMENET (opcionális)]

### Egyéb lehetőségek:

    -l, --list      Összes elérhető előadó listázása
    -h, --help      Ez a szöveg
    -c, --cue       Cuesheet generálása STDOUT-ra
    -d, --dialog    Zenity vagy hasonlóhoz használható folyamatkiköpő

#### Mire jó a cuesheet?

     mp3splt -c [cuesheet] [letöltött album.mp3] # számokra bontja és taggeli a felvételt

## Donate

Ha hasznát vetted ennek a scriptnek, meghívhatnál egy csokira-sörre:

<form action="https://www.paypal.com/cgi-bin/webscr" method="post">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="encrypted" value="-----BEGIN PKCS7-----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-----END PKCS7-----
">
<input type="image" src="https://www.paypalobjects.com/WEBSCR-640-20110306-1/en_US/i/btn/btn_donateCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
<img alt="" border="0" src="https://www.paypalobjects.com/WEBSCR-640-20110306-1/en_US/i/scr/pixel.gif" width="1" height="1">
</form>

