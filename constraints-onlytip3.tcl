exec rm -f constraints
set constraints [ open constraints  a]

#################
#Constraint setup GENERAL
# Will setup constraints for OPT if jobtype is set to "opt".
# Will setup constraints for MD if jobtype is set to "md".
################

# Creating new list that contains only active MM atoms (not qmatoms)

set mmact [listcomp $act $qmatoms ]


set nmmactfull [ llength $mmact ]
set nmmact [expr $nmmactfull-1]

#
# Sets up constraints to freeze the X-H bonds and TIP3 H-H bonds (looks for OT atomtype). 
puts "Setting up constraints for jobtype $jobtype ."
push_banner_flag 0

set con {}
# for loop that goes through whole mmact list
for { set iact 0 } { $iact <= $nmmact } { incr iact 1 } {
   set iat [ lindex $mmact $iact]
   set elem [ lindex [ get_atom_entry coords=$frag \
           atom_number=$iat ] 0 ]
#If statement to find OT in TIP3 and then adding H-H bond constraint (next 2 atoms)
# ($iat -1) thing is because of lindexing the list
  if { [lindex $types [expr $iat - 1 ]] == "OT" } then {
        if { $jobtype == "opt" } {
        lappend con [ list bond [expr $iat + 1] [expr $iat + 2] ]
        lappend con [ list bond [expr $iat] [expr $iat + 1] ]
        lappend con [ list bond [expr $iat] [expr $iat + 2] ]
        } elseif { $jobtype == "md" } {
               set dist [ lindex [ interatomic_distance \
                       coords=$frag \
                       i=[expr $iat + 1] j=[expr $iat + 2] 0 ]
        lappend con [ list [expr $iat + 1] [expr $iat + 2] $dist ]
        }
     }
   #if { $elem == "H" } then {
   #    set neighbours [ get_connected_atoms coords=$frag \
   #            atom_number=$iat ]
       #for { set ine 0 } { $ine < [ llength $neighbours ] } { incr ine 1 } {
       #    set jat [ lindex $neighbours $ine ]
       #    set jelem [ lindex [ get_atom_entry coords=$frag \
       #            atom_number=$jat ] 0 ]
           #if { $jelem != "H" } then {
           #    if { $jobtype == "opt" } {
           #      lappend con [ list bond $iat $jat ]
           #   } elseif { $jobtype == "md" } {
           #    set dist [ lindex [ interatomic_distance \
           #            coords=$frag \
           #            i=$iat j=$jat ] 0 ]
           #    lappend con [ list $iat $jat $dist ]
           #   }
        #   }
       # }
   #}
 }

 puts "[llength $con] constraints were defined. Written to constraints file"

 puts $constraints " Number of constraints [ llength $con ] "
 puts $constraints [ list $con ]
close $constraints

pop_banner_flag
