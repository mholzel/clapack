# Make sure that we have a folder to save all of the arithmetic outputs
mkdir -p arith

# We want to color the font to differentiate our comments from other stuff
normal="\e[0m"
colored="\e[104m"

# For each toolchain that we have generated 
cd toolchains
for TOOLCHAIN in */* ; do

    # Now for each toolchain, copy in the arithmetic checker and build it
    echo -e "${colored}Detecting the arithmetic of the toolchain: ${TOOLCHAIN}${normal}" && echo 
    ${TOOLCHAIN}/bin/clang -pie ../arithchk.c -lm -DNO_FPINIT

    # Next, before deploying, 
    read -n 1 -s -r -p "Please connect a device of type ${TOOLCHAIN_BIN}, and then press any key to continue"
    adb push a.out /data/local/tmp/.
    rm a.out
    
    mkdir -p ../arith/${TOOLCHAIN}
    adb shell "./data/local/tmp/a.out" > ../arith/${TOOLCHAIN}/arith.h

done

exit 0
# Now, for each of the toolchains, copy arithchk.c into the bin folder 

# Go to the bin folder of the toolchain you want to test and copy in arithchk.c
./clang -pie arithchk.c -lm -DNO_FPINIT


# Finally, we need to run this on an emulator to get the actual values
# So start the appropriate emulator and 
adb push a.out /data/local/tmp/.
adb shell "./data/local/tmp/a.out"
