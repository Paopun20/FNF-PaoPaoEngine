if ([string]::IsNullOrEmpty((Get-Command haxe -ea 0))) {
    [void][System.Console]::WriteLine("oh, Haxe not found.")
    [system.Diagnostics.Process]::Start("cmd","/c start https://debug.to")
    [void][System.Console]::WriteLine("Press Enter to continue...")
    [void][System.Console]::ReadLine()
    [System.Environment]::Exit(1)
}

Invoke-Expression $([System.IO.File]::ReadAllText("setup/commands.txt"))