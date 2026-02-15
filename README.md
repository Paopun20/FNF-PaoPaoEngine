# Friday Night Funkin' - PaoPao Engine

> [!WARNING]
> This engine is still in heavy development, so some features may not work as expected like [Python](https://github.com/Paopun20/Hython) with some [limitations](http://github.com/Paopun20/Hython?tab=readme-ov-file#limitations).

## Features/Changes

- Python [**Beta**] - Introduction of Python as a mod scripting language
  > interpreted language that offers greater readability and ease of learning compared to Lua. It also provides enhanced power, flexibility, and it lightweight too.\
  > Work in progress, because some Python feature contracts are yet to be completed.\
  > For assistance, please submit a pull request [here](https://github.com/Paopun20/Hython).\
  > Note: this Hython is a Python interpreter written entirely in **Haxe** and you can use it for your own projects too, it is also open source.
- Hscript (Improved and QOL with own fork)
  > Optimize.
  > Cache AST.
  > Can use without `game.`
  > Use Own's Codename's HScript fork library.
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
- Organize files and folders for improved readability and maintenance. Ensure compatibility with older layouts when importing to new systems (mostly mods, import backend, or import Discord; others may not be compatible).
- Optimize Engine performance and memory usage without breaking everything/mods.
- New Free-play UI (WIP)
- New Loading Screen UI (WIP)
- All states/substates is editable (ex: scripts/stages/[state name].hx, scripts/substates/[state name].hx)
- Improve modding experience and compatibility.

> (I haven't finished writing the README yet.)
