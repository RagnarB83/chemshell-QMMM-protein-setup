#
# Reader for AMBER  prmtop and inpcrd files \$Revision: 3097 
# 
# Current status - 
#
# %FLAG TITLE                         skipped
# %FLAG POINTERS                      ok
# %FLAG ATOM_NAME                     loaded but not usd
# %FLAG CHARGE                        ok
# %FLAG MASS                          loaded but not usd
# %FLAG ATOM_TYPE_INDEX               ok
# %FLAG NUMBER_EXCLUDED_ATOMS         ok
# %FLAG NONBONDED_PARM_INDEX          ok
# %FLAG RESIDUE_LABEL                 loaded but not used
# %FLAG RESIDUE_POINTER               loaded but not used
# %FLAG BOND_FORCE_CONSTANT           ok
# %FLAG BOND_EQUIL_VALUE              ok
# %FLAG ANGLE_FORCE_CONSTANT          ok
# %FLAG ANGLE_EQUIL_VALUE             ok
# %FLAG DIHEDRAL_FORCE_CONSTANT       ok - see below  
# %FLAG DIHEDRAL_PERIODICITY          ok
# %FLAG DIHEDRAL_PHASE                ok
# %FLAG SOLTY                         skipped
# %FLAG LENNARD_JONES_ACOEF           ok
# %FLAG LENNARD_JONES_BCOEF           ok
# %FLAG BONDS_INC_HYDROGEN            ok 
# %FLAG BONDS_WITHOUT_HYDROGEN        ok
# %FLAG ANGLES_INC_HYDROGEN           ok
# %FLAG ANGLES_WITHOUT_HYDROGEN       ok
# %FLAG DIHEDRALS_INC_HYDROGEN        ok
# %FLAG DIHEDRALS_WITHOUT_HYDROGEN    "
# %FLAG EXCLUDED_ATOMS_LIST           !! loaded but not checked
# %FLAG HBOND_ACOEF                   need check - 
# %FLAG HBOND_BCOEF                   need check
# %FLAG HBCUT                         skipped - believed obsolete 
# %FLAG AMBER_ATOM_TYPE               used - but mapping to elements only for parm94, see amber_type_to_z
# %FLAG TREE_CHAIN_CLASSIFICATION     skipped
# %FLAG JOIN_ARRAY                    skipped
# %FLAG IROTAT                        skipped
# %FLAG SOLVENT_POINTERS              skipped
# %FLAG ATOMS_PER_MOLECULE            skipped
# %FLAG BOX_DIMENSIONS                (IFBOX = 1) read in, processed if orthogonal
# %FLAG RADIUS_SET                    skipped
# %FLAG RADII                         skipped
# %FLAG SCREEN                        skipped

# Meaning of pointer section from www

#  NATOM  : total number of atoms
#  NTYPES : total number of distinct atom types
#  NBONH  : number of bonds containing hydrogen
#  MBONA  : number of bonds not containing hydrogen
#  NTHETH : number of angles containing hydrogen
#  MTHETA : number of angles not containing hydrogen
#  NPHIH  : number of dihedrals containing hydrogen
#  MPHIA  : number of dihedrals not containing hydrogen
#  NHPARM : currently not used
#  NPARM  : currently not used
#  NEXT   : number of excluded atoms
#  NRES   : number of residues
#  NBONA  : MBONA + number of constraint bonds
#  NTHETA : MTHETA + number of constraint angles
#  NPHIA  : MPHIA + number of constraint dihedrals
#  NUMBND : number of unique bond types
#  NUMANG : number of unique angle types
#  NPTRA  : number of unique dihedral types
#  NATYP  : number of atom types in parameter file, see SOLTY below
#  NPHB   : number of distinct 10-12 hydrogen bond pair types
#  IFPERT : set to 1 if perturbation info is to be read in
#  NBPER  : number of bonds to be perturbed
#  NGPER  : number of angles to be perturbed
#  NDPER  : number of dihedrals to be perturbed
#  MBPER  : number of bonds with atoms completely in perturbed group
#  MGPER  : number of angles with atoms completely in perturbed group
#  MDPER  : number of dihedrals with atoms completely in perturbed groups
#  IFBOX  : set to 1 if standard periodic box, 2 when truncated octahedral
#  NMXRS  : number of atoms in the largest residue
#  IFCAP  : set to 1 if the CAP option from edit was specified

proc prmtop_skip_to { fp field } {
    set more 1
    while {$more} {
	set code [ gets $fp line ]
	#puts stdout $line
	if { $code  < 0 } { chemerror "prmtop field $field not found" }
	if { [ string index $line 0 ] == "%" } {
	    #puts stdout HIT1
	    if { [ string index $line 2 ] == "L" } {
		#puts stdout HIT2
		set line "$line                     "
		if { [ string range $line 6 20 ] == "$field" }  { 
		    #puts stdout HIT3
		    set more 0 
		} else {
		    #puts stdout  "X [ string range $line 6 20 ] X $field"
		}
	    }
	}
    }
}

proc red3 { val } {
    if { $val < 0 } { 
	set val  [ expr abs($val) ]
	set fac -1
    } else {
	set fac 1
    }
    return [ expr $fac * ($val/3 + 1 ) ]
}


