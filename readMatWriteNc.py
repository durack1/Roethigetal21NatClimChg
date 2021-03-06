#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 29 21:45:56 2021

Generate netcdf files from mat file data

PJD 29 Mar 2021     - Started
PJD 29 Mar 2021     - First pass at data writing, minus metadata
                    - TO-DO: Add attribution info to files; git hash etc

@author: durack1
"""

import os #, pdb
import cdms2 as cdm
import numpy as np
import scipy.io as sio
os.sys.path.insert(0,'/export/durack1/git/durolib/durolib')
from durolib import globalAttWrite

#%%
targetDir = '/work/durack1/Shared/210128_PaperPlots_Rothigetal/'
infile = os.path.join(targetDir,'210328T000410_210325_CMIP6.mat')
mat = sio.loadmat(infile)
matKeys = mat.keys()
lat = mat['t_lat']
lat = lat[:,0] # Strip extra array dimension through slice
lat = cdm.createAxis(np.float32(lat),id='latitude')
lon = mat['t_lon']
lon = lon[:,0]
lon = cdm.createAxis(np.float32(lon),id='longitude')

#%% Create target variable list
actExpPair = {}
actExpPair['CMIP'] = {}
actExpPair['CMIP']['exps'] = ['historical']
actExpPair['CMIP']['time'] = ['1985_2015']
actExpPair['ScenarioMIP'] = {}
actExpPair['ScenarioMIP']['exps'] = ['ssp119','ssp126','ssp245','ssp370','ssp434','ssp460','ssp585'] #,'ssp534-over'
actExpPair['ScenarioMIP']['time'] =['2071_2101']
activityId = ['CMIP', 'ScenarioMIP']
#vars = ['mean','modelNames']

for count1,actId in enumerate(activityId):
    exps = actExpPair[actId]['exps']
    time = actExpPair[actId]['time'][0]
    for count2,exp in enumerate(exps):
        fileName = '_'.join(['sos','CMIP6',exp,time,'mean'])
        print('fileName:',fileName)
        vars()[exp] = mat[fileName]
        # Create output file and write
        outFile = '.'.join([os.path.join(targetDir,fileName),'nc'])
        print('outFile:',outFile)
        cdVar = cdm.createVariable(eval(exp),id='sos')
        cdVar.setAxis(0,lat)
        cdVar.setAxis(1,lon)
        # Write variables to file
        if os.path.isfile(outFile):
            os.remove(outFile)
        fH = cdm.open(outFile,'w')
        # Global attributes
        globalAttWrite(fH,options=None) ; # Use function to write standard global atts
        # Master variables
        fH.write(cdVar.astype('float32'))
        fH.close()

del(count1,actId,exps,time,count2,exp)