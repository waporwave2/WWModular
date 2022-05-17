#!/usr/bin/env sh
set -e

echo 'please set web_version=true'
read -r -p "continue? [y/n] " response
case "$response" in
    [yY][eE][sS]|[yY])
        # pass
        ;;
    *)
        exit 1
        ;;
esac
pico8 wwmodular.p8 -export "-f wwmodular.html"

echo 'please set web_version=false'
read -r -p "continue? [y/n] " response
case "$response" in
    [yY][eE][sS]|[yY])
        # pass
        ;;
    *)
        exit 1
        ;;
esac
pico8 wwmodular.p8 -export "-i 36 -s 2 -c 16 -f wwmodular.bin -e examples/ -e samples/"
# -e folder doesn't work... 
# https://www.lexaloffle.com/bbs/?tid=47834

# https://www.lexaloffle.com/dl/docs/pico-8_manual.html#Binary_Applications_
# By default, the cartridge label is used as an icon with no transparency. To specify an icon from the sprite sheet, use -i and optionally -s and/or -c to control the size and transparency.
#   -I N  Icon index N with a default transparent colour of 0 (black).
#   -S N  Size NxN sprites. Size 3 would be produce a 24x24 icon.
#   -C N  Treat colour N as transparent. Use 16 for no transparency.
# For example, to use a 2x2 sprite starting at index 32 in the sprite sheet, using colour 12 as transparent:
#   EXPORT -I 32 -S 2 -C 12 MYGAME.BIN
# To include an extra file in the output folders and archives, use the -E switch:
#   EXPORT -E README.TXT MYGAME.BIN