#!/usr/bin/env sh
set -e

echo 'did you run export.sh?'
echo 'did you change the html export background color? ("#222" -> "#1d2b53")'
read -r -p "continue? [y/n] " response
case "$response" in
    [yY][eE][sS]|[yY])
        # pass
        ;;
    *)
        exit 1
        ;;
esac

butler push wwmodular_html waporwave/wwmodular:html
butler push wwmodular.bin/wwmodular_windows.zip waporwave/wwmodular:windows
butler push wwmodular.bin/wwmodular_linux.zip waporwave/wwmodular:linux
butler push wwmodular.bin/wwmodular_osx.zip waporwave/wwmodular:osx
butler push wwmodular.bin/wwmodular_raspi.zip waporwave/wwmodular:raspi
# butler push wwmodular.p8.png waporwave/wwmodular:png
