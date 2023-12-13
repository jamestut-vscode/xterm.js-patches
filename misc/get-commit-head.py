#!/usr/bin/env python3

import argparse
import urllib.request
import urllib.error
import sys
import json

def printerr(*args, **kwargs):
   kwargs['file'] = sys.stderr
   print(*args, **kwargs)

if __name__ == "__main__":
   URL = "https://registry.npmjs.org/@xterm/xterm"

   ap = argparse.ArgumentParser(description="This script queries NPM's registry "
      "to look up the commit hash associated with a given version string.")
   ap.add_argument("version", help="Version string to look for the commit hash for.")
   args = ap.parse_args()

   print("Downloading NPM registry for xterm.js ...")
   try:
      req = urllib.request.urlopen(URL)
      d = req.read()
   except urllib.error.URLError as ex:
      printerr(f"Error retreiving registry info: {str(ex)}")
      sys.exit(1)

   d = json.loads(d)
   d = d.get("versions", {}).get(args.version)
   if not d:
      printerr(f"Specified version '{args.version}' is not found.")
      sys.exit(1)

   git_head = d.get("gitHead")
   if not git_head:
      printerr(f"The version '{args.version}' was found, but cannot find the Git head.")
      sys.exit(1)

   print(git_head)
