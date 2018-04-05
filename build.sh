# Specify the CLAPACK and NDK releases that you want to use. 
CLAPACK_RELEASE="3.2.1"
NDK_RELEASE="r16b"

# Specify the number of threads for building (typically number of cores + 1)
BUILD_THREADS="4"

# Now specify the systems that you want to build for and the API you want to use. 
# Note that arm64 is used in most modern devices, but x86_64 is useful if you want 
# to run in the emulator. Other options are "arm", "x86", "mips", "mips64"
declare -a SYSTEMS=("arm64" "x86_64" "arm" "x86")
#declare -a SYSTEMS=("arm64")
API="26"

# We want to color the font to differentiate our comments from other stuff
normal="\e[0m"
colored="\e[104m"

# Save the base directory 
BASE=$PWD

# See if we have already downloaded and unpacked clapack
CLAPACK_NAME=clapack-${CLAPACK_RELEASE}-CMAKE
CLAPACK=${BASE}/${CLAPACK_NAME}
if [ ! -d ${CLAPACK} ]; then

    # If we don't have it, download CLAPACK
    if [ ! -f ${CLAPACK_NAME}.tgz ]; then
    
        echo -e "${colored}Downloading CLAPACK${normal}" && echo 
        wget http://www.netlib.org/clapack/${CLAPACK_NAME}.tgz
    fi 

    echo -e "${colored}Unpacking CLAPACK${normal}" && echo 
    tar -xzf ${CLAPACK_NAME}.tgz

fi

# Make sure that testing is disabled for CLAPACK since they can't run on our system anyway
echo -e "${colored}Disabling CLAPACK testing since that would produce Android binaries that cannot run on this machine.${normal}" && echo 
find ${CLAPACK} -type f -name "CMakeLists.txt" | while read file; do
    sed -i 's/^add_subdirectory(TESTING)/#add_subdirectory(TESTING)/g' ${file}
done

# See if we have already downloaded and unpacked the ndk
NDK=${BASE}/android-ndk-${NDK_RELEASE}
NDK_ZIP=android-ndk-${NDK_RELEASE}-linux-x86_64.zip
if [ ! -d ${NDK} ]; then

    # If we don't have it, download the ndk
    if [ ! -f ${NDK_ZIP} ]; then

        echo -e "${colored}Downloading the NDK${normal}" && echo
        wget https://dl.google.com/android/repository/${NDK_ZIP}
    fi 

    # Now unpack the compressed file, printing a dot for every 100th file that gets unzipped
    echo -e "${colored}To unpack the NDK, we need 'unzip'. Please give us sudo rights to install it." && echo 
    sudo apt install -y unzip
    echo ""

    echo -e "${colored}Unpacking the NDK. This can take a very long time. Here is a dot for every 100th unpacked file:${normal}" && echo 
    unzip ${NDK_ZIP} | awk 'BEGIN {ORS=" "} {if(NR%100==0)print "."}'
    echo ""
    
fi

# See if we have already generated the standalone toolchain that we want/need
for SYSTEM in "${SYSTEMS[@]}" ; do
    
    mkdir -p toolchains
    mkdir -p build

    # If we don't have it, create the toolchain
    TOOLCHAIN=$BASE/toolchains/${SYSTEM}/${API}
    if [ ! -d ${TOOLCHAIN} ]; then

        echo -e "${colored}Creating the standalone toolchain for system=${SYSTEM}, api=${API}${normal}" && echo
        ${NDK}/build/tools/make_standalone_toolchain.py --arch ${SYSTEM} --api ${API} --install-dir ${TOOLCHAIN}
    fi
    
    # Now make a build folder for this toolchain. This is where we will install all of the libraries
    BUILD_DIR=$BASE/build/${SYSTEM}/${API}
    mkdir -p ${BUILD_DIR}
    
    # Compile CLAPACK if not already built
    CLAPACK_BUILD_DIR=${CLAPACK}/build/${SYSTEM}/${API}
    # if [ ! -d ${CLAPACK_BUILD_DIR} ]; then
    
        mkdir -p ${CLAPACK_BUILD_DIR}
        cd ${CLAPACK_BUILD_DIR}
        
        echo -e "${colored}Configuring CLAPACK${normal}" && echo 

        # Or use clang... up to you
        CC=$(find ${TOOLCHAIN}/bin/ -type f -name "*gcc")
        CXX=$(find ${TOOLCHAIN}/bin/ -type f -name "*g++")
        #CC=$(find ${TOOLCHAIN}/bin/ -type f -name "*clang")
        #CXX=$(find ${TOOLCHAIN}/bin/ -type f -name "*clang++")
        cmake -Wno-dev \
            -DCMAKE_SYSTEM_NAME=Android \
            -DCMAKE_ANDROID_STANDALONE_TOOLCHAIN=${TOOLCHAIN} \
            -DCMAKE_SYSROOT=${TOOLCHAIN}/sysroot \
            -DCMAKE_INSTALL_PREFIX:PATH=${BUILD_DIR} \
            -DCMAKE_C_COMPILER=${CC} \
            -DCMAKE_CXX_COMPILER=${CXX} \
            ../../..
            
        # make -j${BUILD_THREADS}
        make
        cd ${BASE}
    # fi
    
done


for SYSTEM in "${SYSTEMS[@]}" ; do

    echo -e "${colored}Done${normal}"
done