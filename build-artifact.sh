#!/usr/bin/env zsh

# This script generates xtermjs.tar.gz, ready for deployment (e.g. used in packages.json
# of other projects). The 'build-repo.sh' must be run first.

set -e

FINALNAME=xtermjs.tar.gz

mkdir -p out
cd xterm.js
yarn
yarn package
npm pack --pack-destination ../out
cd ../out
mv *.tgz $FINALNAME
mv $FINALNAME ../
