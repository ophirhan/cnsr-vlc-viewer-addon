# This module installs the extension by creating link between this project's lua files and the VLC repo project's files

import platform
import os
import logging

logging.basicConfig(level=logging.DEBUG)

LINUX = "linux"
OSX = "darwin"
WINDOWS = "windows"

MODULES = ["extensions/cnsr_ext.lua", "intf/cnsr_intf.lua", "modules/cnsr_memory.lua"]


class NoAdmin(Exception):
    pass


def install_non_windows(vlc_path):
    for module in MODULES:
        vlc_loc = f"{vlc_path}/{module}"
        os.remove(vlc_loc)
        os.symlink(src=f"{os.getcwd()}/../{module}", dst=vlc_loc)


if __name__ == "__main__":
    if os.getuid() != 0:
        raise NoAdmin("This program must be run as sudo or administer")

    system = platform.system().lower()

    if system == OSX:
        install_non_windows("/Applications/VLC.app/Contents/MacOS/share/lua")
    elif system == LINUX:
        raise NotImplementedError()
    elif system == WINDOWS:
        raise NotImplementedError()

    logging.info("Finished installation")
