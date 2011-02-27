# MR2 letöltőszkript

_Kérlek, csak magáncélra, és főleg semmi gonosz dologra ne használd ezt az eszközt. Szeretném, ha a Rádió továbbra is megosztaná a kincseit velünk, s ugye te is?_

## Ruby 1.9.2-vel

Nem jó a default Getopt gem, ezen a forkon ki van javítva  hiba, használd ezt: https://github.com/shurizzle/getopt/


## Egyszerűen összecsapott, de működő "GUI":

Zenity felhasználásával

    mr2.sh

##Parancssorból

    mr2akusztik.rb [-p|--performer ELŐADÓ] [-o|--output KIMENET (opcionális)]

### Egyéb lehetőségek:

    -l, --list      Összes elérhető előadó listázása
    -h, --help      Ez a szöveg
    -c, --cue       Cuesheet generálása STDOUT-ra
    -d, --dialog    Zenity vagy hasonlóhoz használható folyamatkiköpő

#### Mire jó a cuesheet?

     mp3splt -c [cuesheet] [letöltött album.mp3] # számokra bontja és taggeli a felvételt
