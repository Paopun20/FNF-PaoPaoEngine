$mods = "E:\FNF-PaoPaoEngine\export\debug\windows\bin\mods"
$example = "E:\FNF-PaoPaoEngine\example_mods"

New-Item -ItemType Junction -Path $mods -Target $example

Write-Host "Done!"