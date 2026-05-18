# MonOS Design Info

Please note that this OS/Monitoring System was built for a specific purpose.
The OS won't cover as much edge cases/functionality as more general-purpose OSes (i.e. OpenOS, Plan9k and MineOS) would.

## TL:DR

The OS, until now, is built to load once, run always.
That's it.

## How it loads

The OS first loads in libraries (hard-coded)
Then it loads in modules. The functions directly register to the `main` global variable
Finally, the kernel (which is `main.lua`, btw) loads in and the main loop is executed

## How it runs

The modules, which are stored in the `main` global variable, are executed in alphabetical order.
All functions of the os (with the sole exception of flushing events) are ran through it.
Due to inexperience, all calls/function runs are **UNSAFE** and can crash the system.

## What the OS can't do

1. Use mutiple filesytems
2. Use any other filesystems (other than its own, of course)
3. Render graphics (or even text, for that matter)
