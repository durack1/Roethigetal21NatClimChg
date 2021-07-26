#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 26 11:30:22 2021

This file has been written to reformat netcdf matrices into grid ascii output

PJD 26 May 2021     - Started
                    Notes: https://stackoverflow.com/questions/24876331/writing-an-ascii-file-from-a-2d-numpy-array
PJD 28 May 2021     - Consider stringIO module
                    Notes: https://www.geeksforgeeks.org/stringio-module-in-python/
                    https://stackoverflow.com/questions/24876331/writing-an-ascii-file-from-a-2d-numpy-array
PJD 28 May 2021     - Updated to extract Palau data; Generated writeGridAscii function for generic outputs
PJD 26 Jul 2021     - Update Palau spatial range 2 to 10, 130 to 136 -> -10 to 20, 120 to 160
PJD 26 Jul 2021     - flip upside down - https://github.com/durack1/Roethigetal21NatClimChg/issues/1
                    TODO: ?

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
import cdutil as cdu
import datetime
import numpy as np
import pathlib
#import pdb

# %% function def


def writeGridAscii(matrix, outfile):
    # get coords from matrix
    lat = matrix.getLatitude()
    lon = matrix.getLongitude()
    # create format defaults
    noData = -99999
    strFormat = '{:6.3f}'
    with open(outfile, 'w') as fO:
        fO.write("ncols " + str(matrix.shape[1]) + "\n")
        fO.write("nrows " + str(matrix.shape[0]) + "\n")
        fO.write("xllcorner " + str(lon[0]) + "\n")
        fO.write("yllcorner " + str(lat[0]) + "\n")
        fO.write("cellsize " + str(lat[1]-lat[0]) + "\n")
        fO.write("NODATA_value " + str(noData) + "\n")
        # loop through lats
        for count, lats in enumerate(lat):
            print(count, lats)
            # loop through lons, reset outstr
            outStr = ''
            for count2, latVal in enumerate(matrix[count, :]):
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
                    outStr = outStr + ' ' +\
                        str(strFormat.format(matrix[count, count2]))
            fO.write(outStr + "\n")


# %% get inputs
parser = argparse.ArgumentParser(
    description='Convert a netcdf file to grid ascii')
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
# Append time to outfile, prevent overwrites
timeNow = datetime.datetime.now();
timeFormat = timeNow.strftime("%y%m%dT%H%M%S")
# Find filename (exclude path and append timeFormat)
outFileName = outfile.split('/')[-1]
outFileNameNew = '_'.join([timeFormat, outFileName])
outfile = outfile.replace(outFileName, outFileNameNew)
print('outfile:', outfile)

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

# %% regrid data
# Preload WOA18 grids
#warnings.simplefilter('error')
woa         = cdm.open('/work/durack1/Shared/obs_data/WOD18/190501_1210_WOD18_masks_0p25deg.nc')
s           = woa('basinmask')
woaGrid     = s.getGrid() ; # Get WOA target grid
woaLat      = s.getLatitude()
woaLon      = s.getLongitude()
woa.close()
sos025 = sos.regrid(woaGrid,regridTool='ESMF',regridMethod='linear')
print('s:\n', sos.shape)
print('s025:\n', sos025.shape)
#pdb.set_trace()

# %% write global data
writeGridAscii(sos, outfile)

# %% extract Palau data and write
latBounds = [-10, 20] ##[2, 10]
lonBounds = [120, 160] ##[130, 136]
palauDomain = cdu.region.domain(latitude=latBounds, longitude=lonBounds)
sosPalau = palauDomain.select(sos025)
print('sosPalau:\n', sosPalau)
# And flip upside down (N is on bottom, will be on top once flipped)
sosPalau = np.flip(sosPalau, axis=0)
print('sosPalau:\n', sosPalau)
outfile = infile.replace('.nc', '_PalauDomain-025deg.txt')
# Find filename (exclude path and append timeFormat)
outFileName = outfile.split('/')[-1]
outFileNameNew = '_'.join([timeFormat, outFileName])
outfile = outfile.replace(outFileName, outFileNameNew)
writeGridAscii(sosPalau, outfile)
