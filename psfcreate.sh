#!/bin/zsh
echo "------------------"
echo "PSF-create script"
echo "------------------"

#Script does the following:
# 1. Cut chosen PDB-file into segment PDBs
# 2. Runs PSFgen using an inputfile that processes the segments, while reading the CHARMM topology file and creates new PSF and PDB files

#PDB-cutting script is a bit slow unfortunately (too much I/O)
#Cutting is necessary for PSFgen (Protein Structure File Generator).
#http://www.ks.uiuc.edu/Research/namd/mailing_list/namd-l.2003-2004/0757.html


##################################
# MAIN USER DEFINITIONS HERE!
origpdbfile="cry-3000ps-diff-sf4mod.pdb"

#Defining cofactors (based on residues names). Change as needed! Format: cofactorresnames="RESNAME1 RESNAME2"
cofactorresnames="WCC SF4"

#Defining extra species present (neither protein, solvent, cofactor or ions). If nothing then keep keyword as blank. Format: extraspecies="RESNAME1 RESNAME2"
extraspecies=""

#Path to PSFGEN binary
path_to_psfgen=/home/bjornsson/QM-MM-Chemshell-scripts/psfgen

topfile="top_all36_prot.rtf"

# Hopefully no modifications needed below...
#######################################
# FILE PREP
##################################
if [ ! -f "$origpdbfile" ]; then
echo "Error: PDBfile : $origpdbfile  does not exist in directory"
exit
fi

if [ ! -f "$topfile" ]; then
echo "Error: Topologyfile : $topfile  does not exist in directory"
exit
fi


#Delete files from previous run
echo "First removing old files:"
rm -f prox.pdb ions.pdb sol.pdb
rm -f rest*.pdb
rm -f solv-*.pdb
rm -f protein-*.pdb
rm -f extraspecies.pdb cofactor.pdb
echo ""
echo "Beginning now"
date
echo ""
###################################

#######################################
# SEPARATING PROTEIN FROM REST (requires some information on residues by user)
########################################
#Keeping only ATOM lines and keeping original PDBfile unchanged
var=${origpdbfile%.*}
grep 'ATOM ' $origpdbfile > ${var}_new.pdb

pdbfile="${var}_new.pdb"

#Chain symbol is always present in column 22. Deleting if present
#Removing chain symbol if present (user needs to have changed above)
echo "Removing chain symbols first."
sed -i 's/./ /22' $pdbfile


#Grepping all protein residues, silly way
# Including common modified names also
# Saving as prox.pdb
echo "Grepping protein residues"
#This should contain all protein residues including modified ones like LSN (deprot LYS), CSD (deprot CYS), all prot forms of HIS etc.
grep -e 'HSD' -e 'HSP' -e 'HSE' -e 'LSN' -e 'CYS' -e 'PHE' -e 'CSD' -e 'THR' -e 'TRP' -e 'GLY' -e 'LYS' -e 'MET' -e 'ASP' -e 'ASN' -e 'SER' -e 'ARG' -e 'GLU' -e 'VAL' -e 'LEU' -e 'ILE' -e 'GLN' -e 'TYR' -e 'PRO' -e 'ALA' -e 'HIS' $pdbfile >prox.pdb

#Rest (non-protein) becomes rest.pdb (cofactor, ions, solvent etc.)
grep -v -e 'HSD' -e 'HSP' -e 'HSE' -e 'LSN' -e 'CYS' -e 'PHE' -e 'CSD' -e 'THR' -e 'TRP' -e 'GLY' -e 'LYS' -e 'MET' -e 'ASP' -e 'ASN' -e 'SER' -e 'ARG' -e 'GLU' -e 'VAL' -e 'LEU' -e 'ILE' -e 'GLN' -e 'TYR' -e 'PRO' -e 'ALA' -e 'HIS' $pdbfile >rest.pdb