proc parse_prmtop { file } {

    upvar amber_prmtop amber_prmtop

    #
    # In AMBER, the parm + top entries are combined so there is actually no need
    # to load in the AMBER parameter files
    #
    # It is possible to work out the number of types of parameter and also
    # the instances of where these parameters are used
    #
    # Unlike CHARMM, the vdw parameters are already combined in the prmtop
    # file and therefor combination rules dont need to be applied here

    set inst amber1

    set fp [ open $file r ]

    # %VERSION  VERSION_STAMP = V0001.000  DATE = 08/24/05  04:08:16                  
    gets $fp line 

    if { [ string index $line 0 ] != "%" } {
	puts stdout OLD
	parse_old_prmtop $fp
	return
    }

    # %FLAG TITLE %FORMAT(20a4) ======================================================
    #                                                                   
    #                                                                                 

    # %FLAG POINTERS %FORMAT(10I8) ===================================================
    #                                                                   

    prmtop_skip_to $fp "POINTERS       "
    # skip format
    gets $fp line 

    gets $fp line
    set NATOM [ lindex $line 0 ]
    set NTYPES [lindex $line 1 ]
    set NBONH [lindex $line 2]
    set MBONA [lindex $line 3]
    set NTHETH [lindex $line 4]
    set MTHETA [lindex $line 5]
    set NPHIH [lindex $line 6]
    set MPHIA [lindex $line 7]
    set NHPARM [lindex $line 8]
    set NPARM [lindex $line 9]

    gets $fp line
    set NNB [lindex $line 0]
    set NRES [lindex $line 1]
    set NBONA [lindex $line 2]
    set NTHETA [lindex $line 3]
    set NPHIA [lindex $line 4]
    set NUMBND [lindex $line 5]
    set NUMANG [lindex $line 6]
    set NPTRA [lindex $line 7]
    set NATYP [lindex $line 8]
    set NPHB [lindex $line 9]

    gets $fp line
    set IFPERT [lindex $line 0]
    set NBPER [lindex $line 1]
    set NGPER [lindex $line 2]
    set NDPER [lindex $line 3]
    set MBPER [lindex $line 4]
    set MGPER [lindex $line 5]
    set MDPER [lindex $line 6]
    #puts "RB here. line is $line"
    set IFBOX [lindex $line 7]
    set NMXRS [lindex $line 8]
    set IFCAP [lindex $line 9]

    # save as part of the main array for later use to reduce number of global variables
    foreach var { NATOM NTYPES NBONH MBONA NTHETH MTHETA NPHIH MPHIA NHPARM NPARM NNB
	          NRES NBONA  NTHETA NPHIA  NUMBND NUMANG NPTRA  NATYP  NPHB IFPERT
	          NBPER  NGPER  NDPER  MBPER MGPER  MDPER  IFBOX  NMXRS  IFCAP } {
	set amber_prmtop($inst,$var) [ set $var ]
    }

    gets $fp line
    set NUMEXTRA [lindex $line 0]
    #set NCOP [lindex $line 1]

    # %FLAG ATOM_NAME %FORMAT(20a4) ===================================================

    prmtop_skip_to $fp "ATOM_NAME      "
    gets $fp line
    set count 20
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 19 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 4] [ expr ( $count + 1 ) * 4 - 1 ] ]
	set amber_prmtop($inst,ATOM_NAME,$i) $label
	incr count
    }

    # %FLAG CHARGE %FORMAT(5E16.8) ================================================

    prmtop_skip_to $fp "CHARGE         "
    gets $fp line
    set count 20
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	#puts stdout $label
	set amber_prmtop($inst,CHARGE,$i) [ string trim $label ]
	incr count
    }

    # %FLAG MASS %FORMAT(5E16.8) ==================================================

    prmtop_skip_to $fp "MASS           "
    gets $fp line
    set count 20
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,MASS,$i) [ string trim $label]
	incr count
    }

    # %FLAG ATOM_TYPE_INDEX %FORMAT(10I8) ============================================

    prmtop_skip_to $fp "ATOM_TYPE_INDEX"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 9} {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	set amber_prmtop($inst,TYPE_INDEX,$i) [ expr int ($label ) ]
	incr count
    }

    # %FLAG NUMBER_EXCLUDED_ATOMS %FORMAT(10I8) ===============================================

    prmtop_skip_to $fp "NUMBER_EXCLUDED"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 9} {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	set amber_prmtop($inst,N_EXCL_ATOMS,$i) [ expr int ($label ) ]
	incr count
    }

    # %FLAG NONBONDED_PARM_INDEX %FORMAT(10I8) ===================================================

    prmtop_skip_to $fp "NONBONDED_PARM_"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NTYPES } { incr i } {
	for { set j 0 } { $j < $NTYPES } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    set amber_prmtop($inst,NONB_PARM_INDEX,$i,$j) [ expr int ($label ) ]
	    incr count
	}
    }

    # %FLAG RESIDUE_LABEL %FORMAT(20a4) ===================================================

    prmtop_skip_to $fp "RESIDUE_LABEL  "
    gets $fp line
    set count 20
    for { set i 0 } { $i < $NRES } { incr i } {
	if { $count > 19 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 4] [ expr ( $count + 1 ) * 4 - 1 ] ]
	set amber_prmtop($inst,RESIDUE_LAB,$i) $label
	incr count
    }

    # %FLAG RESIDUE_POINTER %FORMAT(10I8) ===================================================

    prmtop_skip_to $fp "RESIDUE_POINTER"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NRES } { incr i } {
	if { $count > 9 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	set amber_prmtop($inst,RESIDUE_PTR,$i) [ string trim $label ]
	incr count
    }

    # %FLAG BOND_FORCE_CONSTANT %FORMAT(5E16.8) =============================================

    prmtop_skip_to $fp "BOND_FORCE_CONS"
    gets $fp line
    set count 5
    for { set i 0 } { $i < $NUMBND } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,BOND_FC,$i) [ string trim $label ]
	incr count
    }

    # %FLAG BOND_EQUIL_VALUE %FORMAT(5E16.8) ================================================

    prmtop_skip_to $fp "BOND_EQUIL_VALU"
    gets $fp line
    set count 5
    for { set i 0 } { $i < $NUMBND } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,BOND_R0,$i) [ string trim $label ]
	incr count
    }


    # %FLAG ANGLE_FORCE_CONSTANT %FORMAT(5E16.8) =============================================

    prmtop_skip_to $fp "ANGLE_FORCE_CON"
    gets $fp line
    set count 5
    for { set i 0 } { $i < $NUMANG } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,ANG_FC,$i) [ string trim $label ]
	incr count
    }

    # %FLAG ANGLE_EQUIL_VALUE %FORMAT(5E16.8)  ==============================================

    prmtop_skip_to $fp "ANGLE_EQUIL_VAL"
    gets $fp line
    set count 5
    for { set i 0 } { $i < $NUMANG } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,ANG_A0,$i) [ string trim $label ]
	incr count
    }

    # %FLAG DIHEDRAL_FORCE_CONSTANT %FORMAT(5E16.8) ========================================

    prmtop_skip_to $fp "DIHEDRAL_FORCE_"
    gets $fp line
    set count 5
    for { set i 0 } { $i < $NPTRA } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,DIHEDRAL_FC,$i) [ string trim $label]
	incr count
    }

    # %FLAG DIHEDRAL_PERIODICITY %FORMAT(5E16.8) ==========================================

    prmtop_skip_to $fp "DIHEDRAL_PERIOD"
    gets $fp line
    set count 5
    for { set i 0 } { $i < $NPTRA } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,DIHEDRAL_PERIOD,$i) [ string trim $label ]
	incr count
    }

    # %FLAG DIHEDRAL_PHASE %FORMAT(5E16.8)  ============================================

    prmtop_skip_to $fp "DIHEDRAL_PHASE "
    gets $fp line
    set count 5
    for { set i 0 } { $i < $NPTRA } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,DIHEDRAL_PHASE,$i) [ string trim $label ]
	incr count
    }

    # %FLAG SOLTY %FORMAT(5E16.8)   ===================================================

    # %FLAG LENNARD_JONES_ACOEF %FORMAT(5E16.8) =======================================

    set ntri [ expr $NTYPES*($NTYPES+1)/2 ]

    # From http://amber.scripps.edu/formats.html
    #
    #CN1    : Lennard Jones r**12 terms for all possible atom type
    #       interactions, indexed by ICO and IAC; for atom i and j
    #       where i < j, the index into this array is as follows
    #       (assuming the value of ICO(index) is positive):
    #       CN1(ICO(NTYPES*(IAC(i)-1)+IAC(j))).

    prmtop_skip_to $fp "LENNARD_JONES_A"
    gets $fp line
    set count 5
    set k 0
    for { set i 0 } { $i < $NTYPES } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    #puts stdout $label
	    set amber_prmtop($inst,LJA,$k) [ string trim $label ]
	    incr count
	    incr k
	}
    }

    # %FLAG LENNARD_JONES_BCOEF %FORMAT(5E16.8) ===========================================

    prmtop_skip_to $fp "LENNARD_JONES_B"
    gets $fp line
    set count 5
    set k 0
    for { set i 0 } { $i < $NTYPES } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    set amber_prmtop($inst,LJB,$k) [ string trim $label ]
	    incr count
	    incr k
	}
    }

    # %FLAG BONDS_INC_HYDROGEN %FORMAT(10I8) ==============================================

    prmtop_skip_to $fp "BONDS_INC_HYDRO"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NBONH } { incr i } {
	for { set j 0 } { $j < 3 } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    set tmp($j)  [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,BONDS_H,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,BONDS_H,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,BONDS_H,$i,TYPE) $tmp(2)
    }

    # %FLAG BONDS_WITHOUT_HYDROGEN %FORMAT(10I8) ===============================================

    prmtop_skip_to $fp "BONDS_WITHOUT_H"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NBONA } { incr i } {
	for { set j 0 } { $j < 3 } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,BONDS_A,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,BONDS_A,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,BONDS_A,$i,TYPE) $tmp(2)
    }

    # %FLAG ANGLES_INC_HYDROGEN %FORMAT(10I8) =================================================

    prmtop_skip_to $fp "ANGLES_INC_HYDR"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NTHETH } { incr i } {
	for { set j 0 } { $j < 4 } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,ANGLES_H,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_H,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_H,$i,K) [ expr $tmp(2)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_H,$i,TYPE) $tmp(3)
    }

    # %FLAG ANGLES_WITHOUT_HYDROGEN %FORMAT(10I8) ==============================================

    prmtop_skip_to $fp "ANGLES_WITHOUT_"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NTHETA } { incr i } {
	for { set j 0 } { $j < 4 } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,ANGLES_A,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_A,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_A,$i,K) [ expr $tmp(2)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_A,$i,TYPE) $tmp(3)
    }

    # %FLAG DIHEDRALS_INC_HYDROGEN %FORMAT(10I8) ==============================================

    prmtop_skip_to $fp "DIHEDRALS_INC_H"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NPHIH } { incr i } {
	for { set j 0 } { $j < 5 } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,DIHEDRALS_H,$i,I) [ red3 $tmp(0) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,J) [ red3 $tmp(1) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,K) [ red3 $tmp(2) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,L) [ red3 $tmp(3) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,TYPE) $tmp(4)
    }

    # %FLAG DIHEDRALS_WITHOUT_HYDROGEN %FORMAT(10I8) =======================================

    prmtop_skip_to $fp "DIHEDRALS_WITHO"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NPHIA } { incr i } {
	for { set j 0 } { $j < 5 } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,DIHEDRALS_A,$i,I) [ red3 $tmp(0) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,J) [ red3 $tmp(1) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,K) [ red3 $tmp(2) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,L) [ red3 $tmp(3) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,TYPE) $tmp(4)
    }

    # %FLAG EXCLUDED_ATOMS_LIST %FORMAT(10I8) =============================================
    #                                                                   
    # NATEX  : the excluded atom list.  To get the excluded list for atom
    # "i" you need to traverse the NUMEX list, adding up all
    # the previous NUMEX values, since NUMEX(i) holds the number
    # of excluded atoms for atom "i", not the index into the 
    # NATEX list.  Let IEXCL = SUM(NUMEX(j), j=1,i-1), then
    # excluded atoms are NATEX(IEXCL) to NATEX(IEXCL+NUMEX(i)).

    prmtop_skip_to $fp "EXCLUDED_ATOMS_"
    gets $fp line
    set count 10
    for { set i 0 } { $i < $NATOM } { incr i } {
	for { set j 0 } { $j < $amber_prmtop($inst,N_EXCL_ATOMS,$i) } { incr j } {
	    if { $count > 9} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 8] [ expr ( $count + 1 ) * 8 - 1 ] ]
	    incr count
	    set amber_prmtop($inst,EXCL,$i,$j)  [ expr int ($label ) ]
	}
    }

    # %FLAG HBOND_ACOEF %FORMAT(5E16.8) ================================================

    prmtop_skip_to $fp "HBOND_ACOEF    "
    gets $fp line
    set count 5
    set k 0
    for { set i 0 } { $i < $NPHB } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    set amber_prmtop($inst,HBA,$k) $label
	    incr count
	    incr k
	}
    }

    # %FLAG HBOND_BCOEF %FORMAT(5E16.8) ==============================================

    prmtop_skip_to $fp "HBOND_BCOEF    "
    gets $fp line
    set count 5
    set k 0
    for { set i 0 } { $i < $NPHB } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    set amber_prmtop($inst,HBB,$k) [ string trim $label]
	    incr count
	    incr k
	}
    }

    # %FLAG HBCUT %FORMAT(5E16.8)  =================================================

    # no longer in use
 
    # %FLAG AMBER_ATOM_TYPE %FORMAT(20a4) ==========================================

    prmtop_skip_to $fp "AMBER_ATOM_TYPE"
    gets $fp line
    set count 20
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 19 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 4] [ expr ( $count + 1 ) * 4 - 1 ] ]
    #
    #RB
	#puts stdout $label
	set amber_prmtop($inst,AMBER_ATOM_TYPE,$i) [ string trim $label ]
	incr count
    }

    # %FLAG TREE_CHAIN_CLASSIFICATION %FORMAT(20a4) ================================

    # %FLAG JOIN_ARRAY %FORMAT(10I8) ==============================================

    # %FLAG IROTAT %FORMAT(10I8) ===================================================
    #puts "RB here2. IFBOX is $IFBOX"
    if { $IFBOX > 0 } {

      # The following are only present if IFBOX .gt. 0

      # %FLAG SOLVENT_POINTERS %FORMAT(3I8) ===========================================

      # %FLAG ATOMS_PER_MOLECULE %FORMAT(10I8) ========================================

      # %FLAG BOX_DIMENSIONS %FORMAT(5E16.8) ==========================================
      # BETA, BOX(1), BOX(2), BOX(3)

      prmtop_skip_to $fp "BOX_DIMENSIONS "
      gets $fp line
      gets $fp line
      set count 0
      for { set i 0 } { $i < 4 } { incr i } {
        set tmp($i) [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
        incr count
      }
      set amber_prmtop($inst,BETA) $tmp(0)
      set amber_prmtop($inst,BOX,1) $tmp(1)
      set amber_prmtop($inst,BOX,2) $tmp(2)
      set amber_prmtop($inst,BOX,3) $tmp(3)      

    }

    # %FLAG RADII %FORMAT(5E16.8) ===================================================

    # %FLAG SCREEN %FORMAT(5E16.8) ==================================================

    #parray amber_prmtop

}


