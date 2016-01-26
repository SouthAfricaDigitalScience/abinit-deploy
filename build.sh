#!/bin/bash -e
# build script for abinit
. /etc/profile.d/modules.sh
SOURCE_FILE=$NAME-$VERSION.tar.gz

# We provide the base module which all jobs need to get their environment on the build slaves
module add ci
module add gsl
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add fftw/fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add netcdf/4.3.2-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

# Next, a bit of verbose description of the build environment. This is useful when debugging initial builds and you
# may want to remove it later.

# this tells you the main variables you can use which are set by the ci module
echo "REPO_DIR is "
echo $REPO_DIR
echo "SRC_DIR is "
echo $SRC_DIR
echo "WORKSPACE is "
echo $WORKSPACE
echo "SOFT_DIR is"
echo $SOFT_DIR


# In order to get started, we need to ensure that the following directories are available

# Workspace is the "home" directory of jenkins into which the project itself will be created and built.
mkdir -p $WORKSPACE
# SRC_DIR is the local directory to which all of the source code tarballs are downloaded. We cache them locally.
mkdir -p $SRC_DIR
# SOFT_DIR is the directory into which the application will be "installed"
mkdir -p $SOFT_DIR

#  Download the source file if it's not available locally.
#  we were originally using ncurses as the test application
if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "tarball's not here ! let's get it"
# use local mirrors if you can. Remember - UFS has to pay for the bandwidth!
  wget http://ftp.abinit.org/$NAME-$VERSION.tar.gz -O $SRC_DIR/$SOURCE_FILE
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi

# now unpack it into the workspace
tar -xvzf ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE} --skip-old-files

#  generally tarballs will unpack into the NAME-VERSION directory structure. If this is not the case for your application
#  ie, if it unpacks into a different default directory, either use the relevant tar commands, or change
#  the next lines

# We will be running configure and make in this directory
mkdir -p ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
# Note that $SOFT_DIR is used as the target installation directory.
../configure \
--prefix=${SOFT_DIR}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION} \
--enable-mpi \
--enable-mpi-io \
--enable-openmp \
--with-mpi-prefix=${OPENMPI_DIR} \
--with-fft-flavor="fftw3" \
--with-fft-incs="-I${FFTW_DIR}/include" \
--with-fft-libs="-L${FFTW_DIR}/lib -lfftw3 -lfftw3f -lfftw3f_omp -lfftw3_mpi" \
--with-linalg-flavour="netlib" \
--with-linalg-incs="-I${LAPACK_DIR}/include" \
--with-linalg-libs="-L${LAPACK_DIR}/lib -lblas -llapack" \
--enable-netcdf=yes \
--with-netcdf-incs="-I${NETCDF_DIR}/include" \
--with-netcdf-libs="-L${NETCDF_DIR}/lib -lnetcdf" \
--with-math-flavour="gsl" \
--with-math-incs="-I${GSL_DIR}/include" \
--with-math-libs="-L${GSL_DIR}/lib -lgsl"

# The build nodes have 8 core jobs. jobs are blocking, which means you can build with at least 8 core parallelism.
# this might cause instability in the builds, so it's up to you.
nice -n20 make -j2
