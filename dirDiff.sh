#! /bin/bash

### Constants
HISTORY_LOCATION="./history"

### Functions

usage()
{
    echo "usage: dirDiff [[[-w watch] [-d dry] [-i interactive]] | [-h]]"
}

deepScan()
{
    for file in ${1}/*; do
    	if [ -d "$file" ]; then
    	    deepScan "${file}"
    	else
    	    echo ${file##*/}
    	fi
    done
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

### Main

interactive=
watch=
dry=

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
       
# deepScan(${watch})

if [ "$interactive" != "" ]; then
    runInteractive
fi

if [ "$watch" = "" ]; then
    echo "ERROR: Target directory was not specified"
    exit 1
fi

deepScan "${watch}"

# for file in ${watch}/*; do
#     if [ -d "$file" ]; then
# 	echo "directory" ${file##*/}
#     else
# 	echo ${file##*/}
#     fi
# done

echo "DEBUG:"
echo "$watch"
echo "$interactive"
echo "$dry"
