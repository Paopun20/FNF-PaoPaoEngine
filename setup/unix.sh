#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
if ! command -v haxe >/dev/null 2>&1; then
  echo "oh, Haxe not found."

  if command -v open >/dev/null 2>&1; then
    open https://haxe.org/download
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open https://haxe.org/download
  else
    echo "Go to https://haxe.org/download"
    read -p "Press [Enter] key to continue..."
  fi
  exit 1
fi

sh < ./setup/commands.txt