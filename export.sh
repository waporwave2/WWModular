#!/usr/bin/env bash
set -e


function bye {
    MSG=${1-"Goodbye"}
    echo "$MSG"
    exit 1
}
function yes_or_no {
    while true; do
        read -rp "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
        esac
    done
}
function pico8_export() {
    P8FILE=${1?"need file"}
    EXPORT_ARGS=${2?"need export command"}

    TEMPFILE=$(mktemp)

    pico8 "$P8FILE" -export "$EXPORT_ARGS" | tee "$TEMPFILE"

    # ! = invert, so grep match => failure exit code
    ! grep -q -F -e'fail' -e'not' -e'limit' -e'future version' -e'too many' -e'#include' "$TEMPFILE"
}

echo 'exporting web...'
./shrink.sh \
    --const web_version true \
    wwmodular.p8 wwmodular-web.p8.png || bye 'shrinko8 error'
pico8_export wwmodular-web.p8.png "-f wwmodular.html" || bye "error exporting html"
sed -r \
  -e 's/background-color:#222/background-color:#1d2b53/' \
  -i wwmodular_html/index.html
rm wwmodular-web.p8.png

echo 'exporting png...'
./shrink.sh \
    --const web_version false \
    wwmodular.p8 wwmodular.p8.png || bye 'shrinko8 error'

echo 'exporting binaries...'
pico8_export wwmodular.p8.png "-i 36 -s 2 -c 16 -f wwmodular.bin"
# https://www.lexaloffle.com/dl/docs/pico-8_manual.html#Binary_Applications_
#   -I N     Icon index N
#   -S N     Size NxN sprites. N=3 would be produce a 24x24 icon.
#   -C N     Treat colour N as transparent. N=16 for no transparency.
#   -E path  Include an extra file in the output folders and archives

echo 'adding docs...'
for ZIP in $(ls wwmodular.bin/*.zip); do
    ark --add-to "$ZIP" \
      "examples/" \
      "samples/" \
      "WWM DOCUMENTATION.txt" \
    > /dev/null \
    && echo "  added docs to $ZIP"
done
