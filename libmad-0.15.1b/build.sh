#!/bin/sh


export CROSS_COMPILE="riscv64-linux-" 
export HOST=${CROSS_COMPILE%-} 
export DEPLOY_DIR=${WORKDIR}/RISCV64

LIBMAD_SOURCE=libmad-0.15.1b 

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

build_libmad