#Checking if all protein grepped
linesprot=`grep 'ATOM ' prox.pdb | wc -l | awk '{print $1}'`
atomnumlast=`tail -1 prox.pdb | awk '{print $2}'`
if [[ $linesprot != $atomnumlast ]]
then
echo "Warning: After getting protein part of pdb, number of atoms ($linesprot) is not the same as last atom number in PDB file ($atomnumlast)"
echo "If numbering did not start from 1 (common) then this is likely OK"
echo "Could also mean that we failed to grep all protein residues"
echo
fi

#Defining cofactor (based on residues names). Change as needed!
for cofresname in $(echo $cofactorresnames)
do
grep -e "$cofresname" rest.pdb >>cofactor.pdb
sed -i "/$cofresname/d" rest.pdb
done
linescofactor=`grep 'ATOM ' cofactor.pdb | wc -l | awk '{print $1}'`
echo "Cofactor segment (cofactor.pdb) contains $linescofactor atoms"
#If special extraspecies fragments (here free imidazole groups, IMIA) are present, other than ions. Can be left as is if not present
for extra in $(echo $extraspecies)
do
grep -e $extra rest.pdb >> extraspecies.pdb
sed -i "/$extra/d" rest.pdb
done
linesextraspecies=`grep 'ATOM ' extraspecies.pdb | wc -l | awk '{print $1}'`
echo "Extraspecies segment (extraspecies.pdb) contains $linesextraspecies atoms"

echo ""
echo "protein atoms : $linesprot atoms"
echo "Done with protein grepping"
date
echo
##################################
# Probably no user changes below this point...."

###################################
# SOLVENT
##################################
echo "Grepping solvent"
grep SOL rest.pdb >>sol.pdb
sed -i "/SOL/d" rest.pdb
#grep -v SOL rest3.pdb >rest4.pdb
linessol=`grep 'ATOM ' sol.pdb | wc -l | awk '{print $1}'`
echo "Initial large solvent segment contains $linessol atoms"
#Converting SOL lines to TIP3 format
sed -i s'/OW  SOL /OH2 TIP3/g' sol.pdb
sed -i s'/HW1 SOL /H1  TIP3/g' sol.pdb
sed -i s'/HW2 SOL /H2  TIP3/g' sol.pdb

#Declaring final Ions segment
# Here just declaring ions as the rest (after cofactor, extraspecies and solvent has been accounted for)
grep 'ATOM ' rest.pdb > ions.pdb
linesion=`grep ATOM ions.pdb | wc -l | awk '{print $1}'`
#Possible chlorine renaming
sed -i s'/CL   CL/CLA  CLA/g' ions.pdb

echo "The final ion segment (ions.pdb) contains $linesion atoms (everything not previously divided into protein, cofactor, solvent and extraspecies)"
echo

####################
# Creating PSFGEN inputfile
##########################
read -r -d '' PSF << EOM
topology $topfile

set protlast UNSET
set sollast UNSET
set extraspecieslast UNSET

#ENZme
for { set p 1 } { \$p <= \$protlast } { incr p 1 } {
segment ENZ\$p {
 pdb protein-\$p.pdb
}

#sourcing list of CSD residues (list called csdres in file labelled with segment)
source csdreslist-seg\$p
for { set m 0 } { \$m < [llength \$csdres] } { incr m 1 } {
set d [lindex \$csdres \$m]
puts "Patching CYSD residue number \$d in ENZ\$p"
patch CYSD ENZ\$p:\$d
}

#LSN
#sourcing list of LSN residues (list called lsnres in file labelled with segment)
source lsnreslist-seg\$p
for { set n 0 } { \$n < [llength \$lsnres] } { incr n 1 } {
set e [lindex \$lsnres \$n]
puts "Patching LSN residue number \$e in ENZ\$p"
patch LSN ENZ\$p:\$e
}

#ASP
#sourcing list of ASP residues (list called aspres in file labelled with segment)
source aspreslist-seg\$p
for { set i 0 } { \$i < [llength \$aspres] } { incr i 1 } {
set f [lindex \$aspres \$i]
puts "Patching ASP to ASPP residue number \$f in ENZ\$p"
patch ASPP ENZ\$p:\$f
}

#GLU
#sourcing list of GLU residues (list called glures in file labelled with segment)
source glureslist-seg\$p
for { set j 0 } { \$j < [llength \$glures] } { incr j 1 } {
set g [lindex \$glures \$j]
puts "Patching GLU  to GLUP residue number \$g in ENZ\$p"
patch GLUP ENZ\$p:\$g
}

coordpdb protein-\$p.pdb ENZ\$p
}

