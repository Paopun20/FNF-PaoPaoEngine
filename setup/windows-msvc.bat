@echo off
color 0a

set "TMPDIR=%TEMP%"
set "VS_EXE=%TMPDIR%\vs_Community.exe"

echo Installing Microsoft Visual Studio Community (Dependency)
echo Downloading to %TMPDIR%

curl -L -# -o "%VS_EXE%" ^
https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe

start /wait "" "%VS_EXE%" ^
--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
--add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
--includeRecommended ^
--quiet --wait --norestart

del "%VS_EXE%"
echo Finished.
pause
