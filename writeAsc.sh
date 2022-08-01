    #!/bin/bash
# -*- coding: utf-8 -*-

# Created on Mon Aug 30 09:36:42 2021

# Script to generate netcdf files from mat file, write grid ascii output from
# netcdf input
# Requires cdms in execution env

# PJD 20 Sep 2021   - Update with args to regenerate netcdf e.g. "nc", or select scenarios e.g. "historical"
# PJD  6 May 2022   - Added workDir
# PJD 10 May 2022   - Added -v as argument

# @author: durack1

# Generate fresh netcdf files from mat input
if [ "$1" == "nc" ]; then
    echo "Recreating nc files"
    python readMatWriteNc.py
else
    echo "Using existing nc files"
fi

# Get list of output netcdf files
workDir=/p/user_pub/climate_work/durack1/Shared/
srcPath=${workDir}210128_PaperPlots_Rothigetal
echo "Searching for files matching \"$2\""
files=`ls "$srcPath"/*$2*.nc`

# Print for testing
for file in $files; do
    echo "$file"
    echo "${file/nc/txt}"
    # Call Python and write ascii
    python readNcWriteAsc.py \
    -i "$file" \
    -v "$2" \
    -o "${file/nc/txt}"
done
