#!/bin/bash

#display help when we have wrong number of arguments
#or we type "--help"
if [ $# -lt 2 ] || [ $1 == "--help" ]; then
    echo "usage: $0 <steamapps> <steam_app_ids>"
    echo "will download game with <app_id> to <steamapps>/common/<game name>"
    echo "<steamapps> must be a valid steamapps folder"
    echo "the file steamcmd_settings.txt will automatically be passed to steamcmd as a script file."
    echo "Do your account etc. setup in that file."
    echo "If it doesn't exist, there will NOT be an opportunity to login to steam as part of this script,"
    echo "meaning most likely it will not work at all"
    echo ""
    echo "appids should be space separated"
    echo "appids can be found at https://steamdb.info/"
    exit 1
fi

#PROCESS FIRST ARGUMENT
if ! [ -d "$1/common" ]; then
#if ! [ -d "$1/common" ] || ! [ -f "$1/libraryfolders.vdf" ]; then
    echo "$1 is not a valid path"
    exit 1
fi

#generate our command line string
command="steamcmd"
options_path=$(realpath ./steamcmd_settings.txt)

#add our options file if it exists
if [ -f "./steamcmd_settings.txt" ]; then
    script=' +runscript "'${options_path}'"'
else
    script=""
fi

#make our temp folder
#temp="$HOME/.steam/steamcmd/temp"
temp="$1/steamcmd_temp"
real_install_dir="$temp/game"
mkdir -p "$temp"

#PROCESS ALL OTHER ARGUMENTS
#These should be strings in the form a=b, each separated by a space

#process each argument
count=0
processed=0
for arg in "$@"
do
    #skip the first argument - it's the path, we just want
    #the delimited list of values
    if [ $count -gt 0 ]; then

        #check that our argument is numeric
        case $arg in
            ''|*[!0-9]*) echo "($arg)" contains non-numeric characters. Skipping && continue ;;
            *) ;;
        esac

        #clear out our temp dir
        rm -f "$real_install_dir"

        #so, we have validated our appid. Now we need to get it's folder information
        #echo "$command$script +app_info_print "${arg}" +quit"
        $(eval "$command$script +app_info_print "${arg}" +quit > $temp/appid.txt")

        #now that we have the app info in a file, we can grep it for the install directory
        #I better explain this monstrosity because it's awful.
        #so first we grep our temp file for the "installdir" line, which tells steam the name of the folder
        #that the game is supposed to be installed into (we can't change this).
        #then we use cut to find the fourth "section" (based on whitespace) that is broken up by quotes
        #so if our line was
        #    "installdir"         "cool game"
        #1   2          3         4         5
        #section 4 starts just after the quote mark and goes until the 5th quote mark
        #the monstrous bundle of quotes you see below is because we need to tell cut what our delimiter is
        #(it's a ") which means we have to put it in single quotes like: cut -d '"' -f4
        #but since we are already using quotes for our eval, we have to use strings of different type
        #it would look much better spaced out, but cut complains if we do that
        #this should make more sense: cut -d'  "'" <-left  '"' <-delim "'" <-right ' -f4'
        installdir=$(eval 'grep -m 1 -w -e "installdir" $temp/appid.txt | cut -d '"'"'"'"'"' -f4')
        appname=$(eval 'grep -m 1 -w -e "name" $temp/appid.txt | cut -d '"'"'"'"'"' -f4')
        echo "==========================================="
        echo "App Name: "$appname
        echo "==========================================="

        #remove the temp file we created
        rm -f "$temp/appid.txt"

        if [ "$installdir" == "" ]; then
            echo "an error occurred retrieving the app information for appid ${arg}"
            continue
        fi

        #we want to download <appid> to <$installdir>
        #since the argument was in the form of
        #so our fullpath is <steamapps>($1)/common/$installdir
        #if we had a leading trail in our path,
        #it will be $1/common//$installdir, but don't worry
        #bash handles that for us
        dir=$1/common/$installdir

        #make a directory for our game
        mkdir -p "$dir"

        #now that our dir is created, point our game dir there
        #echo ln -s "$dir" "$real_install_dir"
        ln -s "$dir" "$real_install_dir"

        #we need to make a symlink to our steamapps dir
        #inside the folder for the game we are downloading
        #because of a quirk with the way that SteamCMD works
        if ! [ -L "$real_install_dir/steamapps" ]; then
            #echo ln -s "$1" "$real_install_dir/steamapps"
            ln -s "$1" "$real_install_dir/steamapps"
        fi

        #we need to create strings the tool will recognise
        #by setting the install dir and telling it
        #to update and validate various games
        #validation is technically options, but recommended
        dir_string=' +force_install_dir "'$real_install_dir'"'
        app_string=" +app_update $arg validate"

        #and now we are ready to go
        #echo "$command$script$dir_string$app_string +quit"
        eval "$command$script$dir_string$app_string +quit"

        #keep track of how many downloads we processed
        processed=$((processed + 1))

        #remove unneeded steamapps link left over
        #there is a confirmation step too, just in case. But it's slow
        #because of the lack of -r, it should theoretically be impossible
        #for this to wipe out the real steamapps dir, in case anything really, really bad happens
        #echo 'going to remove "'${dir}'/steamapps" symlink. Please verify that the following is correct...'
        rm -f "$real_install_dir/steamapps"

        #remove random EmptySteamDepot folder (likely a bug in SteamCMD)
        if [ -d "$real_install_dir/EmptySteamDepot" ]; then
                rm -rf "$real_install_dir/EmptySteamDepot"
        fi

        #add appname to our list of processed apps
        if [ $processed -gt 1 ]; then
            processed_list=$processed_list", "$appname
        else
            processed_list=$appname
        fi

        #display finished message
        echo "finished processing $appname"
    fi
    count=$((count + 1))
done
if [ $processed -gt 0 ]; then
    echo "finished. Processed $processed downloads: $processed_list"
else
    echo "finished. Processed $processed downloads."
fi
        
#remove our temp directory
rm -rf "$temp"
