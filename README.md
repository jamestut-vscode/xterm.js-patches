# James' xterm.js

This fork contains my personal modifications to xterm.js that are not approved by upstream maintainers.

## Changes Made

- **Added an option to disable mouse reporting.**
  If this option is enabled, this will allow scrollback and selection on terminal apps, even those that requires mouse reporting (e.g. `tmux` and `vim`).
- **Fixed link activation behaviour.**
  Link is no longer opened when selecting the a text within a link.

## Build Instructions

- Run `build-repo.sh`. Running this script will perform these steps:
  - Download the latest version of my [Simple Patch Manager](https://github.com/jamestut/spm) script.
  - Clone the original [xterm.js repo](https://github.com/xtermjs/xterm.js) if it does not exists yet.
    - Fetch the repo otherwise if it already exists.
  - Applies the patches on top of the cloned repo using the Simple Patch Manager.
- Proceed with the usual xterm.js' build instructions.

### Build Prerequisite

In addition to xterm.js' build requirements, this repo also requires:

- Python 3.8 or newer is required for running the [Simple Patch Manager](https://github.com/jamestut/spm).
- The [zsh shell](https://www.zsh.org) and [curl](https://curl.se) is required for running `build-repo.sh`.
