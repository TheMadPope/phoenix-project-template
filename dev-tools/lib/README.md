# dev-tools / lib

### What type of files should be kept in this directory?

This directory should contain only this readme, and shared-functions.sh.
It's entirely possible that, in the future, you might want to put another shared library file here, but most likely you should put your shared functions in... the shared-functions library.
How do I invoke / load / source the shared-functions library? Like so:
```
#### LOAD SHARED FUNCTIONS LIBRARY #################################################################
if [ ! -r `dirname $0`/lib/shared-functions.sh ]; then
  echo "\nFATAL ERROR: `tput sgr0``tput setaf 1`Could not load dev-tools/lib/shared-functions.sh.  File not found.\n"
  exit 1
fi
source `dirname $0`/lib/shared-functions.sh
```