proc load_amber_types { coords } {

    #
    # This routine loads up the amber types. Note that the integer TYPE_INDEX
    # values run over a smaller range than the number of unique AMBER_ATOM_TYPE
    # names, a number of types can share common VDW parameters.
    #
    # as far as I can tell the numerical index is only needed to code for the vdw
    # energy. Charges are stored separately and all internal coordinate based
    # terms are defined separately.
    #
    # lsearch needs exact flag as C* is an amber type
    #

    upvar amber_prmtop amber_prmtop
    set inst amber1

    set n  [ get_number_of_atoms coords=$coords ] 

    global amber_types
    global amber_charges
    global amber_code_from_type
    global amber_known_types

    set amber_types {}
    set amber_charges {}
#    set amber_code_from_type {}
    set amber_known_types {}

    push_banner_flag 0
    for { set i 0 } { $i < $n} { incr i } {

	set symbol $amber_prmtop($inst,AMBER_ATOM_TYPE,$i)
	lappend amber_types $symbol
    #puts "RB. amber_types is $amber_types"
	set chg $amber_prmtop($inst,CHARGE,$i)
	lappend amber_charges [ expr $chg / 18.2223 ]

	if { [ lsearch -exact $amber_known_types $symbol ] == -1 } { 
	    set z [ get_atom_znum coords=$coords  atom_number = [ expr $i + 1] ] 
	    param_add_type $symbol $z
	    lappend amber_known_types $symbol
	    set code $amber_prmtop($inst,TYPE_INDEX,$i) 
	    set amber_code_from_type($symbol) $code
	}
    }
    #puts "RBX amber atom types $amber_types"
    #puts stdout "DEBUG TYPE"
    #parray amber_code_from_type

    pop_banner_flag
}

