#!/bin/bash

# Ascertain netcdf/*.nc files in a directory, print header and attempt to
# read variable

# Paul J. Durack

# PJD 25 Feb 2022 - Started for /p/css03/esgf_publish/CMIP6/ScenarioMIP/EC-Earth-Consortium/EC-Earth3/ssp370/r3i1p1f1/Omon/sos/gn/v20210517/
# PJD 25 Feb 2022 - Added catch error after https://intoli.com/blog/exit-on-errors-in-bash-scripts/
# PJD 25 Feb 2022 - Added help block

## Add functional block
# Add help block
Help()
{
   # Display Help
   echo "Provide netcdf file path and variable name and test"
   echo "to read file header and variable"
   echo
   echo "Syntax: checkFiles.sh [-h|v] filePath variableName"
   echo "options:"
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo
}

# Get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done

# Add exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND; file=$filename' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed on ${file} with exit code $?."' EXIT
## end functional block

## Start operating script
# get commandline filepath and var arguments and validate count
echo "Total arguments: $#"
if [[ "$#" != 2 ]]; then
    >&2 echo "$# is not enough arguments, quitting"
    exit 2
fi

# Assign commandline arguments to variables and start file reads
testPath=$1
var=$2
echo "Scanning for files in $testPath"

for filename in $testPath/*.nc; do
    echo "testing: $filename"
    ncdump -h $filename
    ncdump -v $var $filename
done