#!/usr/bin/env zsh

# This script clones the upstream xterm.js and applies our patches

set -e

cd ${0:a:h}

# clone xterm.js if not exist
if ! [ -d xterm.js ]
then
    echo "xterm.js repository does not exist. cloning ..."
    git clone https://github.com/xtermjs/xterm.js.git xterm.js
fi

cd xterm.js
echo "Fetching repository ..."
git fetch

echo "Checking repository for existing patches ..."
if ! [[ -z "$(git branch --list patched)" ]]
then
    echo "Deleting existing patched folder ..."
    git checkout master
    git branch -D patched
fi

cd ..
echo "Applying patches ..."
spm/spm.py patches xterm.js

echo "Done! The custom xterm.js is ready to be built!"
