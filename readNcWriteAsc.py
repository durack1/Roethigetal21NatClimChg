#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 26 11:30:22 2021

This file has been written to reformat netcdf matrices into grid ascii output

PJD 26 May 2021     - Started
                    Notes: https://stackoverflow.com/questions/24876331/writing-an-ascii-file-from-a-2d-numpy-array
PJD 28 May 2021     - Consider stringIO module
                    Notes: https://www.geeksforgeeks.org/stringio-module-in-python/
                    TODO: pull out Palau data

Target:
ncols        360
nrows        180
xllcorner    -0.500000000000
yllcorner    -90.000000000000
cellsize     1.000000000000
 30.681314468383789062

@author: durack1
"""

# %% imports
import argparse
import cdms2 as cdm
#import io
import numpy as np
import pathlib
import sys
#import time
#from io import StringIO

# %% get inputs
parser = argparse.ArgumentParser(description='Convert a netcdf file to grid ascii')
parser.add_argument('-i', '--infile', type=pathlib.Path,
                    help='a valid input netcdf file')
parser.add_argument('-o', '--outfile', type=pathlib.Path,
                    help='a valid output grid ascii file')
args = parser.parse_args()
print(args)
print('args.infile:', args.infile)
infile = str(args.infile)
print('infile:', infile)
outfile = str(args.infile).replace('.nc', '.txt')
print('outfile:', outfile)
#sys.exit()

# %% read data
fH = cdm.open(infile)
sos = fH('sos')
lat = sos.getLatitude()
lon = sos.getLongitude()
print('sos.shape:', sos.shape)
print('lat[0]:', lat[0])
print('lon[0]:', lon[0])
print('cellsize:', lat[1]-lat[0])
#print('sos[0,:]:', sos[0,:])
fH.close()

# %% write data
noData = -99999
strFormat = '{:6.3f}'
with open(outfile, 'w') as fO:
    fO.write("ncols " + str(sos.shape[1]) + "\n")
    fO.write("nrows " + str(sos.shape[0]) + "\n")
    fO.write("xllcorner " + str(lon[0]) + "\n")
    fO.write("yllcorner " + str(lat[0]) + "\n")
    fO.write("cellsize " + str(lat[1]-lat[0]) + "\n")
    fO.write("NODATA_value " + str(noData) + "\n")
    # loop through all lats
    for count, lats in enumerate(lat):
        print(count, lats)
        # loop through all lons
        outStr = ''
        for count2, latVal in enumerate(sos[count,:]):
            #print('latVal:', latVal,'D', 'type:', type(latVal))
            if np.isnan(latVal):
                outStr = outStr + ' ' + str(noData)
                #print('nan found')
            elif latVal == 0.5:
                 outStr = outStr + ' ' + str(noData)
                 #print('0.5 found')
            elif latVal == 1.0:
                 outStr = outStr + ' ' + str(noData)
                 #print('1.0 found')
            else:
                #print('format:', str(strFormat.format(sos[count,count2])))
                outStr = outStr + ' ' + str(strFormat.format(sos[count,count2]))
        #print(count, count2, 'outStr:', outStr)
        #print('-----')
        #time.sleep(3)
        fO.write(outStr + "\n")


# f = StringIO()
# x = np.array(( -9999, 1.345, -9999, 3.21, 0.13, -9999), dtype=float)
# np.savetxt(f, x, fmt='%.3f')
# f.seek(0)
# fs = f.read().replace('-9999.000', '-9999', -1)
# f.close()
# f = open('ASCIIout.asc', 'w')
# f.write("ncols " + str(ncols) + "\n")
# f.write("nrows " + str(nrows) + "\n")
# f.write("xllcorner " + str(xllcorner) + "\n")
# f.write("yllcorner " + str(yllcorner) + "\n")
# f.write("cellsize " + str(cellsize) + "\n")
# f.write("NODATA_value " + str(noDATA) + "\n")
# f.write(fs)
# f.close()

# %% extract Palau info
latBounds = [2, 9]
lonBounds = [130, 135]