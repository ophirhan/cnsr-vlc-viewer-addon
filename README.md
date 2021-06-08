# CNSR-vlc-viewer-addon

**An add-on for VLC media player.**

# Description

VLC plugin for real-time media censorship according to user personal settings,
using [CNSR file format](https://github.com/ophirhan/cnsr-file-format-specification).

This plugin censors categories like nudity, verbal abuse, violence and alchohol and drug consumption.

supports Windows, Linux and Mac OS.
_____________________________________________________________________________________________________

# Getting started

1) download the these files: cnsr_ext.lua, cnsr_intf.lua. 
2) "cnsr_ext.lua" > Copy the VLC Extension Lua script file into \lua\extensions\ folder;
3) "cnsr_intf.lua" > Copy the VLC Interface Lua script file into \lua\intf\ folder;
4) Start the Extension in VLC menu "View > cnsr" on Windows/Linux or "Vlc > Extensions > cnsr" on Mac and configure the cnsr categories to your liking.

**INSTALLATION directory (\lua):**
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua
* Windows (current user): %APPDATA%\VLC\lua
* Linux (all users): /usr/lib/vlc/lua
* Linux (current user): ~/.local/share/vlc/lua
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua
Create directory if it does not exist!
