#!/usr/bin/env python3

#Animate Frequencies from Chemshell Force job (not DL-FIND freq job)

#Setting whether to print out full system (full), Active Region (act) or QM region only (qm)
printsetting='qm'


import numpy as np
import sys

bohrang=0.529177249
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

try:
    fragfile=sys.argv[1]
    outfile=sys.argv[2]
    modenumber=sys.argv[3]
except IndexError:
    print(bcolors.OKGREEN,"Script usage: animate-freq.py fragfile outfile modenumber", bcolors.ENDC)
    print("")
    print(bcolors.OKBLUE,"fragfile is Chemshell fragmentfile, outfile is Chemshell-outputfile, modenumber is integer")
    print(bcolors.WARNING,"Example: ./animate-freq.py system.c E2-muHFe6-2-S7H-s3-2-f235-opH.out 13", bcolors.ENDC)
    quit()


def isint(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

if printsetting=='qm':
    #Get QMatoms from qmatoms file
    with open("qmatoms") as qfile:
        bla=qfile.read()
        qmatoms=[int(i) for i in bla.partition('{')[-1].rpartition('}')[0].split()]
        subsetatoms=qmatoms
elif printsetting=='act':
    #Get ActiveAtoms from act file
    with open("act") as afile:
        bla2=afile.read()
        actatoms=[int(i) for i in bla2.partition('{')[-1].rpartition('}')[0].split()]
        subsetatoms=actatoms

# Get Cartesian coordinates from Chemshell fragment file
count=0
coords=[]
#R coordinates in Bohr
R=[]
Rcoords=[]
symb=[]
elems=[]
grabatoms=False
with open(fragfile) as ffile:
    for line in ffile:
        ll=line.split()
        if 'block' in line and grabatoms==True:
            grabatoms=False
        if grabatoms==True:
            symb.append(ll[0]);symb.append(ll[0]);symb.append(ll[0])
            elems.append(ll[0])
            coords.append(ll)
            coor=[float(i) for i in ll[1:4]]
            Rcoords.append(coor)
        if 'block = coordinates records =' in line:
            numatoms=int(line.split()[-1])
            grabatoms=True


forcejob=False
grabforceatoms=False
grabnormalmodes=False
forceatoms=[]
forceatoms_el=[]
modelinecount=0
modegrab=False
modechosen=[]
with open(outfile) as ofile:
    for line in ofile:
        if 'force/' in line:
            grabforceatoms=False
        if grabforceatoms==True:
            if len(line.split()) == 6:
                forceatom=int(line.split()[0])
                forceatoms.append(forceatom)
                forceatoms_el.append(line.split()[1])
                diffe=float(coords[forceatom-1][1]) - float(line.split()[3])
                if abs(diffe) >0.001  :
                    print("Mismatch between coordinates in outfile and fragmentfile. Are we sure the files are correct ??????")
        if 'normal modes and vibrational frequencies' in line:
            grabnormalmodes=True

        if  modegrab==True:
            if 'x' in line or 'y' in line or 'z' in line:
                modechosen.append(float(line.split()[modeposfromend]))

        if grabnormalmodes==True:
            modelinecount+=1
            modeline=line.split()
            for word in modeline:
                if modenumber == word:
                    modelist=[int(i) for i in line.split()]
                    modeposfromend=int(modeline.index(modenumber))-len(modelist)
                    modegrab=True


            if 'principal second moments of inertia' in line:
                grabnormalmodes=False
                modegrab=False

        if 'Force Constant Calculation' in line:
            forcejob=True
        if 'Input Coordinates' in line:
            grabforceatoms=True
        if 'normal modes and vibrational frequencies' in line:
            grabnormalmodes=True

if forcejob!=True:
    print("Not a Chemshell Force Constant job! Check outputfile!")
    exit()

#print("forceatoms is", forceatoms)
#print("modechosen is", modechosen)

#Creating dictionary of displace atoms and chosen mode coordinates
modedict = {}
for fo in range(0,len(forceatoms)):
    modedict[forceatoms[fo]] = [modechosen.pop(0),modechosen.pop(0),modechosen.pop(0)]


####################################
f = open('Mode'+str(modenumber)+'.xyz','w')
#Displacement array
dx = np.array([0.0,-0.1,-0.2,-0.3,-0.4,-0.5,-0.6,-0.7,-0.8,-0.9,-1.0,-0.9,-0.8,-0.7,-0.6,-0.5,-0.4,-0.3,-0.2,-0.1,0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,0.9,0.8,0.7,0.6,0.4,0.3,0.2,0.1,0.0])
dim=len(modechosen)


for k in range(0,len(dx)):
    if printsetting=='qm':
        f.write('%i\n\n' % len(subsetatoms))
    elif printsetting=='act':
        f.write('%i\n\n' % len(subsetatoms))
    for j,w in zip(range(0,numatoms),Rcoords):
        if j+1 in forceatoms:
            f.write('%s %12.8f %12.8f %12.8f  \n' % (elems[j], bohrang*(dx[k]*modedict[j+1][0]+w[0]), bohrang*(dx[k]*modedict[j+1][1]+w[1]), bohrang*(dx[k]*modedict[j+1][2]+w[2])))
        elif j+1 in subsetatoms:
            f.write('%s %12.8f %12.8f %12.8f  \n' % (elems[j], bohrang*w[0], bohrang*w[1], bohrang*w[2]))
f.close()
print("All done. File Mode%s.xyz has been created!" % (modenumber))