proc list_amber_atom_types {} {
    global amber_types
    return  $amber_types
}

proc list_amber_atom_charges {} {
    global amber_charges
    return  $amber_charges
}


proc parse_old_prmtop { fp } {

    upvar amber_prmtop amber_prmtop

    #
    # In AMBER, the parm + top entries are combined so there is actually no need
    # to load in the AMBER parameter files
    #
    # It is possible to work out the number of types of parameter and also
    # the instances of where these parameters are used
    #
    # Unlike CHARMM, the vdw parameters are already combined in the prmtop
    # file and therefor combination rules dont need to be applied here

    set inst amber1

    #set fp [ open $file r ]

    # first line - title?
    # already read in...
    #gets $fp line 

    # pointers line, 30 numbers 12i6
    set count 12
    for { set i 0 } { $i < 31 } { incr i } {
	if { $count > 11 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	set tmp($i) [ string trim $label ]
	incr count
    }

    set NATOM $tmp(0)
    set NTYPES $tmp(1)
    set NBONH $tmp(2)
    set MBONA $tmp(3)
    set NTHETH $tmp(4)
    set MTHETA $tmp(5)
    set NPHIH $tmp(6)
    set MPHIA $tmp(7)
    set NHPARM $tmp(8)
    set NPARM $tmp(9)
    set NNB $tmp(10)
    set NRES $tmp(11)
    set NBONA $tmp(12)
    set NTHETA $tmp(13)
    set NPHIA $tmp(14)
    set NUMBND $tmp(15)
    set NUMANG $tmp(16)
    set NPTRA $tmp(17)
    set NATYP $tmp(18)
    set NPHB $tmp(19)
    set IFPERT $tmp(20)
    set NBPER $tmp(21)
    set NGPER $tmp(22)
    set NDPER $tmp(23)
    set MBPER $tmp(24)
    set MGPER $tmp(25)
    set MDPER $tmp(26)
    set IFBOX $tmp(27)
    set NMXRS $tmp(28)
    set IFCAP $tmp(29)
    set NEXTRA $tmp(30)

    # save as part of the main array for later use to reduce number of global variables
    foreach var { NATOM NTYPES NBONH MBONA NTHETH MTHETA NPHIH MPHIA NHPARM NPARM NNB
	          NRES NBONA  NTHETA NPHIA  NUMBND NUMANG NPTRA  NATYP  NPHB IFPERT
	          NBPER  NGPER  NDPER  MBPER MGPER  MDPER  IFBOX  NMXRS  IFCAP NEXTRA } {
	set amber_prmtop($inst,$var) [ set $var ]
    }

    # ATOM_NAME NATOM * 20a4
    set count 20
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 19 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 4] [ expr ( $count + 1 ) * 4 - 1 ] ]
	set amber_prmtop($inst,ATOM_NAME,$i) $label
	incr count
    }

    # CHARGE NATOM * 5E16.8
    set count 5
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	#puts stdout $label
	set amber_prmtop($inst,CHARGE,$i) [ string trim $label ]
	incr count
    }

    # MASS NATOM * 5E16.8
    set count 5
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,MASS,$i) [ string trim $label]
	incr count
    }

    # ATOM_TYPE_INDEX NATOM * 12I6
    set count 12
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 11} {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	set amber_prmtop($inst,TYPE_INDEX,$i) [ expr int ($label ) ]
	incr count
    }

    # NUMBER_EXCLUDED_ATOMS 12I6
    set count 12
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 11} {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	set amber_prmtop($inst,N_EXCL_ATOMS,$i) [ expr int ($label ) ]
	incr count
    }

    # NONBONDED_PARM_INDEX 12I6
    set count 12
    for { set i 0 } { $i < $NTYPES } { incr i } {
	for { set j 0 } { $j < $NTYPES } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    set amber_prmtop($inst,NONB_PARM_INDEX,$i,$j) [ expr int ($label ) ]
	    incr count
	}
    }

    # RESIDUE_LABEL NRES 20a4
    set count 20
    for { set i 0 } { $i < $NRES } { incr i } {
	if { $count > 19 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 4] [ expr ( $count + 1 ) * 4 - 1 ] ]
	set amber_prmtop($inst,RESIDUE_LAB,$i) $label
	incr count
    }

    # RESIDUE_POINTER 12I6
    set count 12
    for { set i 0 } { $i < $NRES } { incr i } {
	if { $count > 11 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	set amber_prmtop($inst,RESIDUE_PTR,$i) [ string trim $label ]
	incr count
    }

    # BOND_FORCE_CONSTANT 5E16.8
    set count 5
    for { set i 0 } { $i < $NUMBND } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,BOND_FC,$i) [ string trim $label ]
	incr count
    }

    # BOND_EQUIL_VALUE 5E16.8
    set count 5
    for { set i 0 } { $i < $NUMBND } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,BOND_R0,$i) [ string trim $label ]
	incr count
    }

    # ANGLE_FORCE_CONSTANT 5E16.8
    set count 5
    for { set i 0 } { $i < $NUMANG } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,ANG_FC,$i) [ string trim $label ]
	incr count
    }

    # %ANGLE_EQUIL_VALUE 5E16.8
    set count 5
    for { set i 0 } { $i < $NUMANG } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,ANG_A0,$i) [ string trim $label ]
	incr count
    }

    # DIHEDRAL_FORCE_CONSTANT 5E16.8
    set count 5
    for { set i 0 } { $i < $NPTRA } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,DIHEDRAL_FC,$i) [ string trim $label]
	incr count
    }

    # DIHEDRAL_PERIODICITY 5E16.8
    set count 5
    for { set i 0 } { $i < $NPTRA } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,DIHEDRAL_PERIOD,$i) [ string trim $label ]
	incr count
    }

    # DIHEDRAL_PHASE 5E16.8
    set count 5
    for { set i 0 } { $i < $NPTRA } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,DIHEDRAL_PHASE,$i) [ string trim $label ]
	incr count
    }

    # %FLAG SOLTY %FORMAT(5E16.8)   ===================================================
    #  in amber 7 manual, marked reserved for future use
    set count 5
    for { set i 0 } { $i < $NATYP } { incr i } {
	if { $count > 4 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	set amber_prmtop($inst,SOLTY,$i) [ string trim $label ]
	incr count
    }

    # %FLAG LENNARD_JONES_ACOEF %FORMAT(5E16.8) =======================================
    # From http://amber.scripps.edu/formats.html
    #
    #CN1    : Lennard Jones r**12 terms for all possible atom type
    #       interactions, indexed by ICO and IAC; for atom i and j
    #       where i < j, the index into this array is as follows
    #       (assuming the value of ICO(index) is positive):
    #       CN1(ICO(NTYPES*(IAC(i)-1)+IAC(j))).

    set count 5
    set k 0
    for { set i 0 } { $i < $NTYPES } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    set amber_prmtop($inst,LJA,$k) [ string trim $label ]
	    incr count
	    incr k
	}
    }

    # LENNARD_JONES_BCOEF 5E16.8 ===========================================
    set count 5
    set k 0
    for { set i 0 } { $i < $NTYPES } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    set amber_prmtop($inst,LJB,$k) [ string trim $label ]
	    incr count
	    incr k
	}
    }

    # BONDS_INC_HYDROGEN 12I6
    set count 12
    for { set i 0 } { $i < $NBONH } { incr i } {
	for { set j 0 } { $j < 3 } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    set tmp($j)  [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,BONDS_H,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,BONDS_H,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,BONDS_H,$i,TYPE) $tmp(2)
    }

    # BONDS_WITHOUT_HYDROGEN 12I6  ===============================================
    set count 12
    for { set i 0 } { $i < $NBONA } { incr i } {
	for { set j 0 } { $j < 3 } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,BONDS_A,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,BONDS_A,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,BONDS_A,$i,TYPE) $tmp(2)
    }

    # ANGLES_INC_HYDROGEN 12I6 =================================================
    set count 12
    for { set i 0 } { $i < $NTHETH } { incr i } {
	for { set j 0 } { $j < 4 } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,ANGLES_H,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_H,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_H,$i,K) [ expr $tmp(2)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_H,$i,TYPE) $tmp(3)
    }

    # ANGLES_WITHOUT_HYDROGEN 12I6 ==============================================
    set count 12
    for { set i 0 } { $i < $NTHETA } { incr i } {
	for { set j 0 } { $j < 4 } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,ANGLES_A,$i,I) [ expr $tmp(0)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_A,$i,J) [ expr $tmp(1)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_A,$i,K) [ expr $tmp(2)/3 + 1 ]
	set amber_prmtop($inst,ANGLES_A,$i,TYPE) $tmp(3)
    }

    # %FLAG DIHEDRALS_INC_HYDROGEN 12I6 ==============================================
    set count 12
    for { set i 0 } { $i < $NPHIH } { incr i } {
	for { set j 0 } { $j < 5 } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,DIHEDRALS_H,$i,I) [ red3 $tmp(0) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,J) [ red3 $tmp(1) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,K) [ red3 $tmp(2) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,L) [ red3 $tmp(3) ]
	set amber_prmtop($inst,DIHEDRALS_H,$i,TYPE) $tmp(4)
    }

    # DIHEDRALS_WITHOUT_HYDROGEN 12I6  =======================================
    set count 12
    for { set i 0 } { $i < $NPHIA } { incr i } {
	for { set j 0 } { $j < 5 } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    set tmp($j) [ expr int ($label ) ]
	    incr count
	}
	# reduce to atom indices
	set amber_prmtop($inst,DIHEDRALS_A,$i,I) [ red3 $tmp(0) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,J) [ red3 $tmp(1) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,K) [ red3 $tmp(2) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,L) [ red3 $tmp(3) ]
	set amber_prmtop($inst,DIHEDRALS_A,$i,TYPE) $tmp(4)
    }

    # %FLAG EXCLUDED_ATOMS_LIST %FORMAT(10I8) =============================================
    #                                                                   
    # NATEX  : the excluded atom list.  To get the excluded list for atom
    # "i" you need to traverse the NUMEX list, adding up all
    # the previous NUMEX values, since NUMEX(i) holds the number
    # of excluded atoms for atom "i", not the index into the 
    # NATEX list.  Let IEXCL = SUM(NUMEX(j), j=1,i-1), then
    # excluded atoms are NATEX(IEXCL) to NATEX(IEXCL+NUMEX(i)).

    set count 12
    for { set i 0 } { $i < $NATOM } { incr i } {
	for { set j 0 } { $j < $amber_prmtop($inst,N_EXCL_ATOMS,$i) } { incr j } {
	    if { $count > 11} {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    incr count
	    set amber_prmtop($inst,EXCL,$i,$j)  [ expr int ($label ) ]
	}
    }

    # HBOND_ACOEF 5E16.8 ================================================
    set count 5
    set k 0
    for { set i 0 } { $i < $NPHB } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    set amber_prmtop($inst,HBA,$k) $label
	    incr count
	    incr k
	}
    }

    # HBOND_BCOEF 5E16.8 ==============================================
    set count 5
    set k 0
    for { set i 0 } { $i < $NPHB } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    set amber_prmtop($inst,HBB,$k) [ string trim $label]
	    incr count
	    incr k
	}
    }

    # %FLAG HBCUT %FORMAT(5E16.8)  =================================================
    # no longer in use
    set count 5
    set k 0
    for { set i 0 } { $i < $NPHB } { incr i } {
	for { set j 0 } { $j <= $i } { incr j } {
	    if { $count > 4 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    ######set amber_prmtop($inst,HBCUT,$k) [ string trim $label]
	    incr count
	    incr k
	}
    }

 
    # AMBER_ATOM_TYPE 20a4 ==========================================
    set count 20
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 19 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 4] [ expr ( $count + 1 ) * 4 - 1 ] ]
	#puts stdout $label
	set amber_prmtop($inst,AMBER_ATOM_TYPE,$i) [ string trim $label ]
	incr count
    }


    #FORMAT(20A4)  (ITREE(i), i=1,NATOM)
    #  ITREE  : the list of tree joining information, classified into five
    #           types.  M -- main chain, S -- side chain, B -- branch point, 
    #           3 -- branch into three chains, E -- end of the chain
    #


    set count 20
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 19 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 4] [ expr ( $count + 1 ) * 4 - 1 ] ]
	#puts stdout $label
	# skip ITREE
	#set amber_prmtop($inst,AMBER_ATOM_TYPE,$i) [ string trim $label ]
	incr count
    }

    #FORMAT(12I6)  (JOIN(i), i=1,NATOM)
    #  JOIN   : tree joining information, potentially used in ancient
    #           analysis programs.  Currently unused in sander or gibbs.
    #

    set count 12
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 11 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	#puts stdout $label
	# skip JOIN
	#set amber_prmtop($inst,AMBER_ATOM_TYPE,$i) [ string trim $label ]
	incr count
    }

    #FORMAT(12I6)  (IROTAT(i), i = 1, NATOM)
    #  IROTAT : apparently the last atom that would move if atom i was
    #           rotated, however the meaning has been lost over time.
    #           Currently unused in sander or gibbs.

    set count 12
    for { set i 0 } { $i < $NATOM } { incr i } {
	if { $count > 11 } {
	    gets $fp line
	    set count 0
	}
	set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	#puts stdout $label
	# skip JOIN
	#set amber_prmtop($inst,AMBER_ATOM_TYPE,$i) [ string trim $label ]
	incr count
    }

    if { $IFBOX > 0 } {

	#The following are only present if IFBOX .gt. 0

	#FORMAT(12I6)  IPTRES, NSPM, NSPSOL
	#  IPTRES : final residue that is considered part of the solute,
	#           reset in sander and gibbs
	#  NSPM   : total number of molecules
	#  NSPSOL : the first solvent "molecule"

	gets $fp line
	set NSPM [ lindex $line 1 ]

	#FORMAT(12I6)  (NSP(i), i=1,NSPM)
	#  NSP    : the total number of atoms in each molecule,
	#           necessary to correctly perform the pressure
	#           scaling.

	set count 12
	for { set i 0 } { $i < $NSPM } { incr i } {
	    if { $count > 11 } {
		gets $fp line
		set count 0
	    }
	    set label [ string range $line [ expr $count * 6] [ expr ( $count + 1 ) * 6 - 1 ] ]
	    # skip NSP
	    #set amber_prmtop....
	    incr count
	}

	#FORMAT(5E16.8)  BETA, BOX(1), BOX(2), BOX(3)
	#  BETA   : periodic box, angle between the XY and YZ planes in
	#           degrees.
	#  BOX    : the periodic box lengths in the X, Y, and Z directions
	#

	gets $fp line
	set count 0
	for { set i 0 } { $i < 4 } { incr i } {
	    set tmp($i) [ string range $line [ expr $count * 16] [ expr ( $count + 1 ) * 16 - 1 ] ]
	    incr count
	}
	set amber_prmtop($inst,BETA) $tmp(0)
	set amber_prmtop($inst,BOX,1) $tmp(1)
	set amber_prmtop($inst,BOX,2) $tmp(2)
	set amber_prmtop($inst,BOX,3) $tmp(3)
    }

    # S K I P   T H E    R E S T

    #The following are only present if IFCAP .gt. 0
    #
    #FORMAT(12I6)  NATCAP
    #  NATCAP : last atom before the start of the cap of waters
    #           placed by edit
    #
    #FORMAT(5E16.8)  CUTCAP, XCAP, YCAP, ZCAP
    #  CUTCAP : the distance from the center of the cap to the outside
    #  XCAP   : X coordinate for the center of the cap
    #  YCAP   : Y coordinate for the center of the cap
    #  ZCAP   : Z coordinate for the center of the cap
    #


    #The following is only present if IFPERT .gt. 0
    #Note that the initial state, or equivalently the prep/link/edit state, is represented by lambda=1 and the perturbed state, or final state specified in parm, is the lambda=0 state.
    #
    #FORMAT(12I6)  (IBPER(i), JBPER(i), i=1,NBPER)
    #  IBPER  : atoms involved in perturbed bonds
    #  JBPER  : atoms involved in perturbed bonds
    #
    #FORMAT(12I6)  (ICBPER(i), i=1,2*NBPER)
    #  ICBPER : pointer into the bond parameter arrays RK and REQ for the
    #           perturbed bonds.  ICBPER(i) represents lambda=1 and 
    #           ICBPER(i+NBPER) represents lambda=0.
    #
    #FORMAT(12I6)  (ITPER(i), JTPER(i), KTPER(i), i=1,NGPER)
    #  IPTER  : atoms involved in perturbed angles
    #  JTPER  : atoms involved in perturbed angles
    #  KTPER  : atoms involved in perturbed angles
    #
    #FORMAT(12I6)  (ICTPER(i), i=1,2*NGPER)
    #  ICTPER : pointer into the angle parameter arrays TK and TEQ for 
    #           the perturbed angles.  ICTPER(i) represents lambda=0 and 
    #           ICTPER(i+NGPER) represents lambda=1.
    #
    #FORMAT(12I6)  (IPPER(i), JPPER(i), KPPER(i), LPPER(i), i=1,NDPER)
    #  IPPER  : atoms involved in perturbed dihedrals
    #  JPPER  : atoms involved in perturbed dihedrals
    #  KPPER  : atoms involved in perturbed dihedrals
    #  LPPER  : atoms involved in pertrubed dihedrals
    #
    #FORMAT(12I6)  (ICPPER(i), i=1,2*NDPER)
    #  ICPPER : pointer into the dihedral parameter arrays PK, PN and
    #           PHASE for the perturbed dihedrals.  ICPPER(i) represents 
    #           lambda=1 and ICPPER(i+NGPER) represents lambda=0.
    #
    #FORMAT(20A4)  (LABRES(i), i=1,NRES)
    #  LABRES : residue names at lambda=0
    #
    #FORMAT(20A4)  (IGRPER(i), i=1,NATOM)
    #  IGRPER : atomic names at lambda=0
    #
    #FORMAT(20A4)  (ISMPER(i), i=1,NATOM)
    #  ISMPER : atomic symbols at lambda=0
    #
    #FORMAT(5E16.8)  (ALMPER(i), i=1,NATOM)
    #  ALMPER : unused currently in gibbs
    #
    #FORMAT(12I6)  (IAPER(i), i=1,NATOM)
    #  IAPER  : IAPER(i) = 1 if the atom is being perturbed
    #
    #FORMAT(12I6)  (IACPER(i), i=1,NATOM)
    #  IACPER : index for the atom types involved in Lennard Jones
    #           interactions at lambda=0.  Similar to IAC above.  
    #           See ICO above.
    #
    #FORMAT(5E16.8)  (CGPER(i), i=1,NATOM)
    #  CGPER  : atomic charges at lambda=0
    #
    #The following is only present if IPOL .eq. 1
    #
    #FORMAT(5E18.8) (ATPOL(i), i=1,NATOM)
    #  ATPOL  : atomic polarizabilities
    #


    #The following is only present if IPOL .eq. 1 .and. IFPERT .eq. 1
    #
    #FORMAT(5E18.8) (ATPOL1(i), i=1,NATOM)
    #  ATPOL1 : atomic polarizabilities at lambda = 1 (above is at lambda = 0)
    #

}

