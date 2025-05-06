source common.tcl

set projName fft_hls
set srcFiles [ list "fft_hls.cpp" ]
set tbFiles  []
set desc "FFT Demo"
set version "1.0"

setupProj $projName $srcFiles $tbFiles
synthAndExport $desc $version

exit
