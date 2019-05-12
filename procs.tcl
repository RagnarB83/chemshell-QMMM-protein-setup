# Deletes integer index in nested list and renumbers everything after deletion
proc delindexandreorder {lst value} {
set afterdel no
set updatedlist {}
set newlist {}
set p 0
    foreach sublist $lst {
        set sl [llength $sublist]
        for { set j 0} {$j <= $sl} {incr j 1} {
            if {[string equal [lindex $sublist $j] $value]} {
            set del yes
                  set dellist [lsearch -all -inline -not -exact $sublist $value]
                   for { set k 0} {$k < [llength $dellist]} {incr k 1} {
                     set index [lindex $dellist $k]
                       if {$index >= $value } {set index [expr $index -1] }
                     lappend newlist $index
                   }
               set sublist $newlist
               set j $sl
             }
        }
    # Here adding the sublist where deletion occurred
# Had to add extra single-line ifblocks due to problems lappending with one-word lists
#puts "Now adding sublists"
    if { [info exists del] == "1" } {
         if { $afterdel == "no" } {
                    if { [llength $newlist] == "0" } {
                    #Here exporting emptylist information to outside so that the resname can be deleted.
                    global emptylist
                    set emptylist $p
                    #puts "emptylist is $emptylist . EMPTY"
                    #puts "newlist is $newlist . Skipping adding sublist"
                    } else {
                    #puts "else. Adding sublist"
                     #puts "Adding changed sublist for deletion $newlist"
                        if { [llength $newlist] == 1 } {
                        append $newlist " "
                        lappend updatedlist $newlist
                        } else { lappend updatedlist $newlist }
                    }
         set afterdel yes
# Adding sublists after deletion-sublist. Renumbered.
         } else {
          set sublist [vec - $sublist 1]
#puts "Adding changed sublist after deletion $sublist"
          if { [llength $sublist] == 1 } { 
              append $sublist " "
              lappend updatedlist $sublist 
              } else { lappend updatedlist $sublist }
         }
# Adding sublists before deletion. No change
    } else {
#puts "Adding unchanged sublist $sublist"
#puts "updated list: $updatedlist "
#puts "sublist is $sublist and length is [llength $sublist]"
          if { [llength $sublist] == 1 } {
              append sublist " "
              lappend updatedlist $sublist
              } else { lappend updatedlist $sublist }
    }
incr p 1
    }
return $updatedlist
}

# Some vector arithmetics procs below. From http://wiki.tcl.tk/14022
proc lmap {_var list body} {
     upvar 1 $_var var
     set res {}
     foreach var $list {lappend res [uplevel 1 $body]}
     set res
 }
#-- We need basic scalar operators from [expr] factored out:
 foreach op {+ - * / % ==} {proc $op {a b} "expr {\$a $op \$b}"}
proc vec {op a b} {
     if {[llength $a] == 1 && [llength $b] == 1} {
         $op $a $b
     } elseif {[llength $a]==1} {
         lmap i $b {vec $op $a $i}
     } elseif {[llength $b]==1} {
         lmap i $a {vec $op $i $b}
     } elseif {[llength $a] == [llength $b]} {
         set res {}
         foreach i $a j $b {lappend res [vec $op $i $j]}
         set res
     } else {error "length mismatch [llength $a] != [llength $b]"}
 }

#lappend to a nested list. From http://stackoverflow.com/questions/17945880/append-elements-to-nested-list-in-tcl
proc sub_lappend {listname idx args} {
    upvar 1 $listname l
    set subl [lindex $l $idx]
    lappend subl {*}$args
    lset l $idx $subl
}


#Process to convert full system atom numbers to list of ORCA QM region numbers (starting from zero).
proc atomnumtoQMregionnum {qmatoms atomstoflip} {
set sortqmatoms [lsort -integer $qmatoms]
#Tcl list of atoms to flip (system atom numbers)
set qmatomstoflip {}
for { set m 0 } { $m < [llength $atomstoflip]  } { incr m 1 } {
set x [lindex $atomstoflip $m]
set y [lsearch $sortqmatoms $x]
lappend qmatomstoflip $y
}
return $qmatomstoflip
}

