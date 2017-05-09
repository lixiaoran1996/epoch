#!/usr/bin/env python

# Copyright (C) 2017 Alexander Blinne <A.Blinne@gsi.de>,
# Stephan Kuschel <Stephan.Kuschel@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import numpy as np
import sdf
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os
import os.path as osp
import unittest
import platform
from . import SimTest

micron = 1e-6
femto = 1e-15
c = 2.99792458e8 # m/s

# check that these correspond to input deck!

nx = 240
ny = nx//3

x_min = -12 * micron
x_max = -x_min
y_min = x_min
y_max = x_max

dt_multiplier = 0.95

lambda_l = 0.5 * micron
x0 = -12.0 * micron # m
t0 = 8 * femto # s

# derived quantities from the above
k_l = 2*np.pi/lambda_l
dx = (x_max-x_min)/nx
dy = (y_max-y_min)/ny

dt_lehe   = dt_multiplier * 1.0/np.sqrt(max(1.0/dx**2, 1.0/dy**2)) / c
dt_yee    = dt_multiplier * dx * dy / np.sqrt(dx**2+dy**2) / c
dt_pukhov = dt_multiplier * min(dx,dy)/c


def showdatafields(sdffile):
    data = sdf.read(sdffile, dict=True)
    print('Data fields present in "' + sdffile + '":')
    print(data.keys())

def plotdump(sdffile, key, ax):
    data = sdf.read(sdffile, dict=True)
    array = data[key].data
    xaxis = data[key].grid_mid.data[0]*1e6
    yaxis = data[key].grid_mid.data[1]*1e6
    im = ax.imshow(array.T, extent=[min(xaxis), max(xaxis), min(yaxis), max(yaxis)])
    im.set_clim([-1e11,1e11])
    t = data['Header']['time']
    dx = np.asscalar(data[key].grid_mid.data[0][1] - data[key].grid_mid.data[0][0])

    #dt_
    #dt = dx/c * dt_multiplier

    vg_lehe = c*(1.0 + 2.0*(1.0-c*dt_lehe/dx)*(k_l*dx/2.0)**2)
    #vg_yee  = c*(1.0 - (1.0-c*dt/dx)*(k_l*dx/2.0)**2)
    vg_yee = c*np.cos(k_l*dx/2.0)/np.sqrt(1-(c*dt_yee/dx*np.sin(k_l*dx/2.0))**2)

    x = (x0 + c*(t-t0))*1e6
    x_lehe = (x0 + vg_lehe*(t-t0))*1e6
    x_yee = (x0 + vg_yee*(t-t0))*1e6

    if x > 0:
        ax.plot([x, x], [min(yaxis), 0.9*min(yaxis)], color='k', linestyle='-', linewidth=2, alpha=0.25)
        ax.plot([x, x], [0.9*max(yaxis), max(yaxis)], color='k', linestyle='-', linewidth=2, alpha=0.25)

        ax.plot([x_lehe, x_lehe], [min(yaxis), 0.9*min(yaxis)], color='b', linestyle='-', linewidth=2, alpha=0.25)
        ax.plot([x_lehe, x_lehe], [0.9*max(yaxis), max(yaxis)], color='b', linestyle='-', linewidth=2, alpha=0.25)

        ax.plot([x_yee, x_yee], [min(yaxis), 0.9*min(yaxis)], color='r', linestyle='-', linewidth=2, alpha=0.25)
        ax.plot([x_yee, x_yee], [0.9*max(yaxis), max(yaxis)], color='r', linestyle='-', linewidth=2, alpha=0.25)

    ax.set_title('{:2.1f} fs'.format(data['Header']['time']*1e15))

def plotevolution(path, key):
    sdffiles = [osp.join(path, '{:04d}.sdf'.format(i)) for i in range(3)]

    fig, axarr = plt.subplots(1,3, figsize=(10,4))
    axarr[0].set_ylabel('y [µm]')
    for (sdffile, ax) in zip(sdffiles, np.ravel(axarr)):

        plotdump(sdffile, key, ax)
        ax.set_xlabel('x [µm]')

    if path.endswith('lehe_x'):
        dt = c * dt_lehe / dx
        title = 'Lehe'
    elif path.endswith('pukhov'):
        dt = c * dt_pukhov / dx
        title = 'Pukhov'
    elif path.endswith('yee'):
        dt = c * dt_yee / dx
        title = 'Yee'

    fig.suptitle(key+', c*dt/dx={:0.03f}'.format(dt))

    fig.tight_layout()
    fig.savefig(key.replace('/','_') + '_' + title + '.png', dpi=320)

def createplots(path):
    plotevolution(path, 'Electric Field/Ey')


class test_maxwell_solvers(SimTest):
    def __init__(self, arg):
        super(test_maxwell_solvers, self).__init__(arg)
        if platform.system() == 'Darwin':
            print('macosx backend')
            plt.switch_backend('macosx')

    def test_createplots(self):
        base = os.getcwd()

        createplots(osp.join(base, 'yee'))
        createplots(osp.join(base, 'lehe_x'))
        createplots(osp.join(base, 'pukhov'))



if __name__=='__main__':
    unittest.main()


