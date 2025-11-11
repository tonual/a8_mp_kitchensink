#!/bin/sh
echo "> Compiling browser"
mpb mptb.pas
echo "> Creating .atr"
./mkatr digimsx.atr -b +ph bwdos/xbw130.dos +p bwdos/startup.bat output/mptb.xex ../song/1-channel-digi/* > /dev/null 2>&1
echo "> Done!"