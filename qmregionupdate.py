#!/usr/bin/env python3

# qmregionupdate. 17 June 2015 version for use with Chemshell QM/MM
# To be used after qmedit script has been used to create qmregioncoords.xyz and after coordinate modification.
# Requires fragname as input and requires qmatoms and qmregioncoords.xyz files to exist



import sys
import os
import re

# Read in filename as argument
try:
    filename=sys.argv[1]
except IndexError:
    print("Script usage: qmregionupdate.py fragmentfile.c. Also requires files: qmatoms and qmregioncoords.xyz")
    quit()
try:
    os.remove('file-mod.c')
except OSError:
    pass
fragfile = open('file-mod.c', 'a')

# Read updated coordinates from qmregioncoords.xyz

elem=['H', 'He', 'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne', 'Na', 'Mg', 'Al', 'Si', 'P', 'S', 'Cl', 'Ar', 'K', 'Ca', 'Sc', 'Ti', 'V', 'Cr', 'Mn', 'Fe', 'Co', 'Ni', 'Cu', 'Zn', 'Ga', 'Ge', 'As', 'Se', 'Br', 'Kr', 'Rb', 'Sr', 'Y', 'Zr', 'Nb', 'Mo', 'Tc', 'Ru', 'Rh', 'Pd', 'Ag', 'Cd', 'In', 'Sn', 'Sb', 'Te', 'I', 'Xe', 'Cs', 'Ba', 'La', 'Ce', 'Pr', 'Nd', 'Pm', 'Sm', 'Eu', 'Gd', 'Tb', 'Dy', 'Ho', 'Er', 'Tm', 'Yb', 'Lu', 'Hf', 'Ta', 'W', 'Re', 'Os', 'Ir', 'Pt', 'Au', 'Hg', 'Tl', 'Pb', 'Bi', 'Po', 'At', 'Rn', 'Fr', 'Ra', 'Ac', 'Th', 'Pa', 'U', 'Np', 'Pu', 'Am', 'Cm', 'Bk', 'Cf', 'Es', 'Fm', 'Md', 'No', 'Lr']
coords=[]

#Think about whether skipping 2 lines is always appropriate
s=1
try:
    with open('qmregioncoords.xyz') as qmcor:
        stuff = qmcor.readlines()[2:]
        # To get rid of newlines
        qmcoords = list(line for line in (l.strip() for l in stuff) if line)
except OSError:
    print("No file qmregioncoords.xyz. Run qmedit.sh first.")
    quit()

#Assuming first we are using atom numbers (checked below)
atomnum="yes"
for d in qmcoords:
# Check if atomnumber is integer.
    try:
        val = int(d.split()[0])
    except ValueError:
        atomnum="no"
    # If we are dealing with atom numbers then change to element symbols
    if atomnum == "yes" :
        x=int(d.split()[0])
        x=x-1
        el=elem[x]
    else:
        el=d.split()[0]
    a=d.split()[1]
    b=d.split()[2]
    c=d.split()[3]
    string = el + " " + a + " " + b  + " " + c
    coords.append(string)

#Read qmatoms into qmatoms list
qmatoms=[]
try:
    with open('qmatoms') as qm:
        for i in qm:
            b=i.replace("set qmatoms {","")
            b=b.replace("}","")
            b=b.replace("\n","")
            test=b.split(' ')
            for b in test:
                qmatoms.append(int(b))
except OSError:
    print("No qmatoms file. Run regiondefine script first.")
    quit()

#Readin and writing fragfile to new file. Modifying lines belonging to QM region.
with open(filename) as fp:
    for i, line in enumerate(fp):
        c=i-3
        if c in qmatoms:
            index=qmatoms.index(c)
            fragfile.write(coords[index])
            fragfile.write("\n")
        else:
            fragfile.write(line)

#Closing files
fragfile.close()
fp.close()
qm.close()
qmcor.close()

# Renaming modified fragfile to original file
#os.system('mv file-mod.c filename')
os.rename('file-mod.c', filename)