# Gives list intersection (elements in common)
proc intersect args {
    set res {}
    foreach element [lindex $args 0] {
            set found 1
            foreach list [lrange $args 1 end] {
                if {[lsearch -exact $list $element] < 0} {
                    set found 0; break
                }
            }
            if {$found} {lappend res $element}
     }
     set res
}



proc listcomp {a b} {
  set diff {}
  foreach i $a {
    if {[lsearch -exact $b $i]==-1} {
      lappend diff $i
    }
  }
  return $diff
 }

# proc to create sequence
#Noet iota uses beginning number and then number of extra numbers
proc iota {base n} {
    set res {}
    for {set i $base} {$i<$n+$base} {incr i} {lappend res $i}
    set res
}

# Proper sequence from begin to end: seq 5 .. 10 creates: 5 6 7 8 9 10
proc seq {start ignore end} {
    set result []
    for {set i $start} {$i <= $end} {incr i} {
        lappend result $i
    }
    return $result
}


#Listmatch searches a list of lists:  {{1 2 3} {3 4} {4 5 6 7}}
# Searches for integer val. Returns the whole sublist if match.
proc listmatch {list val} {
foreach sublist $list {
  foreach {name} $sublist {
  #puts "sublist is $sublist. name is $name."
    if {[string eq $name $val]} {
       return $sublist
    }
  }
}
}

# findElement proc. Similar to listmatch above but returns number of sublist and index instead
proc findElement {lst value} {
    set i 0
    foreach sublist $lst {
        set sl [llength $sublist]
        for { set j 0} {$j <= $sl} {incr j 1} {
          if {[string equal [lindex $sublist $j] $value]} {
              return [list $i $j]
          }
    }
        incr i
    }
    return -1
}

#Check QM region for duplicates
proc checkQMregion {qmatoms} {
foreach i $qmatoms {
if {[info exists a($i)]} {
puts "Duplicate QM atom in list:"
puts $i
puts "Exiting Chemshell..."
exit
} {
set a($i) 1
}
}
}

# Write PDBfile from QM/MM optimization result.c file with correct residue and element information for VMD visualization
#Read PSF file for residue and atom info. Read result.c for coordinates.
proc properPDBwrite {coordfile psffile } {

#Grab elements and coords from coordfile
set c [open $coordfile r ]
set clines [split [read $c] "\n"]
set ellist {}
set grab False
set bohrang 0.529177
foreach line $clines {
  if {$grab == True } {
    if {[string match "block =*" $line] > 0} { set grab False; break }
    lappend ellist [lindex $line 0]
    lappend coords_x [expr [lindex $line 1] * $bohrang ]
    lappend coords_y [expr [lindex $line 2] * $bohrang ]
    lappend coords_z [expr [lindex $line 3]  * $bohrang ]
  }
  if {[string match "block = coordinates records*" $line] > 0} { set grab True }
}
close $c

#Grab residue info from psffile
set psf [open $psffile r ]
set psflines [split [read $psf] "\n"]

set atomindexlist {}
set segmentlist {}
set residlist {}
set resnamelist {}
set atomnamelist {}
set typeslist {}
set grab False
foreach line $psflines {
  if {$grab == True } {
    #If empty line (end of PSF-output)
    if {[string match "" $line] > 0} { set grab False; break }
    lappend atomindexlist [lindex $line 0]
    lappend segmentlist [lindex $line 1]
    lappend residlist [lindex $line 2]
    lappend resnamelist [lindex $line 3]
    lappend atomnamelist [lindex $line 4]
    lappend typeslist [lindex $line 5]
  }
  if {[string match "*!NATOM*" $line] > 0} { set grab True }
}
close $c

#Write new PDB file
set out [open "result.pdb" w ]
foreach a $atomindexlist b $segmentlist c $residlist d $resnamelist e $atomnamelist f $typeslist cx $coords_x cy $coords_y cz $coords_z el $ellist {
             set fmt1 "ATOM%7d %4s%4s%-1s%5d%12.3f%8.3f%8.3f%6s%6s%10s%2s"
 puts $out [format $fmt1 $a $e $d " " $c $cx $cy $cz "1.00" "0.00" $b $el]

}
close $out
puts ""
puts "Result PDB file written to: result.pdb"
puts ""
}