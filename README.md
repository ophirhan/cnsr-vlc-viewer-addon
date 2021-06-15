# CNSR vlc viewer add-on

VLC add-on for real-time media censorship according to user personal settings,
using [CNSR file format](https://github.com/ophirhan/cnsr-file-format-specification).

This add-on censors categories like nudity, verbal abuse, violence and alchohol and drug consumption.
The add-on is also available [here](https://addons.videolan.org/p/1537958/).

This add-on is inspired by [MEDERI's "Time v3.2" vlc extension](https://addons.videolan.org/p/1154032/).

Supported OS: Windows, Linux and Mac OS.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Installing the add-on for regular use

1. If you don't have VLC in your computer, install from [VLC](https://www.videolan.org/)
2. download the repository: press on the "CODE" green button, and choose the option: "Download zip".
![Screenshot_061221_040915_PM](https://user-images.githubusercontent.com/19567966/121777049-c8d80580-cb98-11eb-9ac7-6db63a0c518f.jpg)
			       
3. If you want the add-on to be available for all the users of the 
    computer, access the `lua` folder using these paths:
   - Windows- `%ProgramFiles%\VideoLAN\VLC\lua`<br/>
   - Linux- `/usr/lib/vlc/lua` or use the command `find /usr/lib -iname VLSub.luac` to find the directory <br/>
   - MacOS- `/Applications/VLC.app/Contents/MacOS/share/lua`<br/>
     <br/>
   If you want the add-on to be available only for a specific user,
   access the `lua` folder using these paths:
   - Windows- `%APPDATA%\VLC\lua`<br/>
   - Linux- `~/.local/share/vlc/lua`<br/>
   - MacOS- `/Users/%your_name%/Library/Application Support/org.videolan.vlc/lua`<br/>
   If the paths above don't exist and you already have VLC installed on your computer try to uninstall it and then reinstall it. 
   Then, make sure you are using the most updated version of VLC.
  
4. Extract the contents of the `cnsr-vlc-viewer-addon-main` directory within the downloaded zip file to the `lua` folder.
5. Start the Extension in VLC menu
    - `View > cnsr` for Windows/Linux.
    - `VLC > Extensions > cnsr` for Mac OS.
6. Click save to set the cnsr interface script as an extra interface.
7. Restart VLC
8. Start the Extension again in VLC menu
    - `View > cnsr` for Windows/Linux.
    - `VLC > Extensions > cnsr` for Mac OS.
9. Configure the cnsr categories to your liking.

### How to use CNSR files:
CNSR files are not created automatically, they must be downloaded or created manually<br/>
(in the future a [tagging tool](https://github.com/ophirhan/cnsr-tagging-tool) will be available) 
by watching the video and writing tags with time-stamps.<br/>

Possible tags:<br/>
1. for violence<br/>
2. for verbal abuse<br/>
3. for nudity<br/>
4. for alcohol and drug use<br/>

You can see an example of a cnsr file [here](https://github.com/ophirhan/cnsr-vlc-viewer-addon/tree/main/example)<br/>
- Explanation of the timestamps displayed: hours:minutes:seconds,millis

In order to make use of cnsr file you need to create a new file with the format as shown in `example/example_file.cnsr`.<br/>
The file name must be identical to the video name you want to play (except for the file type), and must be at the same directory as the video.

For example, if the video you want to play is: <br>
`/foo/bar/myvid.mp4` <br>
Then the cnsr file should be: <br>
`/foo/bar/myvid.cnsr`

#### NOTICE
- Currently there is an issue with directories that have underscore or spaces, so please try to avoid them


# Setting up the project for development
To work conveniently with git, we recommend cloning the project in your exsisting lua folder.<br/>
Since git doesn't allow to clone a project into an existing folder, we reccomend following these steps:

1. If you don't have VLC installed on your computer, install from [VLC](https://www.videolan.org/)

2. If you don't have Git installed on your computer, install from [Git](https://git-scm.com/downloads)

3. Open a terminal\CLI with admin privileges:
    - Windows- `WinKey + x > a` and approve UAC.
    - Linux- `ctrl + alt + t`, type `sudo -i` and enter password if necessary.
    - macOS- `cmd + space >`, type `terminal` type `sudo -i` and enter password if necessary.
    
4. Type `cd <lua path>` (find `lua path` according to section 3 of "Installing the add-on for regular use").
5. type `git init`
6. type `git remote add origin https://github.com/ophirhan/cnsr-vlc-viewer-addon.git`
7. type `git fetch origin`
8. type `git checkout -b main --track origin/main`

And that's it! the add-on is installed, and you are ready to start developing.<br/>

## Tips for developers
- To interact with VLC we use the API documented [here](http://git.videolan.org/?p=vlc/vlc-3.0.git;a=blob_plain;f=share/lua/README.txt).
- When debbuging in order to see the log messages you need to open the VLC messages panel via:<br/>
`ctrl + m` or `command + m`<br/>
- Since the lua folder is part of the vlc installation directory and writing to it might be proteced,<br/>
in order to save your changes you might need to open your IDE as an administartor.<br/>
### Getting started with lua
If you're just getting started with lua, here are some important things that set it apart from other programming languages:<br/>
- tables are equivalent to hashsets and arrays simultaneously, their index starts from 1 (not 0).<br/>
- lua is an interperted language no need to build anything!<br/>
- As for a prefered IDE we use intellij IDEA, but [eclipse](https://www.eclipse.org/ldt/#installation) should work as well (maybe better).<br/>

For more on lua [this tutorial](https://www.tutorialspoint.com/lua/index.htm) will help you get up and running in little to no time.<br/>


# Founders

[Eyal Ben Tovim](https://github.com/eyal1889) [Ophir Han](https://github.com/ophirhan) [Eldar Lerner](https://github.com/eldarlerner)

