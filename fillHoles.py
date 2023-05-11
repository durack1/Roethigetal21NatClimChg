#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr 19 10:03:51 2023

PJD 11 May 2023     - Add patches to identify seagrass beds

@author: durack1
"""

# %% imports
# import argparse
# import cdms2 as cdm
# import cdutil as cdu
# import xcdat as xcd
# import pathlib
# import pdb
import sys
import xarray as xr
import os
import datetime
from xcdat import open_dataset
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
np.set_printoptions(threshold=sys.maxsize)

# %% Create time string
timeNow = datetime.datetime.now()
timeFormat = timeNow.strftime("%y%m%dT%H%M%S")
print("timeFormat:", timeFormat)
homePath = "/home/durack1/git/Roethigetal21NatClimChg/"
os.chdir(homePath)

# %% function definition


def plotIt(da):
    fig, ax = plt.subplots(figsize=(9, 6), dpi=300)
    plt.axis("off")
    ax = plt.axes(projection=ccrs.PlateCarree())
    ax.coastlines()
    gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,
                      linewidth=2, color='gray', alpha=0.5, linestyle='--')
    lons = tmpVar.longitude
    lats = tmpVar.latitude
    plt.contourf(lons, lats, a, 60,
                 transform=ccrs.PlateCarree())
    plt.show()
    time.sleep(1)
    plt.close()


def fillHoles1(x, maxNloops=-1):
    # Tcl-NAP function in python
    n = x.size
    nPresent = 0  # ensure at least one loop
    nloops = 0
    while nPresent < n and nloops != maxNloops:
        #ip = (x != 0)  # Is present? (0 = missing, 1 = present)
        ip = x.isnull()  # Is present? (True = missing, False = present)
        nPresent = np.sum(ip)
        if nPresent == 0:
            raise ValueError("fillHoles1: All elements are missing")
        elif nPresent < n:
            x = np.where(ip, x, movingAverage(x, 3, -1))
        nloops += 1
        plotIt(x)
        print("nloops:", nloops)
        time.sleep(1)
    
    return x


def fillHoles2(x, maxNloops=-1):
    # Tcl-NAP function in python
    # https://github.com/durack1/Tcl-NAP/blob/master/library/nap_function_lib.tcl#L328-L356
    # http://tcl-nap.cvs.sourceforge.net/viewvc/tcl-nap/tcl-nap/library/nap_function_lib.tcl?revision=1.56&view=markup
    # http://tcl-nap.cvs.sourceforge.net/viewvc/tcl-nap/tcl-nap/library/stat.tcl?revision=1.29&view=markup
    # http://stackoverflow.com/questions/5551286/filling-gaps-in-a-numpy-array
    # http://stackoverflow.com/questions/3662361/fill-in-missing-values-with-nearest-neighbour-in-python-numpy-masked-arrays
    # https://www.google.com/search?q=python+nearest+neighbor+fill
    # https://stackoverflow.com/questions/12612663/counting-of-adjacent-cells-in-a-numpy-array
    # https://numpy.org/doc/stable/reference/generated/numpy.convolve.html
    """
    Replace missing values by estimates based on means of neighbours.

    Parameters:
        x (numpy.ndarray): array to be filled
        maxNloops (int): maximum number of iterations (default is to keep going until
            there are no missing values)

    Returns:
        numpy.ndarray: array with missing values filled
    """
    n = x.size
    nPresent = 0  # ensure at least one loop
    nLoops = 0
    while nPresent < n and (maxNloops == -1 or nLoops != maxNloops):
        #ip = (x != 0).astype(int)  # Is present? (0 = missing, 1 = present)
        ip = x.isnull()  # Is present? (True = missing, False = present)
        nPresent = np.sum(ip)
        if nPresent == 0:
            raise ValueError("fillHoles2: All elements are missing")
        elif nPresent < n:
            x = np.where(ip, x, np.convolve(x, np.ones(3)/3, mode='same'))
        nLoops += 1
        plotIt(x)
        print("nloops:", nLoops)
        time.sleep(1)

    return x


def findToFill(matrix):  # add argument allowing window-size to be set
    # find missing values adjacent to valid values
    mask = np.isnan(matrix)

    return mask


def movingAverage(x, shapeWindow, step=1):
    # Tcl-NAP function in python
    # https://github.com/durack1/Tcl-NAP/blob/master/library/stat.tcl#L231-L317
    """
    Move window of specified shape by specified step (can vary for each dimension).
    Result is arithmetic mean of values in each window.

    'shape_window' is either a scalar or a vector with an element for each dimension.
    If it is a scalar then it is treated as a vector with rank(x) identical elements.

    Similarly, 'step' is either a scalar or a vector with an element for each dimension.
    If it is a scalar then it is treated as a vector with rank(x) identical elements.
    The value -1 is treated like 1, except that missing values are prepended & appended
    (along this dimension of x) to produce a result with the same dimension size as x.

    x can have any rank > 0.
    """
    r = x.ndim
    if r < 1:
        raise ValueError("movingAverage: x is scalar")
    #unit = x.unit
    w = np.reshape(shapeWindow, (r,))
    s = np.reshape(step, (r,))
    expand = 0
    cv_list = []
    for d in range(r):
        if x.coord_vars[d] is None:
            cv_list.append(None)
        else:
            old_cv = x.coord_vars[d]
            old_cv.set_coo()  # Ensure no coord. var. to prevent infinite recursion
            cv_d = movingAverage(old_cv, w[d], s[d])
            cv_list.append(cv_d)
        if s[d] == -1:
            expand = 1
            n = x.shape[d] - 1
            i_d = np.arange(w[d] // 2, n + 1, s[d]
                            ) // np.arange(0, n + 1) // ((w[d] - 1) // 2)
    if expand:
        i = np.ix_(*[i_d for _ in range(r)])
        x = x[i]
    s = np.abs(s)
    n = w + (x.shape - w) // s * s
    p = np.r_[1:r][::-1] + [0]  # permutation of dimensions
    c = np.where(np.isnan(x), 0, 1)  # 0 if missing, 1 if present
    px = np.cumsum(x, axis=0)  # partial sum of x
    pc = np.cumsum(c, axis=0)  # partial sum of c
    for d in range(r):
        i1_d = np.arange(w[d], n[d] + 1, s[d])
        i0_d = i1_d - w[d]
        px = np.zeros_like(px).T
        pc = np.zeros_like(pc).T
    moving_sum = np.zeros_like(px[0])
    moving_count = np.zeros_like(pc[0])
    for j in range(1 << r):
        parity = r % 2
        i = []
        for d in range(r):
            bit = (j >> d) & 1
            i_bit_d = np.arange(i0_d[d], i1_d[d])
            i.append(i_bit_d)
            parity ^= bit
        i = tuple(i)
        if parity:
            moving_sum -= px[i]
            moving_count -= pc[i]
        else:
            moving_sum += px[i]
            moving_count += pc[i]
    result = np.where(moving_count > 0, moving_sum / moving_count, np.nan)
    for d in range(r):
        if cv_list[d] is not None:
            result


# %% fillHoles test

demo = np.array([[1, 2, 3, 4, 5, 6], [7, 8, 9, 10, 11, 12], [13, 14, 15, 16, 17, 18],
                 [19, 20, 21, 22, 23, 24], [25, 26, 27, 28, 29, 30], [31, 32, 33, 34, 35, 36]], dtype=float)
# demo[y,x]
# mask out central
y = 1
while y < 5:
    for x in np.arange(1, 5):
        demo[y, x] = np.nan
    y = y+1

In[24]: a = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])

In[25]: a
Out[25]:
array([[1, 2, 3],
       [4, 5, 6],
       [7, 8, 9]])

with reference to 5:
    1 = -1, -1
    3 = -1, 1
    4 = -1, 0

indx = 1
indy = 1

searchIndex2468 = [(indy-1, indx), (indy, indx-1),
                   (indy, indx+1), (indy+1, indx)]
searchIndex1379 = [(indy-1, indx-1), (indy-1, indx+1),
                   (indy+1, indx-1), (indy+1, indx+1)]

while arrayNan.any:


https://docs.xarray.dev/en/stable/generated/xarray.DataArray.interpolate_na.html
https://wxster.com/blog/2015/12/using-two-filled-contour-plots-simultaneously-in -matplotlib
https://github.com/durack1/durolib/blob/master/durolib/durolib.py


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
#fig.savefig("_".join([timeFormat, "seagrass-Aust.png"]))

# b = tmpVar.bfill("longitude")
# ax = plt.axes(projection=ccrs.PlateCarree())
# ax.coastlines()
# lons = tmpVar.longitude
# lats = tmpVar.latitude
# plt.contourf(lons, lats, b, 60,
#             transform=ccrs.PlateCarree())
# plt.show()

# Use forward fill meridionally
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
# overplot regions - a rectangle patch
rect1 = patches.Rectangle((113, -46), 160-113, (46 - 9), linewidth=1, edgecolor='r', facecolor='none')
ax.add_patch(rect1) # Add the patch to the Axes
rect2 = patches.Rectangle((113, -44), 160-113, (44 - 9), linewidth=1, edgecolor='b', facecolor='none')
ax.add_patch(rect2) # Halophila - Add the patch to the Axes
rect3 = patches.Rectangle((114, -46), 160-114, (46 - 9), linewidth=1, edgecolor='k', facecolor='none')
ax.add_patch(rect3) # Zostera - Add the patch to the Axes
rect4 = patches.Rectangle((113, -44), 153-113, (44 - 25), linewidth=1, edgecolor='w', facecolor='none')
ax.add_patch(rect4) # Posidonia - Add the patch to the Axes
rect5 = patches.Rectangle((114, -22), 149-114, (22 - 9), linewidth=1, edgecolor='m', facecolor='none')
ax.add_patch(rect5) # Thalassia - Add the patch to the Axes
rect6 = patches.Rectangle((130, -20), 147-130, (20 - 9), linewidth=1, edgecolor='y', facecolor='none')
ax.add_patch(rect6) # Enhalus - Add the patch to the Axes

plt.show()
fig.savefig("_".join([timeFormat, "seagrass-Aust-lonInfilled.png"]))


# %% Use interpolate_na
count = 0
a = tmpVar.copy(deep=True)
while a.isnull().any():
    # fill zonally
    print("{:03d}".format(count), "#:", (np.isnan(a)).sum().data)
    b = a.interpolate_na(dim="latitude", method="nearest", limit=2)
    plotIt(b)
    # fill meridionally
    print("{:03d}".format(count), "#:", (np.isnan(b)).sum().data)
    c = b.interpolate_na(dim="longitude", method="nearest", limit=2)
    plotIt(c)
    # reset back to a
    a = c.copy(deep=True)
    count += 1