proc load_prmtop_parms { args } {

    upvar amber_prmtop amber_prmtop

    set inst amber1

    #parray amber_prmtop

    #
    # Bond Stretch terms
    #
    set NBONH $amber_prmtop($inst,NBONH)
    set NBONA $amber_prmtop($inst,NBONA)
    for { set ix 0 } { $ix < $NBONH } { incr ix } {

	set i $amber_prmtop($inst,BONDS_H,$ix,I) 
	set j $amber_prmtop($inst,BONDS_H,$ix,J)
	set type [ expr $amber_prmtop($inst,BONDS_H,$ix,TYPE)  - 1]
	set fc $amber_prmtop($inst,BOND_FC,$type)
	set r0 $amber_prmtop($inst,BOND_R0,$type)
	#puts stdout "X1 harmonic bond stretch $i $j $fc $r0"
	param_add_amber_term "harmonic bond stretch" $i $j $fc $r0
    }
    for { set ix 0 } { $ix < $NBONA } { incr ix } {

	set i $amber_prmtop($inst,BONDS_A,$ix,I) 
	set j $amber_prmtop($inst,BONDS_A,$ix,J)
	set type [ expr $amber_prmtop($inst,BONDS_A,$ix,TYPE)  - 1]
	set fc $amber_prmtop($inst,BOND_FC,$type)
	set r0 $amber_prmtop($inst,BOND_R0,$type)
	#puts stdout "X2 harmonic bond stretch $i $j $fc $r0"
	param_add_amber_term "harmonic bond stretch" $i $j $fc $r0
    }

    #
    # Set up angles
    #
    set NTHETH $amber_prmtop($inst,NTHETH)
    set NTHETA $amber_prmtop($inst,NTHETA)
    for { set ix 0 } { $ix < $NTHETH } { incr ix } {

	set i $amber_prmtop($inst,ANGLES_H,$ix,I) 
	set j $amber_prmtop($inst,ANGLES_H,$ix,J)
	set k $amber_prmtop($inst,ANGLES_H,$ix,K)
	set type [ expr $amber_prmtop($inst,ANGLES_H,$ix,TYPE)  - 1]
	set fc $amber_prmtop($inst,ANG_FC,$type)
	set a0 $amber_prmtop($inst,ANG_A0,$type)
	#puts stdout "X1 harmonic angle bend $i $j $k $fc $a0"
	param_add_amber_term "harmonic angle bend" $i $j $k $fc $a0
    }

    for { set ix 0 } { $ix < $NTHETA } { incr ix } {

	set i $amber_prmtop($inst,ANGLES_A,$ix,I) 
	set j $amber_prmtop($inst,ANGLES_A,$ix,J)
	set k $amber_prmtop($inst,ANGLES_A,$ix,K)
	set type [ expr $amber_prmtop($inst,ANGLES_A,$ix,TYPE)  - 1]
	set fc $amber_prmtop($inst,ANG_FC,$type)
	set a0 $amber_prmtop($inst,ANG_A0,$type)
	#puts stdout "X2 harmonic angle bend $i $j $k $fc $a0"
	param_add_amber_term "harmonic angle bend" $i $j $k $fc $a0
    }

    #
    # dihedrals
    #
    set NPHIH $amber_prmtop($inst,NPHIH)
    set NPHIA $amber_prmtop($inst,NPHIA)
    for { set ix 0 } { $ix < $NPHIH } { incr ix } {

	set i $amber_prmtop($inst,DIHEDRALS_H,$ix,I) 
	set j $amber_prmtop($inst,DIHEDRALS_H,$ix,J)
	set k $amber_prmtop($inst,DIHEDRALS_H,$ix,K)
	set l $amber_prmtop($inst,DIHEDRALS_H,$ix,L)
	set type [ expr $amber_prmtop($inst,DIHEDRALS_H,$ix,TYPE)  - 1]
	set pk $amber_prmtop($inst,DIHEDRAL_FC,$type)
	set phase $amber_prmtop($inst,DIHEDRAL_PHASE,$type)
	set pn $amber_prmtop($inst,DIHEDRAL_PERIOD,$type)
	#puts stdout "X1 cosine dihedral $ix: $i $j $k $l $pk $phase $pn"
	param_add_amber_term "cosine dihedral" $i $j $k $l $pk $phase $pn
    }

    for { set ix 0 } { $ix < $NPHIA } { incr ix } {

	set i $amber_prmtop($inst,DIHEDRALS_A,$ix,I) 
	set j $amber_prmtop($inst,DIHEDRALS_A,$ix,J)
	set k $amber_prmtop($inst,DIHEDRALS_A,$ix,K)
	set l $amber_prmtop($inst,DIHEDRALS_A,$ix,L)
	set type [ expr $amber_prmtop($inst,DIHEDRALS_A,$ix,TYPE)  - 1]
	set pk $amber_prmtop($inst,DIHEDRAL_FC,$type)
	set phase $amber_prmtop($inst,DIHEDRAL_PHASE,$type)
	set pn $amber_prmtop($inst,DIHEDRAL_PERIOD,$type)
	#puts stdout "X2 cosine dihedral $ix:  $i $j $k $l $pk $phase $pn"
	param_add_amber_term "cosine dihedral" $i $j $k $l $pk $phase $pn

    }

    # vdw terms

    # nonbonded parm index (square)

    #  ICO    : provides the index to the nonbon parameter
    # arrays CN1, CN2 and ASOL, BSOL.  All possible 6-12
    # or 10-12 atoms type interactions are represented.
    # NOTE: A particular atom type can have either a 10-12
    # or a 6-12 interaction, but not both.  The index is
    # calculated as follows:
    # index = ICO(NTYPES*(IAC(i)-1)+IAC(j))
    # If index is positive, this is an index into the
    # 6-12 parameter arrays (CN1 and CN2) otherwise it
    # is an index into the 10-12 parameter arrays (ASOL
    # and BSOL).

    # We need to store NB parameters for every pair of atom types
    # As well as the numerical index, we need to 

    set NTYPES $amber_prmtop($inst,NTYPES)

    global amber_code_from_type
    global amber_known_types

    set nt [ llength $amber_known_types ]

    for { set i 0 } { $i < $nt } { incr i } {
	set itag [ lindex $amber_known_types $i ]
	set icode [ expr $amber_code_from_type($itag) -1 ]

	for { set j 0 } { $j <= $i } { incr j } {
	    
	    set jtag [ lindex $amber_known_types  $j ]
	    set jcode [ expr $amber_code_from_type($jtag) -1 ]

	    set index $amber_prmtop($inst,NONB_PARM_INDEX,$icode,$jcode)
	    if { $index > 0 } {

		set ix [ expr $index - 1 ]
		set c6 $amber_prmtop($inst,LJA,$ix) 
		set c12 $amber_prmtop($inst,LJB,$ix)
		#puts stdout "VDW 6-12 $i $itag $j  $jtag  6-12 $index : $c6 $c12"
		param_add_parm {6-12 non-bonded}  "$itag $jtag $c12 $c6"		

	    } else {
		set ix [ expr (-1 * $index) - 1 ]
		set c10 $amber_prmtop($inst,HBA,$ix) 
		set c12 $amber_prmtop($inst,HBB,$ix)
		#puts stdout "VDW 10-12 $i $itag $j  $jtag  10-12 $index : $amber_prmtop($inst,HBA,$ix) $amber_prmtop($inst,HBB,$ix) "
		# could use m n vdw but units wouldnt match
		param_add_parm {k l m power-law non-bonded} "$itag $jtag 12 $c12 10 $c10 6 0.00"		
	    }
	}
    }

    # in case of vdw energy errors, we will needto check this against what is
    # generated from the dl_poly interface

    # puts stdout "Excluded atom table from AMBER"
    # set NATOM $amber_prmtop($inst,NBONH)
    # for { set i 0 } { $i < $NATOM } { incr i } {
    #	for { set j 0 } { $j < $amber_prmtop($inst,N_EXCL_ATOMS,$i) } { incr j } {
    #	    puts stdout "$amber_prmtop($inst,EXCL,$i,$j) " nonewline
    #	}
    #	puts stdout ""
    # }
}


