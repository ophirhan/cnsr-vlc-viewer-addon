# CNSR-vlc-viewer-addon

**An add-on for VLC media player.**

[![License](https://img.shields.io/badge/License-GPL3-red.svg)](https://www.gnu.org/licenses/gpl-3.0.html)


# Description

VLC plugin for real-time media censorship according to user personal settings,
using [CNSR file format](https://github.com/ophirhan/cnsr-file-format-specification).

This plugin censors categories like nudity, verbal abuse, violence and alchohol and drug consumption.
The extension is also available [here](https://addons.videolan.org/p/1537958/).

This extension is inspired by [MEDERI's "Time v3.2" vlc extension](https://addons.videolan.org/p/1154032/).

Supported OS: Windows, Linux and Mac OS.
_____________________________________________________________________________________________________

# Getting started

1. If you don't have VLC in your computer, install from [VLC](https://www.videolan.org/)
2. download the repository: press on the "CODE" green button, and choose the option: "Download zip".
![Screenshot_061221_040915_PM](https://user-images.githubusercontent.com/19567966/121777049-c8d80580-cb98-11eb-9ac7-6db63a0c518f.jpg)
3. Find your way to these two files: 
-cnsr-vlc-viewer-addon/blob/main/extensions/cnsr_ext.lua
-cnsr-vlc-viewer-addon/blob/main/intf/cnsr_intf.lua
			       
4. Access lua folder using these paths:

    If you want the extension to be available for all the users of the 
    computer and not only the user currently logged in choose the all users path.<br/>
        - Windows<br/>
            - `%ProgramFiles%\VideoLAN\VLC\lua` (all users)<br/>
            - `%APPDATA%\VLC\lua` (current user)<br/>
            - If The commands above did not work, go to `%ProgramFiles%\VideoLAN\VLC` or `%APPDATA%\VLC` folder(according to your choice to which user to install). 
	    this can be done by getting to the run pannel(Windows + R, or search run in the windows search bar) and type `%ProgramFiles%\VideoLAN\VLC` 
	    or `%APPDATA%\VLC`(according to your choice). Create a folder named "lua" and inside this folder create 2 folders named "extensions" and "intf".<br/>
	- Linux<br/>
            - `/usr/lib/vlc/lua` (all users)<br/>
            - `~/.local/share/vlc/lua` (current user)<br/>
            - If The commands above did not work, go to `/usr/lib/vlc` or `~/.local/share/vlc` folder(according to your choice to which user to install). 
	    this can be done by typing `cd /usr/lib/vlc` or `cd ~/.local/share/vlc`. Create a folder named "lua" and inside this folder create 2 folders named "extensions" and 	    "intf".<br/>
	- Mac OS<br/>
            - `/Applications/VLC.app/Contents/MacOS/share/lua` (all users)<br/>
            - `/Users/%your_name%/Library/Application Support/org.videolan.vlc/lua (current user)<br/>`

  
5. Move `cnsr_ext.lua` to \lua\extensions\ folder.
6. Move `cnsr_intf.lua` to \lua\intf\ folder.
7. Start the Extension in VLC menu
    - `View > cnsr` for Windows/Linux.
    - `VLC > Extensions > cnsr` for Mac OS.
8. Configure the cnsr categories to your liking.

# For developers

1. Change the lua folder's name to `luab`.

2. Clone the repository a new folder named `lua`

3. Copy the contents of `luab` dir to `lua` dir

4. Delete `luab` dir

and that's it! you are ready to start.<br/>
To interact with VLC we use the API documented [here](https://github.com/videolan/vlc/blob/master/share/lua/README.txt).<br/>
Also if you're just getting started with lua here are some important things that set it apart from other programming languages:<br/>
tables are equivalent to hashsets and arrays simultaneously, their index starts from 1 (not 0).<br/>
[This tutorial](https://www.tutorialspoint.com/lua/index.htm) will help you get up and running with lua in little to no time.<br/>
As for a prefered IDE we use intellij IDEA, but [eclipse](https://www.eclipse.org/ldt/#installation) should work as well (maybe better).

# How to use cnsr files:
NOTE: At this point, The cnsr file is not created automatically or by itself.<br/>
 the user has to watch the video file and decide on the appropriate tags by himself and enter the relevant timestamps.<br/>

Possible tags:<br/>
1 for violence<br/>
2 for verbal violence<br/>
3 for nudity<br/>
4 for alcohol and drug use<br/>

You can see an example of a cnsr file [here](https://github.com/ophirhan/cnsr-vlc-viewer-addon/tree/main/example)<br/>
- Explanation of the timestamps displayed: hours:minutes:seconds,millis

In order to make use of cnsr file you need to create a new file with the format as shown in `example/example_file.cnsr`.<br/>
The file name must be identical to the video name you want to play (except for the ending), and must be at the same directory as the video.

For example, if the video you want to play is: <br>
`/foo/bar/myvid.mp4` <br>
Then the cnsr file should be: <br>
`/foo/bar/myvid.cnsr` <br>

#NOTICE
- Currently there is an issue with directoris that have underscore or spaces, so please try to avoid them

# Founders

[Eyal Ben Tovim](https://github.com/eyal1889) [Ophir Han](https://github.com/ophirhan) [Eldar Lerner](https://github.com/eldarlerner)

