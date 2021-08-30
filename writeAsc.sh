#!/bin/bash
# -*- coding: utf-8 -*-

# Created on Mon Aug 30 09:36:42 2021

# Script to generate netcdf files from mat file, write grid ascii output from
# netcdf input
# Requires cdms in execution env

# @author: durack1

# Generate fresh netcdf files from mat input
python readMatWriteNc.py

# Get list of output netcdf files
srcPath=/work/durack1/Shared/210128_PaperPlots_Rothigetal
files=`ls "$srcPath"/*.nc`

# Print for testing
for file in $files; do
    echo "$file"
    echo "${file/nc/txt}"
    # Call Python and write ascii
    python readNcWriteAsc.py \
    -i "$file" \
    -o "${file/nc/txt}"
done
