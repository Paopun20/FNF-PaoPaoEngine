if ([string]::IsNullOrEmpty((Get-Command haxe -ea 0))) {
    [void][System.Console]::WriteLine("oh, Haxe not found.")
    [system.Diagnostics.Process]::Start("cmd","/c start https://haxe.org/download/")
    [void][System.Console]::WriteLine("Press Enter to continue...")
    [void][System.Console]::ReadLine()
    [System.Environment]::Exit(1)
}

if ([string]::IsNullOrEmpty((Get-Command haxe -ea 0)))
{
    [void][System.Console]::WriteLine("oh, Haxe not found.")
    [system.Diagnostics.Process]::Start("cmd","/c start https://haxe.org/download/")
    [void][System.Console]::WriteLine("Press Enter to continue...")
    [void][System.Console]::ReadLine()
    [System.Environment]::Exit(1)
}

# execute commands from data
haxelib install openfl 9.5.1
haxelib install flixel 6.1.2
haxelib install flixel-addons 4.0.1
haxelib install flixel-tools 1.5.1
haxelib install flixel-waveform
haxelib install tjson 1.4.0
haxelib install hxcpp 4.3.2
haxelib install tink_core 2.1.1
haxelib install moonchart 0.5.1
haxelib install random 1.4.1 
haxelib install lime 8.3.1
haxelib install thx.semver 0.2.2
haxelib install sl-windows-api
haxelib git hxvlc https://github.com/CodenameCrew/cne-hxvlc.git
haxelib git hython https://github.com/Paopun20/hython.git legacy
haxelib git compiletime https://github.com/Paopun20/compiletime.git
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc.git
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate.git 0188d47c982913eb10fad7bd75f062ddfc680f4b
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis.git 22b1ce089dd924f15cdc4632397ef3504d464e90
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio.git 57f5d47f2533fd0c3dcd025a86cb86c0dfa0b6d2
haxelib git hscript-improved https://github.com/CodenameCrew/hscript-improved.git codename-dev
haxelib git hxhardware https://github.com/Vortex2Oblivion/hxhardware.git
haxelib git lscript https://github.com/SrtHero278/lscript.git
haxelib git lemonui https://github.com/NebulaStellaNova/LemonUI.git

haxelib install hxWindowColorMode 0.2.1
