#!/bin/bash
# -*- coding: utf-8 -*-

# Created on Mon Aug 30 09:36:42 2021

# Script to generate netcdf files from mat file, write grid ascii output from
# netcdf input
# Requires cdms in execution env

# PJD 20 Sep 2021   - Update with args to regenerate netcdf e.g. "nc", or select scenarios e.g. "historical"
# PJD  6 May 2022   - Added workDir
# PJD 10 May 2022   - Added -v as argument
# PJD  5 Aug 2022   - Reversed args, as nc is not often used

# Usage example
# $ ./writeAsc.sh $var $nc
# $ ./writeAsc.sh sos nc
#
# $1 = var to search for, $2 whether new netcdf files should be written first

# @author: durack1

# Generate fresh netcdf files from mat input
if [ "$2" == "nc" ]; then
    echo "Recreating nc files"
    python readMatWriteNc.py
else
    echo "Using existing nc files"
fi

# Get list of output netcdf files
workDir=/p/user_pub/climate_work/durack1/Shared/
srcPath=${workDir}210128_PaperPlots_Rothigetal
echo "Searching for files matching \"$1\""
files=`ls "$srcPath"/*$1*.nc`

# Print for testing
for file in $files; do
    echo "$file"
    echo "${file/nc/txt}"
    # Call Python and write ascii
    python readNcWriteAsc.py \
    -i "$file" \
    -v "$1" \
    -o "${file/nc/txt}"
done
