#!/bin/sh

while getopts mv ARGS
    do
        case $ARGS in
            m) git config --global --replace-all core.editor "mate -w" ;;
            g) git config --global --replace-all core.editor "gvim -f" ;;
            v) git config --global --replace-all core.editor "vim"     ;;
        esac
    done

echo Verifying editor change
git config --list | grep -q core.editor
if [ $? -ne 0 ] ; then
    echo "Failed to commit editor change!"
    exit 1
fi

