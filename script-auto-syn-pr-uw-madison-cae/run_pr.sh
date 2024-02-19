#!/bin/bash
# this is a shell script to run place and route for all *.vg files in this foler
# note that the *.vg files require identical file and module name

set -e
set -o noclobber


echo ""
echo "***************************Start Place and Route**************************"
# check the existance of dc setup file and dc run script
SETUPFILE=.synopsys_dc.setup
SRCSETUPFILE=synopsys_dc.setup
if [ ! -f $SETUPFILE ]; then
    if [ -f $SRCSETUPFILE ]; then
        mv $SRCSETUPFILE $SETUPFILE
    else
        echo ""
        echo "Place and route setup file $SETUPFILE or $SRCSETUPFILE does not exist."
        return 0
    fi
fi

DCSCRIPT=script_pr.tcl
if [ ! -f $DCSCRIPT ]; then
    echo ""
    echo "Place and route script $DCSCRIPT does not exist."
    return 0
fi

vsuff=syn.vg

echo ""
echo "Place and route designs in *.vg files:"
if ls *.$vsuff; then
    for dut in $(ls *.$vsuff)
    do
        dutname="${dut%.*.*}"
        echo "Processing design $dutname in $dut..."
        sed -i "s/dut/$dutname/g" $DCSCRIPT
        rm -rf $dutname*/ CLIB*/
        icc2_shell -f $DCSCRIPT >| $dutname.pr.rpt
        sed -i "s/$dutname/dut/g" $DCSCRIPT
        echo "    Done"
        sleep 10s
    done
else
    echo "No design exists."
    return 0
fi

echo ""
echo "Check potential errors in log:"
grep -Ri "Error" ./*
grep -Ri "connected" ./*
echo ""
echo "******************************All Done******************************"
echo ""


