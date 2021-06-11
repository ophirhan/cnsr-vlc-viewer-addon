# CNSR-vlc-viewer-addon

**An add-on for VLC media player.**

# Description

VLC plugin for real-time media censorship according to user personal settings,
using [CNSR file format](https://github.com/ophirhan/cnsr-file-format-specification).

This plugin censors categories like nudity, verbal abuse, violence and alchohol and drug consumption.

supports Windows, Linux and Mac OS.
_____________________________________________________________________________________________________

# Getting started

1. If you don't have VLC in your computer, install from [VLC](https://www.videolan.org/)
2. download these files: [cnsr_ext.lua](https://github.com/ophirhan/cnsr-vlc-viewer-addon/blob/main/extensions/cnsr_ext.lua), [cnsr_intf.lua](https://github.com/ophirhan/cnsr-vlc-viewer-addon/blob/main/intf/cnsr_intf.lua).
3. Access lua folder using these paths:
- Windows
  - `%ProgramFiles%\VideoLAN\VLC\lua` (all users)
  - `%APPDATA%\VLC\lua` (current user)
- Linux
  - `/usr/lib/vlc/lua` (all users)
  - `~/.local/share/vlc/lua` (current user)

- Mac OS X
  - `/Applications/VLC.app/Contents/MacOS/share/lua` (current user)
  - `/Users/%your_name%/Library/Application Support/org.videolan.vlc/lua` (current user) 
  
  ** (create the directory if it does not exist!)

4. Move "cnsr_ext.lua" file into \lua\extensions\ folder.
5. Move "cnsr_intf.lua" file into \lua\intf\ folder.
6. Start the Extension in VLC menu "View > cnsr" on Windows/Linux or "Vlc > Extensions > cnsr" on Mac and configure the cnsr categories to your liking.

# For developers

1. Change the lua folder's name to "luab".

2. Clone the repository a new folder named "lua"

3. Copy the contents of "luab" to "lua"

4. Delete "luab" folder

and thats it! you are ready to start

How to use cnsr files:
In order to make use of cnsr file you need to create a new file with the format as shown in 'example/example_file.cnsr'.
The file name must be identical to the video name you want to play (except for the ending), and must be at the same directory as the video.

For example, if the video you want to play is:
c://User/Me/Desktop/myvid.mp4
Then the cnsr file should be:
c://User/Me/Desktop/myvid.cnsr
(currently there is an issue with directoris that have underscore or spaces, so try to avoid them)
