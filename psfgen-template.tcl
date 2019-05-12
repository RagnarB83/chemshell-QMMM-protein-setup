#topology /data/users/rbjorns/chemshell-gromacs/nitrogenase-charmm36-model/test1/chemshell/top_all36_prot.rtf
topology top_all36_prot.rtf 

set protlast UNSET
set sollast UNSET
set extraspecieslast UNSET

#ENZme
for { set p 1 } { $p <= $protlast } { incr p 1 } {
segment ENZ$p {
 pdb protein-$p.pdb
}


puts "Now processing protein segment $p"
#PATCHES BELOW NO LONGER NECESSARY DUE TO SEGMENT SPLITTING
#####
#Patches for ENZ here
#Other N or C patches here
#Here Arg:242 which is a sole residue
#Also MET path that is cut at N-end
#if { $p >= 3 } { 

#patch CTER ENZ$p:242
#patch NTER ENZ$p:242
#patch NTER ENZ$p:320


#Proper ones

#patch CTER ENZ$p:326

#patch NTER ENZ$p:342
#patch CTER ENZ$p:369


#458NTER
#patch CTER ENZ$p:469

#patch NTER ENZ$p:410
#patch CTER ENZ$p:419

#patch NTER ENZ$p:437
#patch CTER ENZ$p:444

# special patches for GLY N-termini. Regular does not work
#patch GLYP ENZ$p:378
#patch CTER ENZ$p:392

#patch GLYP ENZ$p:486
#Last 523

#}

#sourcing list of CSD residues (list called csdres in file labelled with segment)
source csdreslist-seg$p
for { set m 0 } { $m < [llength $csdres] } { incr m 1 } {
set d [lindex $csdres $m]
puts "Patching CYSD residue number $d in ENZ$p"
patch CYSD ENZ$p:$d
}

#LSN
#sourcing list of LSN residues (list called lsnres in file labelled with segment)
source lsnreslist-seg$p
for { set n 0 } { $n < [llength $lsnres] } { incr n 1 } {
set e [lindex $lsnres $n]
puts "Patching LSN residue number $e in ENZ$p"
patch LSN ENZ$p:$e
}

#ASP
#sourcing list of ASP residues (list called aspres in file labelled with segment)
source aspreslist-seg$p
for { set i 0 } { $i < [llength $aspres] } { incr i 1 } {
set f [lindex $aspres $i]
puts "Patching ASP to ASPP residue number $f in ENZ$p"
patch ASPP ENZ$p:$f
}

#GLU
#sourcing list of GLU residues (list called glures in file labelled with segment)
source glureslist-seg$p
for { set j 0 } { $j < [llength $glures] } { incr j 1 } {
set g [lindex $glures $j]
puts "Patching GLU  to GLUP residue number $g in ENZ$p"
patch GLUP ENZ$p:$g
}

coordpdb protein-$p.pdb ENZ$p
}

#Extra species
for { set c 1 } { $c <= $extraspecieslast } { incr c 1 } {
segment EXTR$c {
 pdb extraspecies-$c.pdb
}
coordpdb extraspecies-$c.pdb EXTR$c
}

#Cofactor
segment COF {
 pdb cofactor.pdb
}
coordpdb cofactor.pdb COF

#Solvent
for { set s 1 } { $s <= $sollast } { incr s 1 } {
segment SOLV$s {
auto none
 pdb solv-$s.pdb
}
coordpdb solv-$s.pdb SOLV$s
}

#Ions
segment ION {
 pdb ions.pdb
}
coordpdb ions.pdb ION



#Regenete connectivity due to patching
#Not needed I don't think
#regenerate angles dihedrals

#Adding missing coordinates if any
guesscoord


#Printing Xplor file to get atom types as a column. Used in python script
writepsf x-plor cmap newxplor.psf

writepsf charmm cmap new.psf
writepdb new.pdb
