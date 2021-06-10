# CNSR-vlc-viewer-addon

**An add-on for VLC media player.**

# Description

VLC plugin for real-time media censorship according to user personal settings,
using [CNSR file format](https://github.com/ophirhan/cnsr-file-format-specification).

This plugin censors categories like nudity, verbal abuse, violence and alchohol and drug consumption.

supports Windows, Linux and Mac OS.
_____________________________________________________________________________________________________

# Getting started

1. if you don't have VLC in your computer, install from [VLC](https://www.videolan.org/)
2. download these files: [cnsr_ext.lua](https://github.com/ophirhan/cnsr-vlc-viewer-addon/blob/main/extensions/cnsr_ext.lua), [cnsr_intf.lua](https://github.com/ophirhan/cnsr-vlc-viewer-addon/blob/main/intf/cnsr_intf.lua).
3. access lua folder using these paths:

Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua

Windows (current user): %APPDATA%\VLC\lua

Linux (all users): /usr/lib/vlc/lua

Linux (current user): ~/.local/share/vlc/lua

Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua

Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua Create directory if it does not exist!

(create the directory if it does not exist!)

3. move "cnsr_ext.lua" file into \lua\extensions\ folder.
4. move "cnsr_intf.lua" file into \lua\intf\ folder.
5. Start the Extension in VLC menu "View > cnsr" on Windows/Linux or "Vlc > Extensions > cnsr" on Mac and configure the cnsr categories to your liking.

# For developers

1) change the lua folder's name to "luab".

2) clone the repository a new folder named "lua"

3) copy the contents of "luab" to "lua"

4) delete "luab" folder

and thats it! you are ready to start
