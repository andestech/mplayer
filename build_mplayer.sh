#!/bin/sh

## Enviroment Setting
WORKDIR=`pwd`
#export DEPLOY_DIR=${WORKDIR}/RISCV64
#export DEPLOY_DIR=${WORKDIR}/RISCV32
export DEPLOY_DIR=${WORKDIR}/${INSTALL_DIR}
export LOG_DIR=${WORKDIR}/LOG
DEMO=${WORKDIR}/demo_mplayer

# Optimization flags
#OPTFLAGS="-O0 -g"
#OPTFLAGS="-O2"
OPTFLAGS="-O3 -fomit-frame-pointer -funroll-loops"
#export CROSS_COMPILE="riscv64-linux-"
#export CROSS_COMPILE="riscv32-linux-"
#which ${CROSS_COMPILE}gcc &> /dev/null || export CROSS_COMPILE="riscv64-elf-"
#which ${CROSS_COMPILE}gcc &> /dev/null || export CROSS_COMPILE="riscv32-elf-"

export HOST=${CROSS_COMPILE%-}
HOST_TYPE=`uname -m`
export BUILD="${HOST_TYPE}-linux"
export TARGET=${CROSS_COMPILE%-}

# Andes Cross Toolchain settings
export BUILD_CC=gcc
export CC=${CROSS_COMPILE}gcc
export CXX=${CROSS_COMPILE}g++
export AR=${CROSS_COMPILE}ar
export AS=${CROSS_COMPILE}as
export RANLIB=${CROSS_COMPILE}ranlib
export LD=${CROSS_COMPILE}ld
export STRIP=${CROSS_COMPILE}strip

export CFLAGS="${OPTFLAGS} -I${DEPLOY_DIR}/usr/include"
#export LDFLAGS="-L${DEPLOY_DIR}/usr/lib"
export LDFLAGS="-static -L${DEPLOY_DIR}/usr/lib"

# Creat log folder if needs
if [ ! -d $LOG_DIR  ]; then
	echo "$LOG_DIR does not exist, now created."
	mkdir -p $LOG_DIR
fi

if [  ${CROSS_COMPILE} = "riscv64-linux-"  ]; then
	mkdir -p ${WORKDIR}/RISCV64
elif [  ${CROSS_COMPILE} = "riscv32-linux-"  ]; then
	mkdir -p ${WORKDIR}/RISCV32
else
	echo " CROSS_COMPILE args not set !!"
	exit 1
fi

LIBMAD_SOURCE=libmad-0.15.1b
MPLAYER_SOURCE=MPlayer-1.0rc2

build_libmad()
{
echo
echo "Compiling $LIBMAD_SOURCE"

cd $LIBMAD_SOURCE

if test -f Makefile; then
    make distclean &> /dev/null
fi

CFLAGS="${OPTFLAGS} -I${DEPLOY_DIR}/usr/include" \
LDFLAGS="-L${DEPLOY_DIR}/usr/lib" \
./configure --host=$HOST --build=$BUILD --prefix=/usr --disable-debugging --enable-shared -enable-static

make all 2> ${LOG_DIR}/${LIBMAD_SOURCE}_error.log| tee ${LOG_DIR}/${LIBMAD_SOURCE}_make.log
make install DESTDIR=${DEPLOY_DIR} 2>&1 | tee ${LOG_DIR}/${LIBMAD_SOURCE}_install.log

cd ..
}

build_mplayer()
{
echo
echo "Compiling $MPLAYER_SOURCE"

cd $MPLAYER_SOURCE

if test -f Makefile; then
    make distclean &> /dev/null
fi

./configure --cc=$CC --host-cc=$BUILD_CC --as=$AS \
--enable-static --enable-fbdev --enable-cross-compile \
--prefix=/usr --target=$TARGET \
--disable-win32dll --disable-dvdread --disable-mencoder --disable-live \
--disable-libavcodec_so --enable-mad --disable-mp3lib --disable-x11 \
--enable-faad-internal --enable-faad-fixed --disable-ivtv --disable-gcc-check
#perl -i.bak -pe 's/(EXTRA_INC) \=(.*)/$1 \=/' config.mak
perl -i -pe 's/(EXTRA_INC) \=(.*)/$1 \=/' config.mak
perl -i -pe 's/(EXTRAXX_INC) \=(.*)/$1 \=/' config.mak
#sed -i 's/\(INSTALLSTRIP = -s\)/\1 --strip-program=nds32le-linux-strip/' config.mak
sed -i 's/INSTALLSTRIP = -s/INSTALLSTRIP =/g' config.mak
make all 2> ${LOG_DIR}/${MPLAYER_SOURCE}_error.log| tee ${LOG_DIR}/${MPLAYER_SOURCE}_make.log
make install DESTDIR=${DEPLOY_DIR} 2>&1 | tee ${LOG_DIR}/${MPLAYER_SOURCE}_install.log
${CROSS_COMPILE}strip ${DEPLOY_DIR}/usr/bin/mplayer

cp ${DEPLOY_DIR}/usr/bin/mplayer ${DEMO}/

cd ..
}

build_libmad
build_mplayer

