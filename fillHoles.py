#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr 19 10:03:51 2023

@author: durack1
"""

# %% imports
# import argparse
# import cdms2 as cdm
# import cdutil as cdu
# import xcdat as xcd
# import numpy as np
# import pathlib
# import pdb
# import sys
import os
import datetime
from xcdat import open_dataset
import cartopy.crs as ccrs
import matplotlib.pyplot as plt

# %% Create time string
timeNow = datetime.datetime.now()
timeFormat = timeNow.strftime("%y%m%dT%H%M%S")
print("timeFormat:", timeFormat)
homePath = "/home/durack1/git/Roethigetal21NatClimChg/"
os.chdir(homePath)

# %% function definition


def fillHoles(matrix):
    pass


# %% load data
f = "/p/user_pub/climate_work/durack1/Shared/210128_PaperPlots_Rothigetal/220804T215723_220729_sos_CMIP6_historical_1985_2015_mean.nc"
ds = open_dataset(f)
latBounds = [-48.25, -6.75]
lonBounds = [105.75, 162.25]
tmpVar = ds.sos.sel(latitude=slice(
    latBounds[0], latBounds[1]), longitude=slice(lonBounds[0], lonBounds[1]))

# austDomain = cdu.region.domain(latitude=latBounds, longitude=lonBounds)
# tmpVar = austDomain.select(sos)

# https://scitools.org.uk/cartopy/docs/v0.15/matplotlib/intro.html
fig, ax = plt.subplots(figsize=(9, 6), dpi=300)
plt.axis("off")
ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()
gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                  linewidth=2, color='gray', alpha=0.5, linestyle='--')
lons = tmpVar.longitude
lats = tmpVar.latitude
plt.contourf(lons, lats, tmpVar, 60,
             transform=ccrs.PlateCarree())
plt.show()
fig.savefig("_".join([timeFormat, "seagrass-Aust.png"]))

# b = tmpVar.bfill("longitude")
# ax = plt.axes(projection=ccrs.PlateCarree())
# ax.coastlines()
# lons = tmpVar.longitude
# lats = tmpVar.latitude
# plt.contourf(lons, lats, b, 60,
#             transform=ccrs.PlateCarree())
# plt.show()

f = tmpVar.ffill("longitude")  # , limit=2) # forward fill left to right
fig, ax = plt.subplots(figsize=(9, 6), dpi=300)
plt.axis("off")
ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()
gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                  linewidth=2, color='gray', alpha=0.5, linestyle='--')
lons = tmpVar.longitude
lats = tmpVar.latitude
plt.contourf(lons, lats, f, 60,
             transform=ccrs.PlateCarree())
plt.show()
fig.savefig("_".join([timeFormat, "seagrass-Aust-lonInfilled.png"]))
