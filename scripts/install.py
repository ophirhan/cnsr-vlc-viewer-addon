# This module installs the extension by creating link between this project's lua files and the VLC repo project's files

import platform
import subprocess
import os
import logging

logging.basicConfig(encoding='utf-8', level=logging.DEBUG)

LINUX = "linux"
OSX = "darwin"
WINDOWS = "windows"

if __name__ == "__main__":
    system = platform.system().lower()

    if system == OSX:
        shellscript = subprocess.Popen(f"sudo -S {os.getcwd()}/install_plugin_osx.sh".split(),
                                       stdout=subprocess.PIPE)
        code = shellscript.wait()
        output, error = shellscript.communicate()
        if code != 10:
            raise Exception(
                f"Failed to run mac installer with error. exit_code={code}, errors={error}, output={output}")

    elif system == LINUX:
        raise NotImplementedError()
    elif system == WINDOWS:
        raise NotImplementedError()

    logging.info("Finished installation")
