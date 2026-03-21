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

haxelib install openfl 9.5.1
haxelib install flixel 6.1.2
haxelib install flixel-addons 4.0.1
haxelib install flixel-tools 1.5.1
haxelib install flixel-waveform
haxelib install tjson 1.4.0
haxelib install hxvlc 2.2.5
haxelib install hxcpp 4.3.2
haxelib install tink_core 2.1.1
haxelib install moonchart 0.5.1
haxelib install sl-windows-api 1.2.0
haxelib install random 1.4.1
haxelib install lime 8.3.1
haxelib install android6permissions
haxelib git hython https://github.com/Paopun20/hython.git dev
haxelib git compiletime https://github.com/Paopun20/compiletime.git
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc.git
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 0188d47c982913eb10fad7bd75f062ddfc680f4b
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio 57f5d47f2533fd0c3dcd025a86cb86c0dfa0b6d2
haxelib git hscript-improved https://github.com/Paopun20/PPE-hscript-improved codename-dev
haxelib git hxhardware https://github.com/Vortex2Oblivion/hxhardware.git
