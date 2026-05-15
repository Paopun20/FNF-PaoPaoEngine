<img src="./art/icons/BaseIcon.png" width="125" height="125" align="right" />

# Friday Night Funkin' - PaoPao Engine

> [!WARNING]
> This engine is currently under heavy development, some API is not 100% same as **Psych Engine** mods, ya your cook bro

PaoPao Engine is a cross-platform [Friday Night Funkin'](https://github.com/FunkinCrew/Funkin) Engine aimed at optimization, lightweight, cross-platform.

## Features/Changes from the fork until 0.1.0 initial releases (maybe)

- Python [**Beta**] - A Simple Version of Python for mod scripting
  > Work in progress, because some Python feature contracts are yet to be completed.\
  > Want to help? Submit a pull request on the [Hython GitHub repository](https://github.com/Paopun20/Hython).
- NxScript [**Experimental**]
  > <https://github.com/Kitsumizy/NxScript/>
- Hscript (Improved)
  > Use Own's Codename's HScript library
- Optimize by Cache AST (HScript/Python only)
  > Cache AST (Abstract Syntax Tree)\
  > Reuse Cache AST
- Ndll Support (HScript/Python only)
  > It codename feature.
- Fixed Psych Engine Bugs (some critical)
  - Loading Screen (Critical): Fix Race Condition
    > A race condition occurs when two or more threads access a shared resource simultaneously, leading to unpredictable behavior, data corruption, or a stuck loading screen.\
    > More details? [YouTube video about Race Conditions](https://www.youtube.com/watch?v=bhpzTWtee2A)
- Open mod folder by clicking the "Open Mod Folder" button in the mod menu.
- Format all files to make them more readable and easier to understand
- Fixed Psych Engine Bugs
- Updated dependencies to the most compatible versions
- Removed obsolete features from the Psych Engine, such as the Easter Egg.
- Organize files and folders to improve readability and maintenance. Ensure compatibility with older layouts when importing to new systems, as others may not be compatible; all are indexed by StructureCompatibility.hx.
- Optimize Engine performance and memory usage without breaking everything/mods like script engine.
- New Free-play UI (WIP)
- Improved Loading Screen (WIP)
- All states/substates is editable (ex: scripts/stages/[state name].hx, scripts/substates/[state name].hx) [**Experimental**]
- Improve modding experience and compatibility.
- Update Lib: flixel, flixel-addons (RIP, old mods)
- GDI Effects (HScript only):
  > /J SL WINDOWS API library
- Video Cutscene Subtitles Is Support
  - Subtitles: subtitles/video/videoName.srt
  > (I facking hate it everytime it crash without error output)

- New events:
  - Offset Timer
    > Shifts the **displayed time** forward or backward in the Time UI. Supports tweening.\
    > Does not affect `Conductor.songPosition`.
  - Offset End
    > Shortens the **displayed song length** in the Time UI, making the bar fill up earlier.\
    > Useful for fake endings. Does not affect `Conductor.songPosition` or `songLength`.

## Mod Scripting You can use for now

- Lua
- Hscript
- Python
- NxScript

## About

I am a solo developer, and I am doing this for fun, so please be patient with the development process or just made pull request if you want to help, I will review it as soon as possible.

I have a discord server for anyone who wants chating or live updates or bot spam on the engine:
<https://discord.gg/XQDpcrk74Q>

## Credits

Icon made by me
> inspired by Geodify's icon, Geode background and Psych Engine's Icon

## Planing

- [mobile support](https://youtu.be/cSQTZoZPJzs)
- switch support

## Origin

PaoPao Engine was fork based on [**Psych Engine 1.0.4**](https://github.com/ShadowMario/FNF-PsychEngine)

> (I haven't finished writing the README yet)
