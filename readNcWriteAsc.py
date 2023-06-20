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
PJD 24 Aug 2021     - Update bounds again 120 to 160E, 10S to 20N -> 120 to 145E, 8S to 19N
PJD 24 Aug 2021     - Add 0p5 output grid
PJD 30 Aug 2021     - Add sos flip
PJD 30 Aug 2021     - Commented out 0p25 outputs
PJD 20 Sep 2021     - Updated to write out global 0p5deg data
PJD  7 Oct 2021     - Updated to compute diff
PJD  6 May 2022     - Added workDir, inFile and histFile entries
PJD 10 May 2022     - Updated hardcoded sos var to variable argument
PJD  4 Aug 2022     - Updated for latest data 220729/220803mat
PJD 19 Apr 2023     - Updated for seagrass-Aust region
PJD 19 Apr 2023     - Added fillHoles function
PJD 20 Jun 2023     - Library cd315cdugencdtspy532mat352 required, as latter envs loose ESMF integration
                      bash-4.2$ ./writeAsc.sh sos
                    - Library cd315cdu821spy543mat371car0211 required for readMatWriteNc.py as scipy.loadmat required
                      bash-4.2$ python readMatWriteNc.py
PJD 20 Jun 2023     - Updated histFile 220729 -> 230321

                    TODO: ?

Target:
ncols        360
nrows        180
xllcorner    -0.500000000000
yllcorner    -90.000000000000
cellsize     1.000000000000
 30.681314468383789062

Updated region for Marshall Islands
See email 9th March and Supplementary Text (coordinates: 139° E, 192° E, 16° S, 37° N)
latBounds = [16, 37]
lonBounds = [139, 192]

Added region seagrass-Aust
https://github.com/durack1/Roethigetal21NatClimChg/issues/3#issuecomment-1499318175
@durack1 The maximum extent limits for the seagrass groups are (format: max lat, max lon, min lat, min lon):
-9, 160, -46, 113
We could just add a boundary around that to add a few degrees either side as previously I think?
Let me know of any questions and thanks! Laura

See https://docs.google.com/document/d/1sbGRVjFTLLIXCDPyEbxe7SU7QAyC4yofDtXaNflmlZU/edit

