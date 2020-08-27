#!/bin/sh

## Enviroment Setting
WORKDIR=`pwd`
#export DEPLOY_DIR=${WORKDIR}/RISCV64
#export DEPLOY_DIR=${WORKDIR}/RISCV32
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
export TARGET=${CROSS_COMPILE}

# Andes Cross Toolchain settings
export CC=${CROSS_COMPILE}-gcc
export CXX=${CROSS_COMPILE}-g++
export AR=${CROSS_COMPILE}-ar
export AS=${CROSS_COMPILE}-as
export RANLIB=${CROSS_COMPILE}-ranlib
export LD=${CROSS_COMPILE}-ld
export STRIP=${CROSS_COMPILE}-strip

# Creat log folder if needs
if [ ! -d $LOG_DIR  ]; then
	echo "$LOG_DIR does not exist, now created."
	mkdir -p $LOG_DIR
fi

if [  ${CROSS_COMPILE} = "riscv64-linux"  ]; then
	mkdir -p ${WORKDIR}/RISCV64
	export	DEPLOY_DIR=${WORKDIR}/RISCV64
elif [  ${CROSS_COMPILE} = "riscv32-linux"  ]; then
	mkdir -p ${WORKDIR}/RISCV32
	export DEPLOY_DIR=${WORKDIR}/RISCV32
else
	echo " CROSS_COMPILE args not set !!"
	exit 1
fi

# Check -march args
if [ ${MARCH} = "rv32v5" ];then
	export MARCH=rv32v5
elif [ ${MARCH} = "rv32v5d" ];then
	export MARCH=rv32v5d
elif [ ${MARCH} = "rv64v5" ];then
	export MARCH=rv64v5
elif [ ${MARCH} = "rv64v5d" ];then
	export MARCH=rv64v5d
else
	echo " -march=rvXXv5X args not set !!"
fi

export CFLAGS="${OPTFLAGS} -I${DEPLOY_DIR}/usr/include -march=${MARCH}"
#export LDFLAGS="-L${DEPLOY_DIR}/usr/lib"
export LDFLAGS="-static -L${DEPLOY_DIR}/usr/lib -march=${MARCH}"

LIBALSA_SOURCE=alsa-lib-1.2.3.2
ALSA_UTILS_SOURCE=alsa-utils-1.2.3

build_alsa_lib()
{
echo
echo "Compiling $LIBALSA_SOURCE"

cd $LIBALSA_SOURCE

if test -f Makefile; then
    make distclean &> /dev/null
fi

./configure --target=${CROSS_COMPILE} --host=${CROSS_COMPILE} --build=${HOST_TYPE} --prefix=/usr --exec-prefix=/usr --sysconfdir=/etc --localstatedir=/var --program-prefix= --disable-dependency-tracking --disable-static --enable-shared --with-alsa-devdir=/dev/snd --with-pcm-plugins=all --with-ctl-plugins=all --without-versioned --enable-static=no --disable-python

make all 2> ${LOG_DIR}/${LIBALSA_SOURCE}_error.log| tee ${LOG_DIR}/${LIBALSA_SOURCE}_make.log
make install DESTDIR=${DEPLOY_DIR} 2>&1 | tee ${LOG_DIR}/${LIBALSA_SOURCE}_install.log

cd ..
}

build_alsa_utils()
{
echo
echo "Compiling $ALSA_UTILS_SOURCE"

cd $ALSA_UTILS_SOURCE

if test -f Makefile; then
    make distclean &> /dev/null
fi

./configure  --target=${CROSS_COMPILE} --host=${CROSS_COMPILE} \
--build=x86_64-pc-linux-gnu --prefix=/usr --exec-prefix=/usr --sysconfdir=/etc \
--localstatedir=/var --program-prefix= --disable-dependency-tracking --disable-nls \
--disable-static --enable-shared --disable-rst2man --with-curses=ncurses --disable-alsaloop \
--disable-bat --disable-alsamixer --disable-alsaconf --disable-alsaloop

make all 2> ${LOG_DIR}/${ALSA_UTILS_SOURCE}_error.log| tee ${LOG_DIR}/${ALSA_UTILS_SOURCE}_make.log
make install DESTDIR=${DEPLOY_DIR} 2>&1 | tee ${LOG_DIR}/${ALSA_UTILS_SOURCE}_install.log
#${CROSS_COMPILE}strip ${DEPLOY_DIR}/usr/bin/mplayer

#cp ${DEPLOY_DIR}/usr/bin/mplayer ${DEMO}/

cd ..
}

#build_alsa_lib
build_alsa_utils

