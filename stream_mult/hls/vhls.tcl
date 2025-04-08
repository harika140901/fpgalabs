source common.tcl

set projName mult_constant
set srcFiles [ list "mult_constant.cpp" ]
set tbFiles  []
set desc "Multiplier Stream Demo"
set version "1.0"

setupProj $projName $srcFiles $tbFiles
synthAndExport $desc $version

exit
