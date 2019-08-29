#!/bin/env python3

#This listprep bersion takes PSF-file (Xplor formatted) as argument and creates all lists from it.
import sys
import os
import re
from decimal import *


psffile=sys.argv[1]

getcontext().prec=6

#Opening input and output
#Remove old outputfile
try:
    os.remove('save-new.chm')
except OSError:
    pass
tcgfile = open('save-new.chm', 'a')


def isWhole(x):
        if(x%1 == 0):
                return True
        else:
                return False


#Here getting atom types from XPLOR file (printed in there but not regular PSF file)
atomtypes=[]
bla=[]
charges=[]
resid=[]
segnames=[]
atomlist=[]
with open(psffile) as gh:
    for line in gh:
        if re.search('!NATOM', line):
            numatoms=int(line.split()[0])
            for i in range(numatoms):
                temp=next(gh)
                temp=temp.rstrip('\n')
                xatomtypes=temp.split()[5]
                atomtypes.append(xatomtypes)
                xcharges=temp.split()[6]
                xresid=temp.split()[2]
                xsegnames=temp.split()[1]
                xatomlist=temp.split()[0]
                charges.append(xcharges)
                resid.append(xresid)
                segnames.append(xsegnames)
                atomlist.append(xatomlist)

#with open('new.psf') as fh:
#    for line in fh:
#        if re.search('!NATOM', line):
#            numatoms=int(line.split()[0])
#            for i in range(numatoms):
#                temp=next(fh)
#                temp=temp.rstrip('\n')
#                xcharges=temp.split()[6]
#                xresid=temp.split()[2]
#                xsegnames=temp.split()[1]
#                xatomlist=temp.split()[0]
#                charges.append(xcharges)
#                resid.append(xresid)
#                segnames.append(xsegnames)
#                atomlist.append(xatomlist)


#print(atomlist)
print("resid atomlist is:", len(atomlist))
print("resid length is:", len(resid))
print("segnames length is:", len(segnames))

#Going through resid list and stripping out duplicate values
#Also creating bsegnames list of same size
prev=94354354
bresid=[]
bsegnames=[]
count=0
counter=1
n=1
atombeg=atomlist[0]
atomsinres=[]
reslistatoms=[]
for j in resid:
    #print("j is:", j)
    #print("count is:", count)
    #print("counter is:", counter)
    j=int(j)
    # Atomlist for each residue
    if (j != prev and prev != 94354354):
        #print("Atomsinres is:", atomsinres)
        reslistatoms.append(atomsinres)
        atomsinres=[]
    atomsinres.append(atomlist[count])
    #Creating bresid and bsegnames
    if j != prev:
        j=int(j)
        bresid.append(j)
        bsegnames.append(segnames[count])
        prev=j
    #Making sure the last atoms for last residue gets printed
    if counter == len(resid):
        #print("Atomsinres is:", atomsinres)
        reslistatoms.append(atomsinres)
    count=count+1
    counter=counter+1

#Charge groups
#Using Decimal here so that floats add up to whole numbers
sum=Decimal(0)
count=0
groups=[]
templist=[]
#Grabbing and printing out
tcgfile.write("set groups {")
for i in charges:
    count=count+1
    templist.extend([count])
    stemplist=count
    #print("Curr sum is ", sum)
    #print("Charge is:", i)
    i=Decimal(i)
    sum=sum + i
    if isWhole(sum) == True:
        #print("Sum is", sum)
        tcgfile.write("{")
        for item in templist:
            tcgfile.write("%s " % item)
        tcgfile.write("} ")
        templist=[]
        sum=0

tcgfile.write("}\n")

# Summing up charge
fsum=Decimal(0)
for b in charges:
    #print("NewCharge is:", b)
    #print("NewCharge in Decimal is:", Decimal(b))
    #print("Curr sum is ", fsum)
    b=Decimal(b)
    fsum=fsum + b
print("Total charge of system is", fsum)


# Printing out charges
tcgfile.write("set charges {")
for item in charges:
    tcgfile.write("%s " % item)

#Ending tcl list
tcgfile.write("}\n")




#Printing pdbresidues list
tcgfile.write("set pdbresidues {{")

beginres=int(resid[0])
residlength=len(resid)-1
endres=int(resid[residlength])+1

#print("Length of segnames:", len(segnames))
#print("Length of bresid:", len(bresid))
#print(segnames)

#Printing out resids
count=0
for x in bresid:
    x=int(x)
    bseg=bsegnames[count]
    #print(bseg)
    tcgfile.write(bseg)
    tcgfile.write("-%s " % x)
    count=count+1
tcgfile.write("} ")
tcgfile.write("{")
for item in reslistatoms:
    tcgfile.write("{")
    tcgfile.write( " ".join(item))
    tcgfile.write("} ")
tcgfile.write("}}\n")

#Printing out special pdbresidues (without segnames)
tcgfile.write("set residuegroups {")
count=0
for item in reslistatoms:
    tcgfile.write("{")
    tcgfile.write( " ".join(item))
    tcgfile.write("} ")
tcgfile.write("}\n")



#Printing out atom types
tcgfile.write("set types {")
for item in atomtypes:
    tcgfile.write("%s " % item)
tcgfile.write("}")
