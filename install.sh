#!/usr/bin/env bash

set -e

if [ "$UID" = "0" ]; then
    echo 'This should not be run as root'
    exit 101
fi

NAME=highlight-focus\@pimsnel.com

function pack-extension {
  echo "Packing extension..."
  compile-preferences
  gnome-extensions pack src \
    --force \
    --extra-source="../LICENSE" \
    --extra-source="../CHANGELOG.md" \
    --extra-source="ui.js" \
    --extra-source="style.js"
}

function compile-preferences {
    if [ -d src/schemas ]; then
        echo 'Compiling preferences...'
        glib-compile-schemas --targetdir=src/schemas src/schemas
    else
        echo 'No preferences to compile... Skipping'
    fi
}

function make-local-install {
    DEST=~/.local/share/gnome-shell/extensions/$NAME

    compile-preferences

    echo 'Installing...'
    if [ ! -d $DEST ]; then
        mkdir $DEST
    fi
    cp -rv src/* locale $DEST/

}

function restart-shell {
    busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting…")'
    echo 'Done'
}

function make-zip {
    if [ -d build ]; then
        rm -r build
    fi

    rm -fv "$NAME".zip
    mkdir build
    compile-preferences
    echo 'Coping files...'
    cp -r LICENSE README.md src/* locale build/
    find build -name "*.po*" -delete
    find build -name "LINGUAS" -delete
    echo 'Creating archive..'
    cd build
    zip -r ../"$NAME".zip ./*
    cd ..
    rm -r build
    echo 'Done'
}

function usage() {
    echo 'Usage: ./install.sh COMMAND'
    echo 'COMMAND:'
    echo "  local-install  install the extension in the user's home directory"
    echo '                 under ~/.local'
    echo '  zip            Creates a zip file of the extension'
}

case "$1" in
    "local-install" )
        pack-extension
        gnome-extensions install --force $NAME.shell-extension.zip && restart-shell
        ;;

    "zip" )
        pack-extension
        ;;

    * )
        usage
        ;;
esac
exit
