# FNF - PaoPao Engine (PaoPao's Psych Engine fork)

Crossover between **Codename Engine**, **FNF V-Slice**, and **Psych Engine**

## Features

- Python [Buggy] - Introduction of Python as a mod scripting language
  > Python is a high-level, interpreted language that offers greater readability and ease of learning compared to Lua. It also provides enhanced power and flexibility.\
  Why is it a work in progress? Because some Python feature contracts are yet to be completed.\
  For assistance, please submit a pull request [here](https://github.com/Paopun20/Hython).
  >> Note: this Hython is a Python interpreter written entirely in **Haxe**.
- Fixed Loading Screen race condition and made it thread-safe
  > A race condition occurs when two or more threads access a shared resource simultaneously, leading to unpredictable behavior, data corruption, or a stuck loading screen.
  >> More details? [here](https://www.youtube.com/watch?v=bhpzTWtee2A)
- 3D support [Buggy^2, HScript Only]
  > Note: bug at enter the song for the second time (or restart song) or has 2 models at the same time for some reason, can make the game crash if mods use 3D models. (I got headache, I try everything, it's not working)
- Open mod folder by clicking the "Open Mod Folder" button in the mod menu.
- Format all files to make them more readable and easier to understand
- Fixed Psych Engine Bugs
- Updated dependencies to the most compatible versions
- Removed obsolete features from the Psych Engine, such as the Easter Egg.

> (I haven't finished writing the README yet.)