proc amber_type_to_z {type} {

    #PARM94 for DNA, RNA and proteins with TIP3P Water. USE SCEE=1.2 in energy progs
    # IP assumed to be Na+
    # IM assumed to be Cl-
    # IB 131.0                             'big ion w/ waters' for vacuum (Na+, 6H2O)

    set type [ string toupper $type ]

    #hms Added GAFF atom types:
    #hms CD - CE - CF - CU
    #hms NH - ND - NE - NO
    #hms SS

    switch $type { 
	C - CA - CB  - CC - CK - CM - CN - CP - CQ - CR - CT - CV - CW - C* - C0 - CD - CE - CF - CU - CX - 3C - 2C  { return 6 }
	H  - HC - H1 - H2 - H3 - HA - H4 - H5 - HO - HS - HW - HP - HN - HX { return 1 }
	N  - NA - NB - NC - N2 - N3 - NF - NM - 'N*' - NH - ND - NE - NO - Y2 - Y5  { return 7 }
	O  - OW - OH - OS - O2 - OM - OB - X1 - X2 - Y1 - Y3 - Y4 - Y6 - Y7  { return 8 }
    FE - M1 - M2 { return 26 }
	SH - SF - SD - SA - SB - SC - SM - SS { return 16 }
	IM { return 17 }
	IP - IB { return 11 }
        FN - F3 - F4 { return 26 }
	EP { return -1 }
	default {
	    push_banner_flag 0
	    set ret [ get_element_data symbol= [ string tolower $type] field=atomic_number ]
	    pop_banner_flag
	    return $ret
	}
    }
}


