# IMPORTANT

Before making ANY code changes, AI agents MUST read:

```txt
Project.xml
```

This file contains:

- build targets
- dependencies
- asset paths
- compiler flags
- platform settings
- haxelib configuration

Do NOT assume project configuration without checking `Project.xml` first.

If build behavior seems unusual, verify:

- `<define />`
- `<source />`
- `<assets />`
- `<haxelib />`
- target-specific sections

first.

---

## Project Overview

This project is a game built using:

- Haxe
- Lime
- OpenFL

Primary goals:

- Performance
- Clean architecture
- Cross-platform support
- Maintainable code

---

## Project Structure

```txt
/project-root
├── Assets/
├── Source/
├── Project.xml
└── (etc.)
```

---

## Coding Rules

- Use explicit typing when possible
- Avoid unnecessary allocations in update loops
- Prefer composition over inheritance
- Keep systems modular
- Avoid giant monolithic classes

---

## Haxe Rules

### Imports

Prefer:

```haxe
import lime.app.Application;
```

Avoid:

```haxe
import lime.app.*;
```

---

## Null Safety

Always check nullable values explicitly.

---

## Performance Rules

Avoid:

- Reflection-heavy code
- Per-frame allocations
- Large temporary arrays

Prefer:

- Object pooling
- Reused structures
- Inline functions for hot paths

---

## Scene Rules

Scenes must:

- manage their own assets
- clean up resources properly
- avoid direct dependencies on unrelated scenes

---

## AI Agent Instructions

When editing code:

1. Read `Project.xml` FIRST
2. Preserve architecture
3. Avoid unnecessary dependencies
4. Keep changes minimal and targeted
5. Explain major structural changes
6. Do not refactor unrelated systems
7. Maintain deterministic gameplay behavior

---

## Project.xml Rules

AI agents MUST NOT:

- modify build targets unnecessarily
- remove existing haxelib dependencies
- change asset paths without reason
- alter application metadata randomly

When adding dependencies:

1. verify compatibility with current Lime/OpenFL version
2. avoid duplicate libraries
3. explain why dependency is required

---

## Serialization Rules

Do NOT:

- rename serialized fields
- reorder save data structures
- change IDs used in save files

Without explicit migration handling.

---

## Conditional Compilation

Project uses extensive conditional compilation.

AI agents MUST verify:

- #if windows
- #if hl
- #if cpp
- #if html5
- #if mobile

MUST end with #end and be properly nested.

before changing platform-specific code.

---

## Modding Compatibility

Maintain backward compatibility for:

- exposed scripting APIs
- mod asset paths
- public gameplay hooks
- event names

Avoid breaking existing mods.

---

## Build Commands

### Debug

```bash
lime test windows -debug
```

### Release

```bash
lime build windows
```

### Final Release

```bash
lime build windows -final
```

---

## Final Checklist

Before finishing:

- Project compiles
- No broken imports
- No missing assets
- No new warnings
- Scene transitions still work
- Performance remains stable
