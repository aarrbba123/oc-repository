# MonOS v2 Concept

Because v1 is currently a messy mess™, this is the second version.

## Boot Process

### init.lua

The first file used to boot from BIOS. Not much to say.
Unlike v1, which has `init.lua` and `boot.lua`.
Both are merged.

1. Load package (`/lib/core/package.lua`) module.
2. Load core (`/lib/core/*`) modules, using the package module.
3. Load superloop/kernel @ (`/sys/main.lua`).

### main.lua

The main loop for the OS.
Instead of just loading ALL of the files in `/sys/modules/*`, we use a `.toml` file
More specifically, the (`/sys/kmod.toml`) file.
