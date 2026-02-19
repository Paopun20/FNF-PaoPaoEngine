if ([string]::IsNullOrEmpty((Get-Command haxe -ea 0))) {
    [void][System.Console]::WriteLine("oh, Haxe not found.")
    [system.Diagnostics.Process]::Start("cmd","/c start https://haxe.org/download/")
    [void][System.Console]::WriteLine("Press Enter to continue...")
    [void][System.Console]::ReadLine()
    [System.Environment]::Exit(1)
}

Invoke-Expression $([System.IO.File]::ReadAllText("setup/commands.txt"))

# for windows only
haxelib install hxWindowColorMode 0.2.1if ([string]::IsNullOrEmpty((Get-Command haxe -ea 0)))
{
    [void][System.Console]::WriteLine("oh, Haxe not found.")
    [system.Diagnostics.Process]::Start("cmd","/c start https://haxe.org/download/")
    [void][System.Console]::WriteLine("Press Enter to continue...")
    [void][System.Console]::ReadLine()
    [System.Environment]::Exit(1)
}

# execute commands from data
haxelib install lime 8.3.0
haxelib install openfl 9.5.0
haxelib install flixel 5.9.0
haxelib install flixel-addons 3.3.0
haxelib install flixel-tools 1.5.1
haxelib install tjson 1.4.0
haxelib install hxvlc 2.2.5
haxelib install hxcpp 4.3.2
haxelib install tink_core 2.1.1
haxelib git hython https://github.com/Paopun20/hython.git
haxelib git compiletime https://github.com/Paopun20/compiletime.git
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc.git
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 0188d47c982913eb10fad7bd75f062ddfc680f4b
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90
haxelib git grig.audio https://github.com/FunkinCrew/grig.audio 57f5d47f2533fd0c3dcd025a86cb86c0dfa0b6d2
haxelib git hscript-improved https://github.com/Paopun20/PPE-hscript-improved codename-dev

# for windows only
Write-Host "Installing hxWindowColorMode 0.2.1"
$output = haxelib install hxWindowColorMode 0.2.1 -y 2>&1

if ($LASTEXITCODE -ne 0)
{
    Write-Error "Failed to install hxWindowColorMode"
    Write-Error $output
    [System.Environment]::Exit(1)
}

Write-Host $output
Write-Host "Setup completed successfully!"
