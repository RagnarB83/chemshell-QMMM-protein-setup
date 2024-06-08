#Creating fragfile
push_banner_flag 0

set numatoms [get_number_of_atoms coords=$frag]
puts "There are $numatoms atoms"
set all [seq 1 to $numatoms]


# This creates a list of active atoms inside a sphere with a specific radius arond a specific atom.
# Each atom which is inside the radium is looked up in the residue list in pdbresidues and the whole residue is put in act list.

set act {}
# Loop to get all interatomic distances between origin atom and all other atoms
# Takes whole residues by using listmatch proc and the residuegroups list (pdbresidues)
set group {}
#puts "radius is $radius"
    for { set m 1 } { $m <= $numatoms  } { incr m 1 } {
    set rij [interatomic_distance coords=$frag  i=$origin  j=$m unit=angstrom]
    #puts "rij is $rij for i=$origin and j=$m"
        # If distance is less than radius and also if not part of last group
        if { $rij < $radius && [lsearch $group $m] == "-1" } {
        set group [listmatch $residuegroups $m]
        #puts "group is $group"
        set act [concat $act $group]
        }
    }

puts "act (radius selection) has length [llength $act]"

set frozen [listcomp $all $act ]

#Add extrafrozen list to frozen
set frozen [concat $frozen $extrafrozen]

#Removing non-unique atom numbers
set frozen [lsort -unique -integer $frozen]
puts "Final frozen list has length [llength $frozen]. Written to file frozen. "
set frozenfile [ open frozen  w]
puts $frozenfile "set frozen { $frozen }"
close $frozenfile

# Here we need to change act so that it does not contain any numbers from list frozen
# List frozen has been added to by cofactor, others and frozen
set act [listcomp $act $frozen ]
puts "Final act list has length [llength $act]. Written to file act."
set actfile [ open act w]
puts $actfile "set act { $act }"
close $actfile


set sum [expr [llength $act] + [llength $frozen]]
if { $sum != $numatoms } {
puts "Sum of active atoms and frozen atoms is $sum"
puts "This is NOT equal to total number of atoms: $numatoms . Exiting..."
exit
}
puts "Sum of act atoms and frozen atoms is $sum"

pop_banner_flag
