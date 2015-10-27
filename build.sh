#!/bin/bash

GCC_PATH=`pwd`/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin
export PATH=$GCC_PATH:$PATH

export USE_CCACHE=1
export CCACHE_DIR=`pwd`/.ccache
prebuilts/misc/linux-x86/ccache/ccache -M 120G

export MKBOOTIMG=`pwd`/kernel/samsung/lt03lte/tools/mkbootimg

if [ "x$1" == "x" ]; then
  products="lt03lte"
else
  products=$1
fi

if [ "x$2" == "xnoclean" ]; then
  noclean=1
else
  noclean=0
fi

# Fix build dependency
mkdir -p prebuilts/qemu-kernel/arm
touch prebuilts/qemu-kernel/arm/LINUX_KERNEL_COPYING

source build/envsetup.sh

if [ "x$noclean" == "x0" ]; then
  make clean
fi

for product in $products
do
  echo "lunch aosp_${product}-user"
  lunch aosp_${product}-user

  cd kernel/samsung/lt03lte
  export ARCH=arm
  export SUBARCH=arm
  export CROSS_COMPILE=arm-eabi-
  export SELINUX_DEFCONFIG=selinux_defconfig
  export VARIANT_DEFCONFIG=msm8974_sec_lt03eur_defconfig
  make msm8974_sec_defconfig
  make -j 16 zImage KCFLAGS=-Wno-sizeof-pointer-memaccess
  DTC=scripts/dtc/dtc

  rm rch/arm/boot/*.dtb

  for DTS_FILE in `ls arch/arm/boot/dts/msm8974/msm8974-sec-lt03-*.dts`
    do
    DTB_FILE=${DTS_FILE%.dts}.dtb
    DTB_FILE=arch/arm/boot/${DTB_FILE##*/}
    ZIMG_FILE=${DTB_FILE%.dtb}-zImage
    
    $DTC -p 1024 -O dtb -o $DTB_FILE $DTS_FILE
    cat arch/arm/boot/zImage $DTB_FILE > $ZIMG_FILE
  done

  tools/dtbTool -o arch/arm/boot/dtb -s 2048 -p scripts/dtc/ arch/arm/boot/

  cd -

  mkdir -p device/samsung/lt03lte-kernel
  cp kernel/samsung/lt03lte/arch/arm/boot/zImage device/samsung/lt03lte-kernel/zImage
  cp kernel/samsung/lt03lte/arch/arm/boot/dtb device/samsung/lt03lte-kernel/dtb

  make -j 16 otapackage
done
