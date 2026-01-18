# FNF - PaoPao Engine (PaoPao's Psych Engine fork)

Crossover between **Codename Engine**, **FNF V-Slice**, and **Psych Engine**

This engine, I focus at 4th wall breaking features and some cool stuff.

> [!WARNING]
> This engine is still in heavy development, so some features may not work as expected like Python.

## Features/Changes

- Python [Beta] - Introduction of Python as a mod scripting language
  > Python is a high-level, interpreted language that offers greater readability and ease of learning compared to Lua. It also provides enhanced power, flexibility, and it lightweight too.\
  > btw, You can all lua functions and haxe functions too. (has some rename lua to python in func name, ex: makeLuaSprite to makePythonSprite in python only)\
  > Work in progress, OK? Because some Python feature contracts are yet to be completed.\
  > For assistance, please submit a pull request [here](https://github.com/Paopun20/Hython).\
  > Note: this Hython is a Python interpreter written entirely in **Haxe** and you can use it for your own projects too, it is also open source.
- Hscript (Improved)
  > It took forever to rewrite this.
- Ndll Support (HScript/Python only)
  > It codename feature.
  > > IDK, what i say.
- Fixed Loading Screen race condition and made it thread-safe
  > A race condition occurs when two or more threads access a shared resource simultaneously, leading to unpredictable behavior, data corruption, or a stuck loading screen.
  > > More details? [here](https://www.youtube.com/watch?v=bhpzTWtee2A)
- Open mod folder by clicking the "Open Mod Folder" button in the mod menu.
- Format all files to make them more readable and easier to understand
- Fixed Psych Engine Bugs
- Updated dependencies to the most compatible versions
- Removed obsolete features from the Psych Engine, such as the Easter Egg.
- Organize files and folders for better readability and maintainability

> [!NOTE]
> It's broken some psych mods, wait I add backwards compatibility any time soon

> (I haven't finished writing the README yet.)
