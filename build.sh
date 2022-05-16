#!/bin/bash

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'
KERNEL_DIR=$PWD

echo -e ""
echo -e "$gre ====================================\n\n Welcome to Citrus building program !\n\n ===================================="
echo -e "$gre \n 1.Build Citrus Clean\n\n 2.Build Citrus Dirty\n"
echo -n " Enter your choice:"
read qc

Start=$(date +"%s")

if [ $qc == 1 ]; then
echo -e "$yellow Running make clean before compiling \n$white"
make clean > /dev/null
rmdir out
export LC_ALL=C && export USE_CCACHE=1
ccache -M 100G
export ARCH=arm64
export KBUILD_BUILD_USER="trax85"

[ -d "out" ] && rm -rf out || mkdir -p out
fi

echo -e "$white"
date=$(date +"%d-%m-%y")
make O=out ARCH=arm64 cupida_defconfig
echo -e "$gre Starting build now... \n$white"
export PATH="${PATH}:/home/nesara/proton-clang/bin/"
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC="clang" \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      OBJDUMP=llvm-objdump STRIP=llvm-strip \
                      AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy \
                      CONFIG_NO_ERROR_ON_MISMATCH=y

zimage=$KERNEL_DIR/out/arch/arm64/boot/Image
if ! [ -a $zimage ];
then
echo -e "$red << Failed to compile zImage, fix the errors first >>$white"
else
End=$(date +"%s")
Diff=$(($End - $Start))
echo -e "$yellow\n Build succesful, generating flashable zip now \n $white"
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
cd AnyKernel
rm *.zip > /dev/null 2>&1
zip -r9 Citrus-Cupida-Test.zip *
echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
fi
