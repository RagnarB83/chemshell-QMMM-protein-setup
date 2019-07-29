#!/bin/sh
# qmedit. 12 June 2015 version for use with Chemshell QM/MM

if [[ "$1" == "" ]]
then
echo "qmedit script."
echo " Usage: qmedit filename.c  (where filename.c is a Chemshell fragment file)."
echo "Script requires qmatoms file to be present in folder. Contains list of all qmatoms numbers"
exit
fi

file=$1
if [ -f $file ]
then
:
else
echo "There is no file $file"
exit
fi
if [ -f "qmatoms" ]
then
:
else
echo "There is no file qmatoms in folder. This is required."
echo "You can run 'chemshell.bash regiondefine.chm $1' to create it (or copy old one)."
exit
fi

rm -f qmregioncoords.xyz

qmatoms=$(cat qmatoms | sed 's/set qmatoms {//g' | sed 's/}//g')
numatom=$(echo $qmatoms | wc -w | cut -d' ' -f1)
file=$1

echo $numatom>qmregioncoords.xyz
echo "QM region coordinates (Bohrs) from $file.">>qmregioncoords.xyz
for i in $(echo $qmatoms)
do
m=$((i+4))
sed -n ''$m''p  $file  >>qmregioncoords.xyz
done
echo "Created qmregioncoords.xyz using qmatoms file and $file"
