#! /bin/bash

### Constants
HISTORY_LOCATION="./history"

### Functions

usage()
{
    echo "usage: dirDiff [[[-w watch] [-d dry] [-i interactive]] | [-h]]"
}

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

showDiff()
{
    echo
    echo "Diff:"
    printf "%s\n" "${diff[@]}"
}

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

compareHistory()
{
    diff=()

    for i in "${newHistory[@]}"; do
	skip=
	for j in "${oldHistory[@]}"; do
            [[ $i == $j ]] && { skip=1; break; }
	done
	[[ -n $skip ]] || diff+=("+ $i")
    done

    for i in "${oldHistory[@]}"; do
	skip=
	for j in "${newHistory[@]}"; do
            [[ $i == $j ]] && { skip=1; break; }
	done
	[[ -n $skip ]] || diff+=("- $i")
    done
}

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

if [ "$1" = "" ]; then
    usage
    exit 1
fi

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

if [ "$interactive" != "" ]; then
    runInteractive
fi

if [ "$watch" = "" ]; then
    echo "ERROR: Target directory was not specified"
    exit 1
fi

historyFile="${dirname}/${watch##*/}.txt"

getOldHistory

deepScan "${watch}"

compareHistory

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

if [ "$dry" = "1" ]; then
    showDebugInfo
fi
