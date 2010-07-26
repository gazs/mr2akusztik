PERFORMER=$(ruby mr2akusztik.rb --list | zenity --list --column "Előadó")


SAVEURL=$(zenity --file-selection --save --filename "$PERFORMER.mp3" --title "Hova töltsem le az MR2 Akusztik felvételt")

ruby mr2akusztik.rb -p "$PERFORMER" -o "$SAVEURL" -d | zenity --progress --auto-kill --auto-close --title "MR2 Akusztik-$PERFORMER" --text "letöltés..."

