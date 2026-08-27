# Concept: Lazy Require

Unlike normal `require()` which loads the library once and keeps it in memory forever (until reboot/poweroff), lazy `require()` takes into account *amount of calls* to the function table **PER** kernel heartbeat.  
By keeping count of `__index()`s to the function table/library per kernel heartbeat, we can determine what libraries to unload, *if needed*.  
This is similar to the `event` subsystem, and reduces memory **DRASTICALLY** if utilized properly (i.e. The `hrf3-net` response functions, or pieces of code you don't want to use)

## Expanded Concept

There are **3** Tiers of packages: `preload`, `core` and `normal`

`preload` is the equivalent of packages/libraries stored in OpenOS' `/lib/core/` directory, and is used by the boot script to initialize and load both `core` and `normal` packages. Once the *kernel* successfully starts, `preload` is automatically `nil`'d.  

`core` packages are packages that are too useful to be unloaded. Mostly used by libraries that are either certainly used by the kernel or by all the modules.  

`normal` packages are packages that are loaded and accessed through the `require()` function. When a `normal` package is not been used for many kernel heartbeats, it will be automatically unloaded.

### requiring a normal package

When a `normal` package is `require()`'d, it will perform the nessecary return table stuff, but instead of returing the package, we return the *proxy* of the package.

When a function or constant is accessed, the *proxy* will call the `__index()` metafunction (since the *proxy* is an empty table) and a counter will be incremented before returning the function (or `nil` if not valid).

### unloading a normal package

If a `normal` package is not accessed for a *certain number of kernel heartbeats*, the table containing all the function data will be `nil`'d. The *proxy* will remain though, and is used to **reload** the unloaded package if a module gets data or executes a function.

### package persistence

If a module decides to *write* to the package (for whatever reason), the `__newindex()` metafunction in the *proxy* table will be called. This will store the new value into a special *peristence table*.  

If a module decides to get something from the package (loaded or unloaded), the `__index()` function **should check** if said something is available in the *persistence table* before accessing (and/or loading) the main table containing the package data.  

The *persistence table* will stay loaded into memory and **will not be unloaded.**

**NOTE**: Depending on the programmer, they may or may not decide to count the *persistence table* as a use.

## Reference(s)

Also see: https://www.lua.org/pil/13.4.4.html
