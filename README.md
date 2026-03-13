# Friday Night Funkin' - PaoPao Engine

> [!WARNING]
This engine is currently under heavy development, so some features may not function as expected, such as [Python](https://github.com/Paopun20/Hython), which has certain [limitations](http://github.com/Paopun20/Hython?tab=readme-ov-file#limitations).

PaoPoa Engine is a cross-platform [Friday Night Funkin'](https://github.com/FunkinCrew/Funkin) Engine aimed at freedom of modding without source code, optimization, and lightweight, cross-platform.

## Features/Changes from the frok until 0.1.0 initial releases (maybe)

- Python [**Beta**] - Introduction of Python as a mod scripting language
  > interpreted language that offers greater readability and ease of learning compared to Lua. It also provides enhanced power, flexibility, and it lightweight too.\
  > Work in progress, because some Python feature contracts are yet to be completed.\
  > For assistance, please submit a pull request [here](https://github.com/Paopun20/Hython).\
  > Note: this Hython is a Python interpreter written entirely in **Haxe** and you can use it for your own projects too, it is also open source.
- Hscript (Improved and QOL)
  > Can use without `game.`
  > Use Own's Codename's HScript fork library, only add QOL.
- Optimize by Cache AST (HScript/Python only)
  > Cache AST (Abstract Syntax Tree)
  > Reuse Cache AST
- Ndll Support (HScript/Python only)
  > It codename feature.
- Fixed Psych Engine Bugs (some critical)
   - Loading Screen (Critical): Fix Race Condition
    > A race condition occurs when two or more threads access a shared resource simultaneously, leading to unpredictable behavior, data corruption, or a stuck loading screen.
    > More details? [here](https://www.youtube.com/watch?v=bhpzTWtee2A)
- Open mod folder by clicking the "Open Mod Folder" button in the mod menu.
- Format all files to make them more readable and easier to understand
- Fixed Psych Engine Bugs
- Updated dependencies to the most compatible versions
- Removed obsolete features from the Psych Engine, such as the Easter Egg.
- Organize files and folders to improve readability and maintenance. Ensure compatibility with older layouts when importing to new systems, as others may not be compatible; all are indexed by StructureCompatibility.hx.
- Optimize Engine performance and memory usage without breaking everything/mods.
- New Free-play UI (WIP)
- Improved Loading Screen (WIP)
- All states/substates is editable (ex: scripts/stages/[state name].hx, scripts/substates/[state name].hx)
- Improve modding experience and compatibility.
- New event:
  - Offset Timer (useful for fake end)
  > Adjust the time **displayed in the PlayState Time UI only**, without affecting `Conductor.songPosition`.

## Origin

PaoPao Engine was fork based on [**Psych Engine 1.0.4**](https://github.com/ShadowMario/FNF-PsychEngine)

> (I haven't finished writing the README yet.)
