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

1. Data directory names within steamapps/common have to be exact for the Steam client to detect the game. Some games have unspaced names such as "CnCRemastered" while others have proper spacing such as "DARK SOULS III". Dota 2 is strangely named "dota 2 beta". The name can be fetched manually by running steamcmd +app_info_print 220
2. SteamCMD has a bug where +force_install_dir refuses to work with spaces, meaning this will be placed in the "Half-Life" directory rather than the "Half-Life 2" directory.
3. SteamCMD creates a separate steamapps folder inside our game folder, which means the Steam client won't properly recognise the game install, and won't be able to recognise partial downloads

SteamCMDHelper automates this process in the following ways:

1. It fetches the correct steamapps/common folder name for a specified appid
2. It creates the directory in the steamapps/common folder, then symlinks the steamapps folder inside it
3. It calls SteamCMD with the appropriate arguments

It cleans up the symbolic links after creation, and is able to run multiple appids in sequence.

## Installation ##

Simply download steamcmd_helper and steamcmd_settings.txt, then either invoke the script from it's directory or add it to your path.

## Usage ##

SteamCMDHelper can be used to download multiple applications in sequence. It can be invoked with the following syntax:

    steamcmd_helper "<steamapps path>" <appid> { <appid> }...
    
If I wanted to download Half-Life 2 and Boneworks to my steamapps folder, I could do so with

    steamcmd_helper "/home/user/.steam/steamapps/" 220 823500
    
SteamCMD will log in using the username and password provided in the file steamcmd_settings.txt, which will be sent to it using the [+runscript](https://developer.valvesoftware.com/wiki/SteamCMD#Automating_SteamCMD) command. A sample steamcmd_settings.txt file is provided. Additional commands can be added here as well, such as forcing SteamCMD to download Windows versions of games (for a dual boot, or for playing with Wine/Proton etc). You should modify this file before first running the script, as you will need to insert your login information (only your username is required)

Help can be provided with

    steamcmd_helper --help

## Troubleshooting ##

In order to download games using SteamCMD, you will need to provide login details. If you do not do this, you will get the following error:

    ERROR! Failed to request AppInfo update, not online or not logged in to Steam.
    
This is because SteamCMD is trying to work in "anonymous" mode. The solution is to make sure you have your username and password set in the login field in steamcmd_settings.txt (like in the sample file). If you do not wish to store this information, providing just your username is enough. If the script gets stuck on the following command:
    
    Logging in user '<your user name>' to Steam Public ...
    
It isn't stuck. You simply need to type your password and press enter to continue. This should only be required the first time you use the script if you don't provide your password in the file.

## FAQ ##

**Why do I have to specify my steamapps folder every time?**

The script needs to know where your steamapps folder is so that it can create a link to it

**Where do I place steamcmd_settings.txt?**

In the current working directory. This would normally be your home directory, but it doesn't have to be, as long as you run the script from the same place. If the file is not present, nothing will break, but steamcmd will likely ask you to login which may or may not work correctly.

**I have found a bug or have a feature suggestion. What can I do?**

You can report bugs or request new features on the issues page. I also accept pull requests.

**The code kind of sucks**

Yes. It needs a refactor. I am not the best shell scripter out there, but if you feel like you want to help rewrite it, I accept pull requests.

**Why does the script produce so much extra unnecessary output?**

There is no way to run SteamCMD in "silent mode" or any equivalent, and redirecting output to a file is problematic as it can hide login prompts etc.

**I ended the script early and it left a hidden file in my current working dir. Is that safe to delete?**

The script uses temporary files to make steamcmd work. These can be safely deleted
