#!/bin/bash
BUILD_START=$(date +"%s")

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Kernel details
KERNEL_NAME="Stratosphere"
VERSION="ME"
DATE=$(date +"%d-%m-%Y-%I-%M")
DEVICE="NOKIA_SDM660"
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE.zip
defconfig=stratosphere_defconfig

# Dirs
BASE_DIR=`pwd`/../
KERNEL_DIR=$BASE_DIR/android_kernel_nokia_sdm660
ANYKERNEL_DIR=$BASE_DIR/AnyKernel3
KERNEL_IMG=$BASE_DIR/output/arch/arm64/boot/Image.gz-dtb
UPLOAD_DIR=$BASE_DIR/Stratosphere-Kernel

# Export
# export PATH="$BASE_DIR/azure-clang/bin:$PATH"
export ARCH=arm64
export CROSS_COMPILE=~/evagcc/gcc-arm64/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=~/evagcc/gcc-arm/bin/arm-eabi-
export USE_CCACHE=1
export CCACHE_EXEC=$(command -v cccache)

## Functions ##

# Make kernel
function make_kernel() {
  echo -e "$cyan***********************************************"
  echo -e "          Initializing defconfig          "
  echo -e "***********************************************$nocol"
  make $defconfig O=$BASE_DIR/output/
  echo -e "$cyan***********************************************"
  echo -e "             Building kernel          "
  echo -e "***********************************************$nocol"
  make -j$(nproc --all) O=$BASE_DIR/output/
  if ! [ -a $KERNEL_IMG ];
  then
    echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
    exit 1
  fi
}

# Making zip
function make_zip() {
cp $KERNEL_IMG $ANYKERNEL_DIR
mkdir -p $UPLOAD_DIR
cd $ANYKERNEL_DIR
zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip LICENSE
mv $ANYKERNEL_DIR/UPDATE-AnyKernel2.zip $UPLOAD_DIR/$FINAL_ZIP
}

# Options
function options() {
echo -e "$cyan***********************************************"
  echo "          Compiling Stratosphere Kernel              "
  echo -e "***********************************************$nocol"
  echo -e " "
  echo -e " Select one of the following types of build : "
  echo -e " 1.Dirty"
  echo -e " 2.Clean"
  echo -n " Your choice : ? "
  read ch

  echo -e " Select if you want zip or just kernel : "
  echo -e " 1.Get flashable zip"
  echo -e " 2.Get kernel only"
  echo -n " Your choice : ? "
  read ziporkernel

case $ch in
  1) echo -e "$cyan***********************************************"
     echo -e "          	Dirty          "
     echo -e "***********************************************$nocol"
     make_kernel ;;
  2) echo -e "$cyan***********************************************"
     echo -e "          	Clean          "
     echo -e "***********************************************$nocol"
     make clean O=$BASE_DIR/output/
     make mrproper O=$BASE_DIR/output/
     make_kernel ;;
esac

if [ "$ziporkernel" = "1" ]; then
     echo -e "$cyan***********************************************"
     echo -e "     Making flashable zip        "
     echo -e "***********************************************$nocol"
     make_zip
else
     echo -e "$cyan***********************************************"
     echo -e "     Building Kernel only        "
     echo -e "***********************************************$nocol"
fi
}

# Clean Up
function cleanup(){
rm -rf $ANYKERNEL_DIR/Image.gz-dtb
}

options
cleanup
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"