proc load_amber_coords {args} {

    if { [ parsearg load_amber_coords { coords inpcrd prmtop } $args ] != 0 } { 
	error "error in arguments" 
    }

    push_banner_flag 0
    set unknown_atoms {}
    set tags {}

    parse_prmtop $prmtop

    set NATOM $amber_prmtop(amber1,NATOM)

    for { set i 0 } { $i < $NATOM } { incr i } {
	set label $amber_prmtop(amber1,AMBER_ATOM_TYPE,$i)
	set z [ amber_type_to_z [ string trim $label ]  ]
	if { $z <= 0 } {
	    lappend unknown_atoms [string trim $label ]
	}
	set tag [ get_element_data atomic_number=$z field=atomic_symbol ]
	lappend tags $tag
    }

    pop_banner_flag 0

    if { [ llength $unknown_atoms ] !=  0 } {
	puts stdout "***********************************"
	puts stdout "***********************************"
	puts stdout "Warning: unknown atom types from amber prmtop: $unknown_atoms"
	puts stdout "This can be fixed by adding entries to amber_type_to_z in chemsh/src/interface_amber/parse_amber.tcl"
	puts stdout "***********************************"
	puts stdout "***********************************"
    }

    set fac 1.889726664
    set fpo [ open $coords w ]
    puts $fpo "block=fragment records=0"
    puts $fpo "block=title records=1"
    puts $fpo "from inpcrd"
    puts $fpo "block=coordinates records=$NATOM"

    set fp [ open $inpcrd r ]
    #  first line is blank
    gets $fp line 

    if { [ string index $line 0 ] == "%" } {

	# This is a new format file 
	# starts like this....

	#%VERSION  VERSION_STAMP = V0001.000  DATE = 12/20/05  16:49:26
	#%FLAG TITLE
	#%FORMAT(a)
	#joint amber charmm
	#%FLAG ATOMIC_COORDS_SIMULATION_TIME
	#%FORMAT(E16.8)
	#0.00000000E+00
	#%FLAG ATOMIC_COORDS_NUM_LIST
	#%FORMAT(i8)
	#23558
	#%FLAG ATOMIC_COORDS_LIST
	#%COMMENT   dimension = (3,23558)
	#%FORMAT(3e20.12)
	#0.387850000000E+02  0.198310000000E+02  0.386670000000E+02
	#0.376800000000E+02  0.201570000000E+02  0.376780000000E+02
	#0.377150000000E+02  0.215980000000E+02  0.372520000000E+02


	prmtop_skip_to $fp "TITLE          "
	gets $fp line
	#  skip to format
	while { [ string index $line 3 ] != "R" } {
	    #puts stdout " skipper1 $line "
	    gets $fp line
	}

	gets $fp line
	#puts stdout "read title $line"

	prmtop_skip_to $fp "ATOMIC_COORDS_N"
	#  skip to format
	gets $fp line
	while { [ string index $line 3 ] != "R" } {
	    #puts stdout " skipper2 $line "
	    gets $fp line
	}
	gets $fp line
	set NATOM2 [ string trim $line]
	if { $NATOM != $NATOM2 } { chemerr "inpcrd and prmtop files have different NATOM   $NATOM $NATOM2" }

	prmtop_skip_to $fp "ATOMIC_COORDS_L"

	gets $fp line
	# skip to format
	while { [ string index $line 3 ] != "R" } {
	    #puts stdout " skipper3 $line "
	    gets $fp line
	}
	
	for { set i 0 } { $i < $NATOM } { incr i } {
	    gets $fp line
	    #puts stdout $line
	    set count 0
	    for { set j 0 } { $j < 3 } { incr j } {
		set label [ string range $line [ expr $count * 20] [ expr ( $count + 1 ) * 20 - 1 ] ]
		set tmp($j)  [ string trim $label]
		incr count
	    }
	    # write out the atom record
	    puts $fpo "[ lindex $tags $i ] [ expr $fac * $tmp(0)] [expr $fac * $tmp(1)] [expr $fac * $tmp(2)]"

	}

    } else {

	#  second line number of atoms (and a float value)
	gets $fp line
	set NATOM2 [ lindex $line 0]
	if { $NATOM != $NATOM2 } { chemerr "inpcrd and prmtop files have different NATOM   $NATOM $NATOM2" }

	set count 6

	for { set i 0 } { $i < $NATOM } { incr i } {
	    if { $count > 5 } {
		gets $fp line
		set count 0
	    }
	    for { set j 0 } { $j < 3 } { incr j } {
		set label [ string range $line [ expr $count * 12] [ expr ( $count + 1 ) * 12 - 1 ] ]
		set tmp($j)  [ string trim $label]
		incr count
	    }
	    # write out the atom record
	    puts $fpo "[ lindex $tags $i ] [ expr $fac * $tmp(0)] [expr $fac * $tmp(1)] [expr $fac * $tmp(2)]"
	}

    }
    close $fp

    #
    set inst amber1
    set NBONH $amber_prmtop($inst,NBONH)
    set NBONA $amber_prmtop($inst,NBONA)
    set nconn [ expr $NBONH + $NBONA ]
    puts $fpo "block=connectivity records=$nconn"

    for { set ix 0 } { $ix < $NBONH } { incr ix } {
	set i $amber_prmtop($inst,BONDS_H,$ix,I) 
	set j $amber_prmtop($inst,BONDS_H,$ix,J)
	puts $fpo "$i $j"
    }
    for { set ix 0 } { $ix < $NBONA } { incr ix } {
	set i $amber_prmtop($inst,BONDS_A,$ix,I) 
	set j $amber_prmtop($inst,BONDS_A,$ix,J)
	puts $fpo "$i $j"
    }

    # puts stdout "IFBOX= $amber_prmtop(amber1,IFBOX)"

    if { $amber_prmtop(amber1,IFBOX) != 0  } {

	set beta  $amber_prmtop(amber1,BETA)

	if { [ expr abs ( $beta - 90.0 ) ] > 0.001 } {

	    chemerr "can only process orthogonal cells in amber"

	}

	set fac 1.889726664

	set box1  [ expr $fac * $amber_prmtop(amber1,BOX,1) ]
	set box2  [ expr $fac * $amber_prmtop(amber1,BOX,2) ]
	set box3  [ expr $fac * $amber_prmtop(amber1,BOX,3) ]

	puts $fpo "block=cell_vectors records=3"	
	puts $fpo "$box1    0.0     0.0"
	puts $fpo "0.0      $box2   0.0"
	puts $fpo "0.0      0.0     $box3"

    }

    close $fpo

}
