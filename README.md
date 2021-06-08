# CNSR-vlc-viewer-addon

**An add-on for VLC media player.**

# Description

VLC plugin for real-time media censorship according to user personal settings,
using [CNSR file format](https://github.com/ophirhan/cnsr-file-format-specification).

This plugin censors categories like nudity, verbal abuse, violence and alchohol and drug consumption.
_____________________________________________________________________________________________________

# Getting started

first, download these files 
"cnsr_ext.lua" > Put this VLC Extension Lua script file in \lua\extensions\ folder
"cnsr_intf.lua" > Put the VLC Interface Lua script file in \lua\intf\ folder
Simple instructions:
1) "cnsr_ext.lua" > Copy the VLC Extension Lua script file into \lua\extensions\ folder;
2) "cnsr_intf.lua" > Copy the VLC Interface Lua script file into \lua\intf\ folder;
3) Start the Extension in VLC menu "View > Time v3.x (intf)" on Windows/Linux or "Vlc > Extensions > Time v3.x (intf)" on Mac and configure the Time interface to your liking.
Alternative activation of the Interface script:
* The Interface script can be activated from the CLI (batch script or desktop shortcut icon):
vlc.exe --extraintf=luaintf --lua-intf=cnsr_intf
* VLC preferences for automatic activation of the Interface script:
Tools > Preferences > Show settings=All > Interface >
> Main interfaces: Extra interface modules [luaintf]
> Main interfaces > Lua: Lua interface [cnsr_intf]
INSTALLATION directory (\lua\extensions\):
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\VLC\lua\extensions\
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/extensions/
Create directory if it does not exist!
