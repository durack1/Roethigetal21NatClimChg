#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan 28 13:00:25 2021

Paul J. Durack 28th January 2021

This script builds trend files for salinity changes

PJD 28 Jan 2021     - Started
PJD 11 Feb 2021     - Updated to add tos
PJD 24 Feb 2021     - Updated to remove 3d field (so)
PJD 24 Feb 2021     - Copied climatology/regrid code from ~git/AR6-WG1/Chap3/make_CMxWOAClims.py
PJD 25 Feb 2021     - Updated removing 3D code
PJD 26 Feb 2021     - Catch issue with experimentIdStartEndYrs not updating from list info
PJD 26 Feb 2021     - Added continue if file exists
PJD 27 Feb 2021     - Added temporal range check before var read with time bounds
PJD 24 Mar 2021     - Corrected issue with ssp534-over -> ssp534_over
PJD 24 Mar 2021     - Fixed variable name from var*_CdmsRegrid -> var
PJD 25 Mar 2021     - Redefine var before creating outfile names - test for variable stepping
PJD 26 Jul 2021     - Update for new home path
PJD 26 Jul 2021     - Appended additional historical tas to problem list CMIP6.CMIP.historical.KIOST.KIOST-ESM.r1i1p1f1.mon.tas.atmos.glb-z1-gr1.v20210601.0000000.0.xml
PJD 18 Feb 2022     - Added .ICON-ESM-LR. to badMods list
PJD 25 Feb 2022     - Added to badFiles list CMIP6.ScenarioMIP.ssp370.EC-Earth-Consortium.EC-Earth3.r3i1p1f1.mon.sos
PJD 25 Feb 2022     - Added to badFiles list CMIP6.ScenarioMIP.ssp370.EC-Earth-Consortium.EC-Earth3.r3i1p1f1.mon.tos
PJD 27 Apr 2022     - Updated /work/durack1 to /p/user_pub/climate_work/durack1
PJD 15 Mar 2023     - Update to correct durolib/wrangle imports (requires os.sys.path.insert)
                    - TO-DO: fix sos, tos rotated pole (FGOALS*, IPSL-CM6*INCA)
                    - TO-DO: fix mrro no ocean mask with sftof field (CanESM*, GISS*, E3SM*, NorESM2*, INMCM5*)
                    - TO-DO: Add badMods back in
                    - TO-DO: think about emailing when an error is raised
                    https://stackoverflow.com/questions/6182693/python-send-email-when-exception-is-raised

