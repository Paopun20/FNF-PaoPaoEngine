if ([string]::IsNullOrEmpty((Get-Command haxe -ea 0))) {
    [void][System.Console]::WriteLine("oh, Haxe not found.")
    [system.Diagnostics.Process]::Start("cmd","/c start https://haxe.org/download/")
    [void][System.Console]::WriteLine("Press Enter to continue...")
    [void][System.Console]::ReadLine()
    [System.Environment]::Exit(1)
}

# execute commands from data
foreach ($line in [System.IO.File]::ReadAllText("setup/commands.txt").Split("`n")) {
    sh -c "haxelib --quiet $line -y"
}

# for windows only
haxelib install --quiet hxWindowColorMode 0.2.1 -y