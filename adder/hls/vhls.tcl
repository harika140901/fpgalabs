source common.tcl

set projName add
set srcFiles [ list "add.cpp" ]
set tbFiles  []
set desc "Adder Demo"
set version "1.0"

setupProj $projName $srcFiles $tbFiles
synthAndExport $desc $version

exit