@author: durack1
"""
from __future__ import print_function
from socket import gethostname

# Make py2 backward compatible
import datetime
import gc
import glob
import os
import sys
import time  # ,pdb #,regrid2,

# import pdb,sys,warnings
import cdms2 as cdm
import cdtime as cdt
import cdutil as cdu

# import MV2 as mv
import numpy as np

# climlib
os.sys.path.insert(0, "/home/durack1/git/durolib/durolib")
os.sys.path.insert(0, "/home/durack1/git/climlib/climlib")
from durolib import fixVarUnits, globalAttWrite, writeToLog  # ,trimModelList
from wrangle import trimModelList

# %% Set current dirs
workDur = "/p/user_pub/climate_work/durack1"
workDir = os.path.join(workDur, "Shared/210128_PaperPlots_Rothigetal/")
xmlPath = "/p/user_pub/xclim/"
# '/data_crunchy_oceanonly/crunchy_work/cmip-dyn'

# %% Generate log file
timeNow = datetime.datetime.now()
timeFormat = timeNow.strftime("%y%m%dT%H%M%S")
dateNow = timeNow.strftime("%y%m%d")
# dateNow = '210226'
logFile = os.path.join(workDir, "_".join([timeFormat, "RothigData_log.txt"]))
textToWrite = " ".join(["TIME:", timeFormat])
writeToLog(logFile, textToWrite)
pypid = str(os.getpid())
# Returns calling python instance, so master also see os.getppid() - Parent
writeToLog(logFile, " ".join(["MASTER PID:", pypid]))
writeToLog(logFile, " ".join(["UV-CDAT:", sys.executable]))
host_name = gethostname()
print(" ".join(["HOSTNAME:", host_name]))
writeToLog(logFile, " ".join(["HOSTNAME:", host_name]))
print("----------")
writeToLog(logFile, "----------")

# %% Preallocate lists and fill
fileLists = []
mipEra = "CMIP6"
actExpPair = {}
actExpPair["CMIP"] = {}
actExpPair["CMIP"] = ["historical"]
actExpPair["ScenarioMIP"] = {}
actExpPair["ScenarioMIP"] = [
    "ssp119",
    "ssp126",
    "ssp245",
    "ssp370",
    "ssp434",
    "ssp460",
    "ssp534-over",
    "ssp585",
]
activityId = ["CMIP", "ScenarioMIP"]
variableId = {}
variableId["ocean"] = {}
variableId["ocean"] = ["sos", "tos"]  # so 535, sos 546 210224
variableId["land"] = {}
variableId["land"] = ["mrro"]  # mrro 518, mrros 468
variableId["atmos"] = {}
variableId["atmos"] = ["tas"]
frequency = "mon"

for key in actExpPair.keys():
    activityId = key
    for count1, experimentId in enumerate(actExpPair[activityId]):
        print("mip:", mipEra, "actId:", activityId, "expId:", experimentId)
        for realm in variableId.keys():
            for count2, var in enumerate(variableId[realm]):
                print(
                    "mip:",
                    mipEra,
                    "actId:",
                    activityId,
                    "expId:",
                    experimentId,
                    "realm:",
                    realm,
                    "var:",
                    var,
                )
                searchPath = os.path.join(
                    xmlPath,
                    mipEra,
                    activityId,
                    experimentId,
                    realm,
                    frequency,
                    var,
                    "*.xml",
                )
                print("searchPath:", searchPath)
                writeToLog(logFile, " ".join(["searchPath:", searchPath]))
                fileList = glob.glob(searchPath)
                fileList.sort()
                print(var, " len(fileList):     ", len(fileList))
                writeToLog(
                    logFile, "".join(
                        [var, " len(fileList):     ", str(len(fileList))])
                )
                badFiles = [
                    "/p/user_pub/xclim/CMIP6/CMIP/historical/atmos/mon/tas/CMIP6.CMIP.historical.KIOST.KIOST-ESM.r1i1p1f1.mon.tas.atmos.glb-z1-gr1.v20191106.0000000.0.xml",
                    "/p/user_pub/xclim/CMIP6/ScenarioMIP/ssp126/atmos/mon/tas/CMIP6.ScenarioMIP.ssp126.KIOST.KIOST-ESM.r1i1p1f1.mon.tas.atmos.glb-z1-gr1.v20191106.0000000.0.xml",
                    "/p/user_pub/xclim/CMIP6/ScenarioMIP/ssp245/atmos/mon/tas/CMIP6.ScenarioMIP.ssp245.KIOST.KIOST-ESM.r1i1p1f1.mon.tas.atmos.glb-z1-gr1.v20191106.0000000.0.xml",
                    "/p/user_pub/xclim/CMIP6/ScenarioMIP/ssp585/atmos/mon/tas/CMIP6.ScenarioMIP.ssp585.KIOST.KIOST-ESM.r1i1p1f1.mon.tas.atmos.glb-z1-gr1.v20191106.0000000.0.xml",
                    "/p/user_pub/xclim/CMIP6/CMIP/historical/atmos/mon/tas/CMIP6.CMIP.historical.KIOST.KIOST-ESM.r1i1p1f1.mon.tas.atmos.glb-z1-gr1.v20210601.0000000.0.xml",
                    "/p/user_pub/xclim/CMIP6/ScenarioMIP/ssp370/ocean/mon/sos/CMIP6.ScenarioMIP.ssp370.EC-Earth-Consortium.EC-Earth3.r3i1p1f1.mon.sos.ocean.glb-2d-gn.v20210517.0000000.0.xml",
                    "/p/user_pub/xclim/CMIP6/ScenarioMIP/ssp370/ocean/mon/tos/CMIP6.ScenarioMIP.ssp370.EC-Earth-Consortium.EC-Earth3.r3i1p1f1.mon.tos.ocean.glb-2d-gn.v20210517.0000000.0.xml",
                ]
                for bad in badFiles:
                    # print(bad)
                    fileList = list(filter((bad).__ne__, fileList))
                fileListTrim = trimModelList(
                    fileList, criteria=["tpoints", "cdate", "ver"]
                )  # , verbose=True); #, 'publish');
                print(var, " len(fileListTrim): ", len(fileListTrim))
                writeToLog(
                    logFile,
                    "".join([var, " len(fileListTrim): ",
                            str(len(fileListTrim))]),
                )
                print("_".join([mipEra, experimentId, var]))
                writeToLog(logFile, "_".join([mipEra, experimentId, var]))
                if "ssp534-over" in experimentId:
                    experimentId_ = experimentId.replace("-", "_")
                    print(
                        "experimentId:", experimentId, " - to _ fixed ", experimentId_
                    )
                else:
                    experimentId_ = experimentId
                varName = "_".join([mipEra, experimentId_, var])
                vars()[varName] = fileListTrim
                fileLists.extend([varName])
                del (searchPath, fileList, fileListTrim, varName, var)
                gc.collect()

# Sort fileLists
fileLists.sort()

# %% Now deal with lists - generate timeseries/trends
print("Variables scanned")
print("dir():", dir())
# print('locals():',locals())

# %% Preload WOA18 grids
# warnings.simplefilter('error')
woa = cdm.open(os.path.join(
    workDur, "Shared/obs_data/WOD18/190312/woa18_decav_s00_01.nc"))
s = woa("s_oa")
print("Start read wod18")
print("type(s):", type(s))
s = s[(0,)]
print("End read wod18")
woaLvls = s.getLevel()
woaGrid = s.getGrid()
# Get WOA target grid
woaLat = s.getLatitude()
woaLon = s.getLongitude()
woa.close()

# %% Declare file lists of problem data or unuseable grids
badMods = [
    ".AWI-CM-1-1-MR.",
    ".AWI-ESM-1-1-LR.",
    ".BCC-CSM2-MR.",
    ".BCC-ESM1.",
    ".CMCC.CMCC-CM2-HR4.",
    ".CNRM-CM6-1-HR.",
    ".ICON-ESM-LR.",
    ".IITM-ESM.",
    ".bcc-csm1-1-m.",
    ".bcc-csm1-1.",
    "CMIP6.CMIP.historical.NCAR.CESM2-WACCM-FV2.r3i1p1f1.mon.mrro.",
    "CMIP6.ScenarioMIP.ssp126.CAS.FGOALS-g3.r4i1p1f1.mon.sos.",
    "CMIP6.ScenarioMIP.ssp245.CNRM-CERFACS.CNRM-CM6-1.r10i1p1f2.mon.mrro",
    "CMIP6.ScenarioMIP.ssp245.CNRM-CERFACS.CNRM-CM6-1.r7i1p1f2.mon.mrro.",
    "CMIP6.ScenarioMIP.ssp245.CNRM-CERFACS.CNRM-CM6-1.r8i1p1f2.mon.mrro.",
    "HadGEM3-GC31-MM",
]
bigMods = {
    "HadGEM3-GC31-MM": (1980, 75, 1205, 1440),
    ".CMCC.CMCC-CM2-HR4.": (1980, 50, 1051, 1442),
}

# %% Now generate climatologies
# First loop over lists
for count1, listy in enumerate(fileLists):
    print(count1, listy)
    if "ssp" in listy:
        times = [2071, 2101]
        startYrCt = cdt.comptime(2071, 1, 1)
        endYrCt = cdt.comptime(2101, 1, 1)
    elif "historical" in listy:
        times = [1985, 2015]
        startYrCt = cdt.comptime(1985, 1, 1)
        endYrCt = cdt.comptime(2015, 1, 1)
    else:
        print("Experiment unmatched, times undefined")
        sys.exit()
    print(listy)
    listVar = eval(listy)  # Convert to generic list name
    startYr = startYrCt.year
    endYr = endYrCt.year
    print(listy)
    if "ssp534_over" in listy:
        experimentId = "-".join(listy.split("_")[1:3])  # Deal with _ vs -
    else:
        experimentId = listy.split("_")[1]
    experimentIdStartEndYrs = "-".join([experimentId,
                                       str(startYr), str(endYr)])
    print("experimentIdStartEndYrs:", experimentIdStartEndYrs)
    # continue

    # Once a list is defined loop over listed models
    for count2, filePath in enumerate(listVar):
        # Add AWI, BCC kludge - have to fix grid issue - *** TypeError: 'NoneType' object is not subscriptable
        if any(x in filePath for x in badMods):
            strTxt = " ".join(
                [
                    str(count2),
                    "** Known grid issue with:",
                    filePath.split("/")[-1],
                    "skipping..**",
                ]
            )
            print(strTxt)
            writeToLog(logFile, strTxt)
            continue
        print(count2, filePath)

        # Create outfile name and test for existence
        var = filePath.split("/")[-2]
        modId = ".".join(
            [
                ".".join(filePath.split("/")[-1].split(".")[:-3]),
                "-".join([str(startYr), str(endYr - 1), "clim"]),
                "nc",
            ]
        )
        outFMod = os.path.join(
            workDir, "ncs", dateNow, mipEra, experimentIdStartEndYrs, var, "modGrid"
        )
        outFModId = os.path.join(outFMod, modId)
        woaId = ".".join(
            [
                ".".join(filePath.split("/")[-1].split(".")[:-3]),
                "-".join([str(startYr), str(endYr - 1), "woaClim"]),
                "nc",
            ]
        )
        outFWoa = os.path.join(
            workDir, "ncs", dateNow, mipEra, experimentIdStartEndYrs, var, "woaGrid"
        )
        outFWoaId = os.path.join(outFWoa, woaId)
        if os.path.exists(outFModId):
            print("** File exists.. continue loop **")
            writeToLog(logFile, " ".join(["File exists:", outFModId]))
            continue

        startTime = time.time()
        fH = cdm.open(filePath)

        # Test valid dates
        dH = fH[var]
        timeCheck = dH.getTime()
        startYrChk = timeCheck.asComponentTime()[0].year
        endYrChk = timeCheck.asComponentTime()[-1].year

        # Deal with case of piControl
        if experimentId == "piControl":
            startYr = endYrChk - int(
                endYrCt.year
            )  # Take climatological period from last year
            endYr = endYrChk + 1  # Pad so last year is included fully
            print("piControl, startYr:", startYr, "endYr:", endYr)

        print("startYr:", startYr, type(startYr),
              "endYr:  ", endYr, type(endYr))
        # Generate climatological period (now provided as args)
        startYrCt = cdt.comptime(startYr)
        endYrCt = cdt.comptime(endYr)

        # Test time coverage
        if (endYrChk < endYrCt.year - 1) or (startYrChk > startYrCt.year):
            # Skip file and go to next, note 2006-1 to give 2005 coverage
            reportStr = "".join(
                [
                    "*****\n",
                    filePath.split("/")[-1],
                    " does not cover temporal range; target: ",
                    str(endYrCt.year - 1),
                    " vs file: ",
                    str(endYrChk),
                    " skipping to next file..\n",
                    "*****",
                ]
            )
            print(reportStr)
            writeToLog(logFile, reportStr)
            continue

        # Load data from file
        d1 = fH(var, time=(startYrCt, endYrCt, "con"))
        # print('dH.max:',dH.max())
        # print('dH.min:',dH.min())
        # print('dH loaded')
        # pdb.set_trace()
        print("dH shape:", dH.shape)
        writeToLog(logFile, " ".join(["dH shape:", str(dH.shape)]))
        # Specify levels for per-level read/write
        levs = dH.getLevel()

        # Add test for 0-valued arrays
        if d1.max == 0.0 and d1.min == 0.0:
            # Skip file and go to next, note 2006-1 to give 2005 coverage
            reportStr = "".join(
                [
                    "*****\n",
                    filePath.split("/")[-1],
                    " has zero-valued arrays,",
                    " skipping to next file..\n",
                    "*****",
                ]
            )
            print(reportStr)
            writeToLog(logFile, reportStr)
            continue
        # Validate variable axes
        # for i in range(len(d1.shape)):
        #    ax = d1.getAxis(i)
        #    print(ax.id,len(ax))
        # pdb.set_trace()
        d1, varFixed = fixVarUnits(d1, var, report=True, logFile=logFile)
        # print('d1.max():',d1.max().max().max(),'d1.min():',d1.min().min().min()) ; Moved below for direct comparison
        # print('d1 loaded')
        # pdb.set_trace()
        times = d1.getTime()
        print("starts :", times.asComponentTime()[0])
        print("ends   :", times.asComponentTime()[-1])
        print("Time:", datetime.datetime.now().strftime("%H%M%S"), "cdu start")
        climLvl = cdu.YEAR.climatology(d1)
        # print('climLvl created')
        # pdb.set_trace()
        print("Time:", datetime.datetime.now().strftime("%H%M%S"), "cdu end")
        clim = climLvl
        # pdb.set_trace()
        climInterp = climLvl.regrid(
            woaGrid, regridTool="ESMF", regridMethod="linear")
        # climInterp = climLvl.regrid(woaGrid,regridTool='ESMF',regridMethod='conservative') ; # Chat to Pete 191127
        # print('climInterp created')
        precision = 8.3
        # Updated to deal with Kelvin 300.xx
        d1Max = np.max(d1)  # d1.max().max().max()
        d1Mean = np.mean(d1.data)  # 1 #np.mean(d1) #np.mean(d1.data)
        d1Median = np.median(d1.data)  # 1 #np.median(d1) #np.median(d1.data)
        d1Min = np.min(d1)  # 1.min().min().min()
        d1Str = "".join(
            [
                "d1.max()".ljust(16),
                ":",
                "{:{}f}".format(d1Max, precision),
                " mean:",
                "{:{}f}".format(d1Mean, precision),
                " median:",
                "{:{}f}".format(
                    d1Median, precision
                ),  # This method is oblivious to the mask/missing values
                " min:",
                "{:{}f}".format(d1Min, precision),
            ]
        )
        print(d1Str)
        writeToLog(logFile, d1Str)
        climInterpMax = np.max(climInterp)  # climInterp.max().max().max()
        climInterpMean = np.mean(climInterp.data)
        climInterpMedian = np.median(climInterp.data)
        climInterpMin = np.min(climInterp)  # climInterp.min().min().min()
        climInterpStr = "".join(
            [
                "climInterp.max()".ljust(16),
                ":",
                "{:{}f}".format(climInterpMax, precision),
                " mean:",
                "{:{}f}".format(climInterpMean, precision),
                " median:",
                "{:{}f}".format(climInterpMedian, precision),
                " min:",
                "{:{}f}".format(climInterpMin, precision),
            ]
        )
        print(climInterpStr)
        writeToLog(logFile, climInterpStr)
        del (d1, climLvl)
        gc.collect()

        # Regrid vertically
        """
        pr = regrid2.pressure.PressureRegridder(levs,woaLvls)
        #climInterp2 = pr(climInterp)
        #climInterp2 = pr.rgrd(climInterp,None,None) ; # This interpolation is currently not missing data aware
        climInterp2 = pr.rgrd(climInterp,climInterp.missing,'equal') ; # By default output missing value will be missingValueIn
        # rgrd(dataIn,missingValueIn,missingMatch,logYes='yes',positionIn=None,missingValueOut=None)
        # https://github.com/CDAT/cdms/blob/master/regrid2/Lib/pressure.py#L150-L222
        #pdb.set_trace()
        climInterp2Max = np.max(climInterp2)
        climInterp2Mean = np.mean(climInterp2)
        climInterp2Median = np.median(climInterp2)
        climInterp2Min = np.min(climInterp2)
        climInterp2Str = ''.join(['climInterp2.max():',
                                  '{:{}f}'.format(climInterp2Max,precision),
                                  ' mean:','{:{}f}'.format(climInterp2Mean,precision),
                                  ' median:','{:{}f}'.format(climInterp2Median,precision),
                                  ' min:','{:{}f}'.format(climInterp2Min,precision)])
        print(climInterp2Str)
        writeToLog(logFile,climInterp2Str)
        #print('climInterp2 created')
        #pdb.set_trace()
        # Mask invalid datapoints
        climInterp3 = mv.masked_where(mv.equal(climInterp2,1e+20),climInterp2)
        climInterp3 = mv.masked_where(mv.greater(climInterp3,1e+10),climInterp3) ; # Add great to catch fringe values, switched from 1e+20 to 1e+10
        print('climInterp3.missing:',climInterp3.missing)
        #climInterp3.setMissing(1e+20) ; # Specifically assign missing value
        #print('climInterp3 created')
        #pdb.set_trace()
        """
        """
        import matplotlib.pyplot as plt
        #climSlice = clim[0,0,:,:] ; plt.figure(1) ; plt.contourf(clim.getLongitude().data,clim.getLatitude().data,climSlice,20) ; #clim
        climSlice = clim[0,:,:] ; plt.figure(1) ; plt.contourf(clim.getLongitude().data,clim.getLatitude().data,climSlice,20) ; #clim
        plt.show()
        #climInterpSlice = climInterp[0,0,:,:] ; plt.figure(2) ; plt.contourf(climInterp.getLongitude().getData(),climInterp.getLatitude().getData(),climInterpSlice,20) ; #climInterp
        climInterpSlice = climInterp[0,:,:] ; plt.figure(2) ; plt.contourf(climInterp.getLongitude().getData(),climInterp.getLatitude().getData(),climInterpSlice,20) ; #climInterp
        plt.show()
        #climInterp2Slice = climInterp2[0,0,:,:] ; plt.figure(3) ; plt.contourf(climInterp.getLongitude().getData(),climInterp.getLatitude().getData(),climInterp2Slice,20) ; #climInterp2
        #plt.show()
        climInterp3Slice = climInterp3[0,0,:,:] ; plt.figure(4) ; plt.contourf(climInterp.getLongitude().getData(),climInterp.getLatitude().getData(),climInterp3Slice,20) ; #climInterp3
        plt.show()
        """
        """
        #climInterp3 = mv.masked_where(mv.greater(climInterp2,100),climInterp2) ; # Fudge for deep BNU fields
        climInterp3.id = "".join([var,'_mean_WOAGrid'])
        climInterp3Max = np.max(climInterp3)
        climInterp3Mean = np.mean(climInterp3)
        #climInterp3Median = np.median(climInterp3)
        climInterp3Median = np.median(climInterp3.data) ; # Fix for MIROC-ES2L.historical.r1i1p1f2.so.gn.v20190823 (184)
        climInterp3Min = np.min(climInterp3)
        climInterp3Str = ''.join(['climInterp3.max():',
                                  '{:{}f}'.format(climInterp3Max,precision),
                                  ' mean:','{:{}f}'.format(climInterp3Mean,precision),
                                  ' median:','{:{}f}'.format(climInterp3Median,precision),
                                  ' min:','{:{}f}'.format(climInterp3Min,precision)])
        print(climInterp3Str)
        writeToLog(logFile,climInterp3Str)
        """

        # Redress WOA grid
        # pdb.set_trace()
        print("climInterp.shape:", climInterp.shape)
        # timeAx = cdm.createAxis(np.mean([startYrCt.absvalue,endYrCt.absvalue]),[startYrCt,endYrCt],id='time')
        # TypeError: len() of unsized object
        startYrCtYear = startYrCt.year
        startYrCtMonth = startYrCt.month
        startYrCtDay = startYrCt.day
        # pdb.set_trace()
        calStr = " ".join(
            [
                "days since",
                "-".join([str(startYrCtYear),
                         str(startYrCtMonth), str(startYrCtDay)]),
            ]
        )
        timeMean = np.mean([startYrCt.torel(calStr).value,
                           endYrCt.torel(calStr).value])
        # timeMean = cdt.relativetime(timeMean,calStr)
        timeBounds = np.array(
            [startYrCt.torel(calStr).value, endYrCt.torel(calStr).value]
        )
        timeAx = cdm.createAxis((timeMean,), bounds=timeBounds, id="time")
        timeAx.units = calStr
        # Assign units to ndarray type NOT reltime type
        # print(timeAx)
        # pdb.set_trace()
        climInterp.setAxis(0, timeAx)
        # climInterp.setAxis(1,woaLvls)
        climInterp.setAxis(1, woaLat)
        climInterp.setAxis(2, woaLon)
        # Fix variable name - var_CdmsRegrid -> var
        climInterp.name = var
        climInterp.id = var

        # Write out data
        # Check file exists
        if os.path.exists(outFModId):
            print("** File exists.. removing **")
            os.remove(outFModId)
        if not os.path.exists(outFMod):
            os.makedirs(outFMod)
        # Print outfile to screen and logfile
        outFModIdStr = " ".join(["outFModId:", outFModId])
        print(outFModIdStr)
        writeToLog(logFile, outFModIdStr)
        # Open file to write
        modIdH = cdm.open(outFModId, "w")
        # Copy across global attributes from source file - do this first, then write again so new info overwrites
        for i, key in enumerate(fH.attributes.keys()):
            setattr(modIdH, key, fH.attributes.get(key))
        del (i, key)
        gc.collect()
        globalAttWrite(modIdH, options=None)
        modIdH.climStart = str(times.asComponentTime()[0])
        modIdH.climEnd = str(times.asComponentTime()[-1])
        modIdH.write(clim.astype("float32"))
        modIdH.close()
        # Check file exists
        if os.path.exists(outFWoaId):
            print("** File exists.. removing **")
            os.remove(outFWoaId)
        if not os.path.exists(outFWoa):
            os.makedirs(outFWoa)
        woaIdH = cdm.open(outFWoaId, "w")
        # Copy across global attributes from source file - do this first, then write again so new info overwrites
        for i, key in enumerate(fH.attributes.keys()):
            setattr(woaIdH, key, fH.attributes.get(key))
        del (i, key)
        gc.collect()
        globalAttWrite(woaIdH, options=None)
        woaIdH.climStart = str(times.asComponentTime()[0])
        woaIdH.climEnd = str(times.asComponentTime()[-1])
        woaIdH.write(climInterp.astype("float32"))
        woaIdH.close()
        fH.close()

        # print('end data read')
        endTime = time.time()
        print("Time taken (secs):", "{:.2f}".format(endTime - startTime))
        writeToLog(
            logFile,
            " ".join(
                ["Time taken (secs):", "{:.2f}".format(endTime - startTime)]),
        )
        print("----------")
        writeToLog(logFile, "----------")
