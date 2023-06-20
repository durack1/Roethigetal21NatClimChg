#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 29 21:45:56 2021

Generate netcdf files from mat file data

PJD 29 Mar 2021     - Started
PJD 29 Mar 2021     - First pass at data writing, minus metadata
PJD 24 Aug 2021     - Update to latest data - need to update one last time
PJD 24 Aug 2021     - Update home path
PJD 30 Aug 2021     - Update input mat file 210824T132736_210726_CMIP6.mat -> 210824T225103_210726_CMIP6.mat
PJD  6 May 2022     - Added workDir, matFile
PJD  6 May 2022     - Added multi-var [sos, tos]
PJD 10 May 2022     - Corrected output varName to var (not sos hard-coded)
PJD  4 Aug 2022     - Updated for latest data 220729/220803mat
PJD  5 Aug 2022     - Updated for corrected latest data 220804
PJD 20 Jun 2023     - Updated for latest data 230321
PJD 20 Jun 2023     - Updated ssp434 -> ssp370
PJD 20 Jun 2023     - Added mambaEnv and gitInfo as global attributes to output files
PJD 20 Jun 2023     - Updated fH.write(cdVar), np.float() ; float32 -> float; numpy 1.20.0 deprecation
PJD 20 Jun 2023     - Library amipbcs230516 (py3.10.11, numpy1.23.5) required for readMatWriteNc.py as scipy.loadmat required
                    - TO-DO: Add attribution info to files; git hash etc

@author: durack1
"""

import os
import cdms2 as cdm
import numpy as np
# import pdb
import scipy.io as sio
import sys
os.sys.path.insert(0, '/home/durack1/git/durolib/durolib')
from durolib import globalAttWrite, getGitInfo

# %%
workDir = '/p/user_pub/climate_work/durack1/Shared/'
targetDir = os.path.join(workDir, '210128_PaperPlots_Rothigetal/')
# "220803T175312_220729_CMIP6.mat"  # "220429T143503_220427_CMIP6.mat"
matFile = "230601T165519_230321_CMIP6.mat"  # "220804T215723_220729_CMIP6.mat"
infile = os.path.join(targetDir, matFile)
mat = sio.loadmat(infile)
matKeys = mat.keys()
lat = mat['t_lat']
lat = lat[:, 0]  # Strip extra array dimension through slice
lat = cdm.createAxis(np.float32(lat), id='latitude')
lon = mat['t_lon']
lon = lon[:, 0]
lon = cdm.createAxis(np.float32(lon), id='longitude')
# pdb.set_trace()

# %% Create target variable list
actExpPair = {}
actExpPair['CMIP'] = {}
actExpPair['CMIP']['exps'] = ['historical']
actExpPair['CMIP']['time'] = ['1985_2015']
actExpPair['ScenarioMIP'] = {}
actExpPair['ScenarioMIP']['exps'] = ['ssp126',  # 'ssp119', 'ssp245',
                                     'ssp370', 'ssp585']  # 'ssp434', 'ssp460', 'ssp534-over'
actExpPair['ScenarioMIP']['time'] = ['2071_2101']
activityId = ['CMIP', 'ScenarioMIP']
# vars = ['mean','modelNames']

for count1, actId in enumerate(activityId):
    exps = actExpPair[actId]['exps']
    time = actExpPair[actId]['time'][0]
    varList = ['sos', 'tos']
    for count2, exp in enumerate(exps):
        for count3, var in enumerate(varList):
            fileName = '_'.join([var, 'CMIP6', exp, time, 'mean'])
            outFile = '_'.join([infile.split(
                '/')[-1].split('.')[0].replace('_CMIP6', ''), fileName])
            print('fileName:', fileName)
            vars()[exp] = mat[fileName]
            # Create output file and write
            outFile = '.'.join([os.path.join(targetDir, outFile), 'nc'])
            print('outFile:', outFile)
            cdVar = cdm.createVariable(eval(exp), id=var)
            cdVar.setAxis(0, lat)
            cdVar.setAxis(1, lon)
            # Write variables to file
            if os.path.isfile(outFile):
                os.remove(outFile)
            fH = cdm.open(outFile, 'w')
            # Global attributes
            # Use function to write standard global atts
            globalAttWrite(fH, options=None)
            fH.mambaEnv = sys.prefix
            gitInfo = getGitInfo("./readMatWriteNc.py")
            fH.gitInfo = "; ".join(gitInfo)
            # Master variables
            # sensitive to numpy version 1.20.0 warning
            fH.write(cdVar.astype('float32'))
            fH.close()

del (count1, actId, exps, time, count2, exp)
