#! /bin/bash

### Constants
HISTORY_LOCATION="./history"

### Functions

# Displays usage information
usage()
{
    echo "usage: dirDiff [[[-w watch] [-d dry] [-i interactive]] | [-h]]"
}

# Additional info for debug
showDebugInfo()
{
    echo "DEBUG:"

    echo "watch: $watch"
    echo "interactive: $interactive"
    echo "dry: $dry"

    echo "historyFile: $historyFile"

    echo
    echo "newHistory: ${#newHistory[@]} elements"
    printf "%s\n" "${newHistory[@]}"
    
    echo
    echo "oldHistory: ${#oldHistory[@]} elements"
    printf "%s\n" "${oldHistory[@]}"

    showDiff
}

# Prints actual final diff
showDiff()
{
    echo
    echo "Diff:"
    printf "%s\n" "${diff[@]}"
}

# Recursively scan directory and push all filenames into newHistory array
deepScan()
{
    echo "Scanning..."
    for file in ${1}/*; do
	if [ -d "$file" ]; then
	    if [ "$dry" != "1" ]; then
		newHistory+=("$file")
	    else
		newHistory+=("$file")
	    fi
	    deepScan "${file}"
	else
	    if [ "$dry" != "1" ]; then
		newHistory+=("$file")
	    else
		newHistory+=("$file")
	    fi
	fi
    done
}

# React history file and push all filenames stored in it into oldHistory array
getOldHistory() {
    if [ -e "$historyFile" ]; then
	echo "Scanning old history..."
	while IFS= read line
	do
	    # display $line or do somthing with $line
	    oldHistory+=("$line")
	done < "$historyFile"
    else
	echo "No history detected."
    fi
}

# Basic interactive mode
runInteractive()
{
    if [ "$interactive" = "1" ]; then
	response=

	echo -n "Enter full path to directory to watch > "
	read response

	if [ -n "$response" ]; then
	    watch=$response
	fi

	echo -n "Should dirDiff dry run? (y/n) > "
	read response

	if [ "$response" = "y" ]; then
	    dry=1
	fi
    fi
}

# Basic compare mechanic
compareHistory()
{
    diff=()

    # Get additions diff
    for i in "${newHistory[@]}"; do
	skip=
	for j in "${oldHistory[@]}"; do
            [[ $i == $j ]] && { skip=1; break; }
	done
	[[ -n $skip ]] || diff+=("+ $i")
    done

    # Get deletions diff
    for i in "${oldHistory[@]}"; do
	skip=
	for j in "${newHistory[@]}"; do
            [[ $i == $j ]] && { skip=1; break; }
	done
	[[ -n $skip ]] || diff+=("- $i")
    done
}

# See if history directory exists and create it not
checkForHistoryDir()
{
    if [ -d "$dirname" ]; then
	echo "History directory already exists..."
    else
	echo "History directory does not exist. Creating..."
	mkdir -p -- "$dirname"
    fi
}


### Main

interactive=
watch=
dry=
dirname="history"
newHistory=()
oldHistory=()

checkForHistoryDir

# If no arguments are given - show usage info
if [ "$1" = "" ]; then
    usage
    exit 1
fi

# Check arguments and set flags based on arguments
while [ "$1" != "" ]; do
    case $1 in
	-w | --watch )        shift
			      watch=$1
			      ;;

	-i | --interactive )  shift
			      interactive=1
			      ;;


	-d | --dry )          shift
			      dry=1
			      ;;

	-h | --help )         shift
			      usage
			      exit
			      ;;

	* )                   shift
			      usage
			      exit 1
    esac
    shift
done

# Run in interactive mode
if [ "$interactive" != "" ]; then
    runInteractive
fi

# Stop execution if we don't know which directory we should watch
if [ "$watch" = "" ]; then
    echo "ERROR: Target directory was not specified"
    exit 1
fi

# Concatenate path to history file for this run
historyFile="${dirname}/${watch##*/}.txt"

getOldHistory

deepScan "${watch}"

compareHistory

# Write files only if dry run is disabled
if [ "$dry" != "1" ]; then
    if [ "${#oldHistory[@]}" = "0" ]; then
	echo "Creating new history file..."
	printf "%s\n" "${newHistory[@]}" > ${historyFile}
    else
	echo "Updating history..."
	printf "%s\n" "${newHistory[@]}" > ${historyFile}
    fi

    showDiff
fi

# Show debug info only if dry run is enabled
if [ "$dry" = "1" ]; then
    showDebugInfo
fi
