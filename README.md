# FNF - PaoPao Engine (PaoPao's Psych Engine fork)

<!--Crossover between **Codename Engine**, **FNF V-Slice**, and **Psych Engine**-->

> [!WARNING]
> This engine is still in heavy development, so some features may not work as expected like [Python](https://github.com/Paopun20/Hython) with some [limitations](http://github.com/Paopun20/Hython?tab=readme-ov-file#limitations).

## Features/Changes

- Python [Beta] - Introduction of Python as a mod scripting language
  > Python is a high-level, interpreted language that offers greater readability and ease of learning compared to Lua. It also provides enhanced power, flexibility, and it lightweight too.\
  > btw, You can all lua functions and haxe functions too. (has some rename lua to python in func name, ex: makeLuaSprite to makePythonSprite in python only)\
  > Work in progress, OK? Because some Python feature contracts are yet to be completed.\
  > For assistance, please submit a pull request [here](https://github.com/Paopun20/Hython).\
  > Note: this Hython is a Python interpreter written entirely in **Haxe** and you can use it for your own projects too, it is also open source.
- Hscript (Improved and QOL with own fork)
  > Optimize.
  > Cache AST.
  > Use Codename's HScript fork library.
- Ndll Support (HScript/Python only)
  > It codename feature.
  >
  > > IDK, what to say.
- Fixed Loading Screen race condition and made it thread-safe
  > A race condition occurs when two or more threads access a shared resource simultaneously, leading to unpredictable behavior, data corruption, or a stuck loading screen.
  > > More details? [here](https://www.youtube.com/watch?v=bhpzTWtee2A)
- Open mod folder by clicking the "Open Mod Folder" button in the mod menu.
- Format all files to make them more readable and easier to understand
- Fixed Psych Engine Bugs
- Updated dependencies to the most compatible versions
- Removed obsolete features from the Psych Engine, such as the Easter Egg.
- Organize files and folders for improved readability and maintenance. Ensure compatibility with older layouts when importing to new systems (mostly mods, import backend, or import Discord; others may not be compatible).
- Optimize Engine performance and memory usage.
- Improve modding experience and compatibility.

> (I haven't finished writing the README yet.)