#Extra species
for { set c 1 } { \$c <= \$extraspecieslast } { incr c 1 } {
segment EXTR\$c {
 pdb extraspecies-\$c.pdb
}
coordpdb extraspecies-\$c.pdb EXTR\$c
}

#Cofactor
segment COF {
 pdb cofactor.pdb
}
coordpdb cofactor.pdb COF

#Solvent
for { set s 1 } { \$s <= \$sollast } { incr s 1 } {
segment SOLV\$s {
auto none
 pdb solv-\$s.pdb
}
coordpdb solv-\$s.pdb SOLV\$s
}

#Ions
segment ION {
 pdb ions.pdb
}
coordpdb ions.pdb ION



#Regenerate connectivity due to patching. Not needed.
#regenerate angles dihedrals

#Adding missing coordinates if any
guesscoord

#Printing Xplor file to get atom types as a column.
writepsf x-plor cmap newxplor.psf

writepsf charmm cmap new.psf
writepdb new.pdb
EOM

#Writing inputfile to disk
echo "$PSF" > psfgen.tcl



##############
linecount=1
solfrag=1
begincut=1
prevcount=0
lastline=`wc -l sol.pdb | awk '{print $1}'`
echo "Cutting down solvent (very slow step, several min)"
while read line
do
count=`echo $line | awk '{print $5}'`
    if (( $count < $prevcount ))
    then
    #echo "Count is $count and prevcount is $prevcount"
    numcut=$((linecount - 1 ))
        #echo "linecount is $linecount"
    #echo "Now cutting from $begincut to $numcut"
    sed -n "$begincut,$numcut p " sol.pdb > solv-$solfrag.pdb
    solfrag=$((solfrag + 1 ))
    begincut=$linecount
    fi
        if [[ $linecount == $lastline ]]
        then
        #echo "Now cutting from $begincut to $linecount"
    sed -n "$begincut,$linecount p " sol.pdb > solv-$solfrag.pdb
    fi
prevcount=$count
linecount=$((linecount + 1))
done < sol.pdb

sed -i s":set sollast UNSET:set sollast $solfrag:g" psfgen.tcl

echo ""
echo "Done with Solvent"
date
echo
##############################################


####################################################
# RESIDUE CHECKS
####################################################
echo "Now checking residues"

#Fixing N-terminus in a few places
sed -i s'/ H1 / HT1/g' prox.pdb
sed -i s'/ H2 / HT2/g' prox.pdb
sed -i s'/ H3 / HT3/g' prox.pdb

#Fixing histidine naming in PDB file
#CHARMM/Chemshell programs need HSP (doubly protonated), HSD (protonated ND1), HSE (protonated NE2)
# to be named as such
# HSE if NE2, HSD if ND1, HSP if double
hisreshsd=`grep 'HD1 HIS' prox.pdb | awk '{print $5}'`
hisreshse=`grep 'HE2 HIS' prox.pdb | awk '{print $5}'`
hsplist=`grep -e 'HD1 HIS' -e 'HE2 HIS' prox.pdb | awk '{print $5}' | uniq -d`