@author: durack1
"""

# %% imports
import argparse
# cd315cdugencdtspy532mat352 required, as latter envs loose ESMF integration
import cdms2 as cdm
import cdutil as cdu
import datetime
import numpy as np
import os
import pathlib
import pdb
import sys

# %% file and path def
workDir = "/p/user_pub/climate_work/durack1/Shared/"
# inFile = "230412T104649_230321_CMIP6.mat" # "220803T175312_220729_CMIP6.mat"  # "220429T143503_220427_CMIP6.mat"
# if diff is being used
# "220429T143503_220427_sos_CMIP6_historical_1985_2015_mean.nc"
# "220804T215723_220729_sos_CMIP6_historical_1985_2015_mean.nc"
histFile = "230601T165519_230321_sos_CMIP6_historical_1985_2015_mean.nc"

# %% function def


def writeGridAscii(matrix, outfile):
    # get coords from matrix
    lat = matrix.getLatitude()
    lon = matrix.getLongitude()
    # Check for edge effects
    if (lat[1]-lat[0]) != (lat[2]-lat[1]):
        print('writeGridAscii: lat step inconsistency, check inputs..')
        pdb.set_trace()
        sys.exit()
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
                    # print('nan found')
                elif latVal == 0.5:
                    outStr = outStr + ' ' + str(noData)
                    # print('0.5 found')
                elif latVal == 1.0:
                    outStr = outStr + ' ' + str(noData)
                    # print('1.0 found')
                else:
                    outStr = outStr + ' ' +\
                        str(strFormat.format(matrix[count, count2]))
            fO.write(outStr + "\n")


def fillHoles(matrix):
    # iteratively fill missing data with nearest neighbour averages
    pass


# %% get inputs
parser = argparse.ArgumentParser(
    description='Convert a netcdf file to grid ascii')
parser.add_argument('-i', '--infile', type=pathlib.Path,
                    help='a valid input netcdf file')
parser.add_argument('-v', '--variable', type=str,
                    help='a valid file variable')
parser.add_argument('-o', '--outfile', type=pathlib.Path,
                    help='a valid output grid ascii file')
parser.add_argument('-d', '--diff', type=str,
                    help='generate a change field, rather than absolute')
args = parser.parse_args()
print(args)
# print('args.infile:', args.infile)
infile = str(args.infile)
print('infile: ', infile)
# print('args.variable:', args.variable)
varName = str(args.variable)
print('varName: ', varName)
outfile = str(args.infile).replace('.nc', '.txt')
print('outfile:', outfile)
diff = str(args.diff)
print('diff:   ', diff)
# Append time to outfile, prevent overwrites
timeNow = datetime.datetime.now()
timeFormat = timeNow.strftime("%y%m%dT%H%M%S")
# Find filename (exclude path and append timeFormat)
outFileName = outfile.split('/')[-1]
outFileNameNew = '_'.join([timeFormat, outFileName])
outfile = outfile.replace(outFileName, outFileNameNew)
print('outfile:', outfile)

# %% read data
fH = cdm.open(infile)
var = fH(varName)
lat = var.getLatitude()
lon = var.getLongitude()
print('var.shape:', var.shape)
print('lat[0]:', lat[0])
print('lon[0]:', lon[0])
print('cellsize:', lat[1]-lat[0])
# print('sos[0,:]:', sos[0,:])
fH.close()

# %% regrid data
# Preload WOA18 0p25 grid
# warnings.simplefilter('error')
woa = cdm.open(os.path.join(
    workDir, 'obs_data/WOD18/190501_1210_WOD18_masks_0p25deg.nc'))
s = woa('basinmask')
woaGrid = s.getGrid()  # Get WOA target grid
woaLat = s.getLatitude()
woaLon = s.getLongitude()
woa.close()
# var0p25 = var.regrid(woaGrid, regridTool='ESMF', regridMethod='linear')
# print('s:\n', var.shape)
# print('s025:\n', var0p25.shape)

# Create 0p5 grid
woaLat0p5 = woaLat.getData()[0::2]  # Extract every second lon
woaLon0p5 = woaLon.getData()[0::2]
# woaGrid0p5 = cdm.grid.createGenericGrid(woaLat0p5, woaLon0p5, latBounds=None, lonBounds=None, order='yx', mask=None) ## Returns a 0.5 but off set grid
# -89.875, -89.375, -88.875, -88.375, -87.875, -87.375, -86.875,
# sos05 = sos.regrid(woaGrid0p5,regridTool='ESMF',regridMethod='linear')
# createUniformGrid(startLat, nlat, deltaLat, startLon, nlon, deltaLon, order='yx', mask=None)
woaGrid0p5Uniform = cdm.grid.createUniformGrid(
    lat[0], 359, .5, lon[0], 719, .5, order='yx', mask=None)  # Returns a 0.5 grid
# -89.5, -89. , -88.5, -88. , -87.5, -87. , -86.5, -86. , -85.5,
var0p5Uniform = var.regrid(
    woaGrid0p5Uniform, regridTool='ESMF', regridMethod='linear')

# %% Check if diff
if diff == 'diff':
    inPath = os.path.join(workDir, '210128_PaperPlots_Rothigetal/')
    histFile = histFile
    varName = histFile.split('_')[2]
    fHist = cdm.open(os.path.join(inPath, histFile))
    sosHist = fHist(varName)
    sosHist0p5Uniform = sosHist.regrid(
        woaGrid0p5Uniform, regridTool='ESMF', regridMethod='linear')
    var0p5Uniform = var0p5Uniform - sosHist0p5Uniform
    outfile = outfile.replace('_mean.txt', '_diff.txt')
    print('outfile:', outfile)
    print('computing diff..')

# %% write global data
# 1deg data
# Flip upside down (N is on bottom, will be on top once flipped)
var = np.flip(var, axis=0)
# writeGridAscii(sos, outfile.replace('.txt', '-1p0deg.txt'))
# 0p5deg data
var0p5 = np.flip(var0p5Uniform, axis=0)
writeGridAscii(var0p5, outfile.replace('.txt', '-0p5deg.txt'))

# %% Create dictionary for regions
regions = {}
regions['Palau'] = {}
regions['Palau']['latBounds'] = [-8.25, 19.25]
regions['Palau']['lonBounds'] = [119.75, 145.25]
regions['MarshallIslands'] = {}
regions['MarshallIslands']['latBounds'] = [-16.25, 37.25]  # [16, 37]
regions['MarshallIslands']['lonBounds'] = [138.75, 192.25]  # [139, 192]
regions['Plankton-NAtl'] = {}
regions['Plankton-NAtl']['latBounds'] = [-0.25, 79.75]  # [0.00033, 79.2233]
regions['Plankton-NAtl']['lonBounds'] = [278.25, 352.75]  # [-80, -7]
regions['Plankton-SAtl'] = {}
regions['Plankton-SAtl']['latBounds'] = [-62.25, -2.75]  # [-62.2231, -1.9002]
regions['Plankton-SAtl']['lonBounds'] = [308.25, 348.75]  # [-50, 11]
regions['Seagrass-Aust'] = {}
regions['Seagrass-Aust']['latBounds'] = [-48.25, -6.75]
regions['Seagrass-Aust']['lonBounds'] = [110.75, 162.25]

for count, regionId in enumerate(regions.keys()):
    print('----------')
    print(count, regionId)
    print('----------')
    # get info from dictionary
    latBounds = regions[regionId]['latBounds']
    lonBounds = regions[regionId]['lonBounds']
    # regrid to 0p5 degree
    tmpDomain0p5 = cdu.region.domain(latitude=latBounds, longitude=lonBounds)
    print('lat:', var0p5Uniform.getLatitude()[
          0], var0p5Uniform.getLatitude()[-1])
    print('lon:', var0p5Uniform.getLongitude()[
          0], var0p5Uniform.getLongitude()[-1])
    # pdb.set_trace()
    tmpVar = tmpDomain0p5.select(var0p5Uniform)
    # checkout values
    print('tmpVar0p5:\n', tmpVar)
    print('tmpVar.getLat.getData:', tmpVar.getLatitude().getData())
    print('tmpVar.getLat.getBnds:', tmpVar.getLatitude().getBounds())
    # flip upside down (N is on bottom, will be on top once flipped)
    tmpVar = np.flip(tmpVar, axis=0)
    # create outfile name, write
    print('tmpSos:\n', tmpVar)
    outfile = infile.replace('.nc', '-'.join([regionId, '0p5deg.txt']))
    # Find filename (exclude path and append timeFormat)
    outFileName = outfile.split('/')[-1]
    outFileNameNew = '_'.join([timeFormat, outFileName])
    outfile = outfile.replace(outFileName, outFileNameNew)
    print('var0p5Uniform lat[1]-lat[0]:', var0p5Uniform.getLatitude().getData()
          [1]-var0p5Uniform.getLatitude().getData()[0])
    print('tmpSos0p5 lat[1]-lat[0]:', tmpVar.getLatitude().getData()
          [1]-tmpVar.getLatitude().getData()[0])
    writeGridAscii(tmpVar, outfile)

'''
# %% extract Palau data and write
# [-8.5, 19.25] ##[-7.999, 19.001] ##[-8.001, 19.001] ##[-8, 19] ##[-10, 20] ##[2, 10]
latBounds = [-8.25, 19.25]
# [120.001, 145.001] ##[120, 145] ##[120, 160] ##[130, 136]
lonBounds = [119.75, 145.25]
# 0p25
# palauDomain0p25 = cdu.region.domain(latitude=latBounds, longitude=lonBounds)
# sosPalau = palauDomain0p25.select(sos0p25)
# print('sosPalau0p25:\n', sosPalau)
# print('sosPalau.getLat.getData:', sosPalau.getLatitude().getData())
# print('sosPalau.getLat.getBnds:', sosPalau.getLatitude().getBounds())
# # And flip upside down (N is on bottom, will be on top once flipped)
# sosPalau = np.flip(sosPalau, axis=0)
# #print('sosPalau:\n', sosPalau)
# outfile = infile.replace('.nc', '_PalauDomain-0p25deg.txt')
# # Find filename (exclude path and append timeFormat)
# outFileName = outfile.split('/')[-1]
# outFileNameNew = '_'.join([timeFormat, outFileName])
# outfile = outfile.replace(outFileName, outFileNameNew)
# print('sos0p25 lat[1]-lat[0]:', sos0p25.getLatitude().getData()[1]-sos0p25.getLatitude().getData()[0])
# print('sosPalau0p25 lat[1]-lat[0]:', sosPalau.getLatitude().getData()[1]-sosPalau.getLatitude().getData()[0])
# writeGridAscii(sosPalau, outfile)
# 0p5
palauDomain0p5 = cdu.region.domain(latitude=latBounds, longitude=lonBounds)
sosPalau = palauDomain0p5.select(sos0p5Uniform)
# pdb.set_trace()
print('sosPalau0p5:\n', sosPalau)
print('sosPalau.getLat.getData:', sosPalau.getLatitude().getData())
print('sosPalau.getLat.getBnds:', sosPalau.getLatitude().getBounds())
# And flip upside down (N is on bottom, will be on top once flipped)
sosPalau = np.flip(sosPalau, axis=0)
print('sosPalau:\n', sosPalau)
outfile = infile.replace('.nc', '_PalauDomain-0p5deg.txt')
# Find filename (exclude path and append timeFormat)
outFileName = outfile.split('/')[-1]
outFileNameNew = '_'.join([timeFormat, outFileName])
outfile = outfile.replace(outFileName, outFileNameNew)
print('sos0p5Uniform lat[1]-lat[0]:', sos0p5Uniform.getLatitude().getData()
      [1]-sos0p5Uniform.getLatitude().getData()[0])
print('sosPalau0p5 lat[1]-lat[0]:', sosPalau.getLatitude().getData()
      [1]-sosPalau.getLatitude().getData()[0])
#writeGridAscii(sosPalau, outfile)
'''
