#!/bin/sh
clear
echo "> Compiling browser"
mpb mptb.pas
echo "> Creating .atr"

#./mkatr dimsxvo1.atr -b +ph bwdos/xbw130.dos +p bwdos/startup.bat -s 524288 output/mptb.xex ../song/1-channel-digi/VOL1/*
./mkatr dimsxvo2.atr -b +ph bwdos/xbw130.dos +p bwdos/startup.bat -s 524288 output/mptb.xex ../song/1-channel-digi/VOL2/*
#./mkatr dimsxvo3.atr -b +ph bwdos/xbw130.dos +p bwdos/startup.bat -s 524288 output/mptb.xex ../song/1-channel-digi/VOL3/*


#

echo "> Done!"