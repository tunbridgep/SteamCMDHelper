# SteamCMDHelper
A simple shell script to allow SteamCMD to work better with existing Steam libraries. Designed to be POSIX Compliant.

## Overview ##

[SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) is a very interesting tool, but being suited to server environments rather than average Steam users, it suffers from some problems when it comes to automating Steam downloading for regular users who have an existing library.

For example, say we want to install [Half-Life 2 (appid 220)](https://steamdb.info/app/220/) using steamcmd.

If we have an existing library at ~/.steam/steamapps, we can pass the following command line to steamcmd:

    steamcmd +force_install_dir /home/user/.steam/steamapps/ +app_update 220 validate
    
This will run steamcmd and install all the files for Half Life 2 directly in the root steamapps directory. This is not desired, as Steam itself will not be able to see this as a valid installed game.

We could use steamcmd to install it to a more specific location - namely the steamapps/Half Life 2 directory, like this:

    steamcmd +force_install_dir "/home/user/.steam/steamapps/common/Half-Life 2" +app_update 220 validate

 but there are a few problems here, namely

1. Data directory names within steamapps/common have to be exact for Steam to detect the game. Some games have unspaced names such as "CnCRemastered" while others have proper spacing such as "DARK SOULS III". Dota 2 is strangely named "dota 2 beta". The name can be fetched manually by running steamcmd +app_info_print 220
2. SteamCMD has a bug where +force_install_dir refuses to work with spaces, meaning this will be placed in the "Half-Life" directory rather than the "Half-Life 2" directory.
3. SteamCMD creates a separate steamapps folder inside our game folder, which means the Steam client won't properly recognise the game install, and won't be able to recognise partial installs

SteamCMD Helper automates this process in the following ways:

1. It fetches the correct steamapps/common folder name for a specified appid
2. It creates the directory in the steamapps/common folder, then symlinks the steamapps folder inside it
3. It calls steamCMD with the appropriate arguments

## Installation ##

Simply download steamcmd_helper and steamcmd_settings.txt, then either invoke the script from it's directory or add it to your path

## Usage ##

SteamCMDHelper can be used to download multiple applications in sequence. It can be invoked with the following syntax

    steamcmd_helper "<steamapps path>" <appid> { <appid> }...
    
If I wanted to download Half-Life 2 and Boneworks to my steamapps folder, I could do so with

    steamcmd_helper "/home/user/.steam/steamapps/" 220 823500
    
Any additional commands placed in the file steamcmd_settings.txt will be sent to steamcmd using the [+runscript](https://developer.valvesoftware.com/wiki/SteamCMD#Automating_SteamCMD) command. A sample steamcmd_settings.txt file is provided. This can be used to input user information and force SteamCMD to download windows versions of games (for a dual boot, or for playing with Wine/Proton etc)

Help can be provided with

    steamcmd_helper --help
    
## FAQ ##

*Why do I have to specify my steamapps folder every time?*
The script needs to know where your steamapps folder is so that it can create a link to it

*Where do I place steamcmd_settings.txt?*
In the current working directory. This would normally be your home directory, but it doesn't have to be, as long as you run the script from the same place. If the file is not present, nothing will break, but steamcmd will likely ask you to login which may or may not work correctly.

*I have found a bug or have a feature suggestion. What can I do?*
You can report bugs or request new features on the issues page. I also accept pull requests.