echo "Doing HIS to HSP substitution"
# First doing HSP substitution before HSE/HSD
for x in `echo $hsplist`
do
        if (( ${#x} == 1 ))
        then
        sed -i s":HIS     $x:HSP     $x:g" prox.pdb
        elif (( ${#x} == 2 ))
        then
        sed -i s":HIS    $x:HSP    $x:g" prox.pdb
        elif (( ${#x} == 3 ))
        then
    sed -i s":HIS   $x:HSP   $x:g" prox.pdb
        elif (( ${#x} == 4 ))
        then
        sed -i s":HIS  $x:HSP  $x:g" prox.pdb
        fi
done

echo "Doing HIS to HSD and HSE subsitution"
# Substituting HSD
for x in `echo $hisreshsd`
do
    if (( ${#x} == 1 ))
    then
    sed -i s":HIS     $x:HSD     $x:g" prox.pdb
    elif (( ${#x} == 2 ))
    then
    sed -i s":HIS    $x:HSD    $x:g" prox.pdb
    elif (( ${#x} == 3 ))
    then
        sed -i s":HIS   $x:HSD   $x:g" prox.pdb
    elif (( ${#x} == 4 ))
    then
        sed -i s":HIS  $x:HSD  $x:g" prox.pdb
    fi
done

# Substituting HSE
echo "Doing HIS to HSE substitution"
for y in `echo $hisreshse`
do
        if (( ${#y} == 1 ))
        then
        sed -i s":HIS     $y:HSE     $y:g" prox.pdb
        elif (( ${#y} == 2 ))
        then
    sed -i s":HIS    $y:HSE    $y:g" prox.pdb
        elif (( ${#y} == 3 ))
        then
        sed -i s":HIS   $y:HSE   $y:g" prox.pdb
        elif (( ${#y} == 4 ))
        then
        sed -i s":HIS  $y:HSE  $y:g" prox.pdb
        fi
done

echo ""
echo "Done with HIS substitution"
echo ""

##########################################

##############################################
## PROTEIN SEGMENT SPLITTER
#############################################
linecount=0
proteinfrag=1
begincut=1
lastline=`wc -l prox.pdb | awk '{print $1}'`
echo "Now starting protein splitting:"
date

prevresid=`head -1 prox.pdb | awk '{print $5}'`
#echo "prevresid is $prevresid"
while read line
do
atomnum=`echo $line | awk '{print $2}'`
type=`echo $line | awk '{print $3}'`
res=`echo $line | awk '{print $4}'`
#echo "res is $res"
count=`echo $line | awk '{print $5}'`
#echo "count is $count and res is $res and type is $type and atomnum is $atomnum . Linecount is $linecount"
#echo "prevresid is $prevresid"
prevresidplus=$((prevresid + 1))
#echo "prevresidplus is $prevresidplus"
        if (( $count == $prevresid ))
        then
        :
        #echo "Normal: same residue!"
        elif (( $count == $prevresidplus ))
        then
        :
        #echo "Normal: next residue"
        else
        #echo "Else."
        numcut=$linecount
        #echo "linecount is $linecount"
        #echo "Now cutting from $begincut to $numcut"
        sed -n "$begincut,$numcut p " prox.pdb > protein-$proteinfrag.pdb
        proteinfrag=$((proteinfrag + 1 ))
        begincut=$((linecount+1))
        fi
#echo "linecount is $linecount (lastline is $lastline)"
        if (( $linecount == $((lastline-1)) ))
        then
        numcut=$((linecount+1))
        #echo "Now cutting from $begincut to $linecount"
        sed -n "$begincut,$numcut p " prox.pdb > protein-$proteinfrag.pdb
        fi
prevresid=$count
linecount=$((linecount + 1))
done < prox.pdb

echo "Done with protein segment splitting"
date
echo
################################################################




################################################
# Here going through each protein segment. Finding special residues
# Preparing for patches
###############################################
echo "Checking other residues"


# Converting CSD (deprotonated CYS) back to CYS
# Will require patching by psfgen instead
# First grabbing list of CSD residues
for i in `seq 1 $proteinfrag`
do
csdres=`grep CSD protein-$i.pdb | awk '{print $5}' | uniq | sed ':a;N;$!ba;s/\n/ /g'`
echo "CSD residues for patching: $csdres"
echo "set csdres {$csdres}" >csdreslist-seg$i
sed -i s'/CSD/CYS/g' protein-$i.pdb

#LSN. Deprotonated lysines
#This finds if no HZ3 atom exists on lysine
lsnres=`grep -A1 'HZ2 LYS' protein-$i.pdb | grep C | awk '{print $5}'`
echo "LSN residues for patching: $lsnres"
echo "set lsnres {$lsnres}" >lsnreslist-seg$i

#Findin protonated GLU
glures=`grep 'HE2 GLU' protein-$i.pdb | awk '{print $5}'`
echo "GLU residues for patching: $glures"
echo "set glures {$glures}" >glureslist-seg$i

#Findin protonated ASP
aspres=`grep 'HD2 ASP' protein-$i.pdb | awk '{print $5}'`
echo "ASP residues for patching: $aspres"
echo "set aspres {$aspres}" >aspreslist-seg$i
done


sed -i s":set protlast UNSET:set protlast $proteinfrag:g" psfgen.tcl



#Going through extraspecies segment.
if (( $linesextraspecies > 0 ))
then
  linecount=1
  extraspeciesfrag=1
  begincut=1
  prevcount=0
  lastline=`wc -l extraspecies.pdb | awk '{print $1}'`

  while read line
  do
  count=`echo $line | awk '{print $5}'`
        if (( $count < $prevcount ))
        then
          #echo "Count is $count and prevcount is $prevcount"
          numcut=$((linecount - 1 ))
          #echo "linecount is $linecount"
          #echo "Now cutting from $begincut to $numcut"
          sed -n "$begincut,$numcut p " extraspecies.pdb > extraspecies-$extraspeciesfrag.pdb
          extraspeciesfrag=$((extraspeciesfrag + 1 ))
          begincut=$linecount
        fi
        if [[ $linecount == $lastline ]]
        then
          #echo "Now cutting from $begincut to $linecount"
          sed -n "$begincut,$linecount p " extraspecie.pdb > extraspecies-$extraspeciesfrag.pdb
        fi
  prevcount=$count
  linecount=$((linecount + 1))
  done < extraspecies.pdb
sed -i s":set extraspecieslast UNSET:set extraspecieslast $extraspeciesfrag:g" psfgen.tcl
else
sed -i s":set extraspecieslast UNSET:set extraspecieslast 0:g" psfgen.tcl
fi


echo ""
echo "Now done with cutting down steps!"
#################################################################


#######################################
# Now checking if everything adds up
#######################################
echo "linescofactor is $linescofactor"
echo "linesextraspecies is $linesextraspecies"
echo "linesion is $linesion"
echo "linessol is $linessol"
echo "linesprot is $linesprot"
sumtotlines=$((linescofactor + linesextraspecies + linesion + linessol + linesprot ))
echo "After cutting down PDB file, sum of all atoms is  $sumtotlines"

#all ATOM lines in original file
allatoms=`grep -n 'ATOM ' $pdbfile | wc -l | awk '{print $1}'`
echo "Original PDB files had $allatoms ATOM entries"
if [[ $allatoms != $sumtotlines ]]
then
echo "After cutting down system to various segments, number of atoms do not match"
echo "Check carefully why."
exit
fi
date

##########################################
# RUNNING PSFGEN NOW UNLESS PROBLEMS
###########################################
echo ""
echo "If everything checks out then PSFgen will be run now."
echo "Note that system atom number may change after patching"
echo "Note that PSFgen requires all residues be present in topology file"

#Now running PSFGen with inputfile
$path_to_psfgen psfgen.tcl

#Check if number of atoms is correct in PSF-created files
numatoms_psf=$(grep '!NAT' new.psf | awk '{print $1}')

if [[ $allatoms != $numatoms_psf ]]
then
echo "Problem: Number of atoms in PSFgen-made PSF/PDB files does not match number in original PDB-file"
echo "Please check PSFgen output above for error messages (e.g. duplicate RESID errors)"
else
echo "All done. Everything checks out"
fi
echo ""
echo "WARNING: PSFGEN CAN REORDER THE SYSTEM."
echo "MAKE SURE TO USE the NEWLY CREATED FILES:"
echo "new PSF-file:   newxplor.psf"
echo "new PDB-file:   new.pdb"
