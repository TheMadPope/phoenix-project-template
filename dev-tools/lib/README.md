# dev-tools / lib

### What type of files should be kept in this directory?

This directory should contain only this readme, and shared-functions.sh.
It's entirely possible that, in the future, you might want to put another shared library file here, but most likely you should put your shared functions in... the shared-functions library.

### How do I invoke / load / source the shared-functions library? Like so:
```
#### LOAD SHARED FUNCTIONS LIBRARY #################################################################
# Make sure that the shared-functions.sh script exists.
# Start from the current directory
current_dir=$(realpath .)

# Look for the "dev-tools" directory by traversing up the directory structure
while [[ "$current_dir" != "/" ]]; do
  if [[ -d "$current_dir/dev-tools" ]]; then
    root_dir="$current_dir/dev-tools"
    break
  fi
  current_dir=$(dirname "$current_dir")
done

# Check if the "dev-tools" directory was found
if [[ -z "$root_dir" ]]; then
  echo "FATAL ERROR: `tput sgr0``tput setaf 1`Could not find the dev-tools directory."
  exit 1
fi

# Now you can use "$root_dir" as the root directory
lib_path="$root_dir/lib/shared-functions.sh"
if [[ ! -r "$lib_path" ]]; then
  echo "FATAL ERROR: `tput sgr0``tput setaf 1`Could not load $lib_path. File not found."
  exit 1
fi

# Load the shared-functions.sh library.  This action will also cause the
# config variables from dev-tools/lib/local-config.sh to be loaded.
source "$lib_path"
```
