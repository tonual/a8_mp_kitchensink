#!/bin/sh
clear
echo "> Compiling browser"
mpb mptb.pas
echo "> Creating .atr"

./mkatr dpkyvol1.atr -b +ph bwdos/xbw130.dos +p bwdos/startup.bat -s 524288 output/mptb.xex ../song/1-channel-digi/VOL1/* > /dev/null 2>&1 
./mkatr dpkyvol2.atr -b +ph bwdos/xbw130.dos +p bwdos/startup.bat -s 524288 output/mptb.xex ../song/1-channel-digi/VOL2/* > /dev/null 2>&1



#

echo "> Done!"