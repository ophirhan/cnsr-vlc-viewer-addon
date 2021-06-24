#!/bin/bash
declare -a MODULES=("extensions/cnsr_ext.lua" "intf/cnsr_intf.lua" "modules/cnsr_memory.lua")
cd ..
CURRENT_DIR=$(pwd)

for module in "${MODULES[@]}"; do
  sudo rm -rf "/Applications/VLC.app/Contents/MacOS/share/lua/$module"
  sudo ln -s "$CURRENT_DIR/$module" "/Applications/VLC.app/Contents/MacOS/share/lua/$module"
  echo linked "/Applications/VLC.app/Contents/MacOS/share/lua/$module" to "/Applications/VLC.app/Contents/MacOS/share/lua/$module"
done

exit 10