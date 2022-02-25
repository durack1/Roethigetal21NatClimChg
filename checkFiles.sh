#!/bin/bash

# Ascertain files in a directory, print this and attempt to read

# Paul J. Durack

# PJD 25 Feb 2022 - Started for /p/css03/esgf_publish/CMIP6/ScenarioMIP/EC-Earth-Consortium/EC-Earth3/ssp370/r3i1p1f1/Omon/sos/gn/v20210517/
# PJD 25 Feb 2022 - Added catch error after https://intoli.com/blog/exit-on-errors-in-bash-scripts/

# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND; file=$filename' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed on ${file} with exit code $?."' EXIT

# Get path argument from command line and assign
echo "Total arguments: $#"
if $# < 2; then
    echo "not enough arguments, quitting"
    exit 1
fi

testPath=$1
var=$2
echo "Scanning for files in $testPath"

for filename in $testPath/*.nc; do
    echo "testing: $filename"
    ncdump -h $filename
    ncdump -v $var $filename
done