#!/bin/bash -e
# build script for abinit
. /etc/profile.d/modules.sh

# We provide the base module which all jobs need to get their environment on the build slaves
module add deploy
module add gsl
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add fftw/fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add netcdf/4.3.2-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
rm -rf *
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

nice -n20 make install

echo "install finished, now making the module"
mkdir -p modules
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
  puts stderr "\\tAdds $NAME ($VERSION.) to your environment."
}
module-whatis "Sets the environment for using $NAME ($VERSION.) Built with GCC ${GCC_VERSION} and OpenMPI Version ${OPENMPI_VERSION}"
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add gsl
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add netcdf/4.3.2-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
setenv ABINIT_VERSION $VERSION
setenv ABINIT_DIR $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/${VERSION}/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}
setenv ABINIT_ROOT $::env(ABINIT_DIR)
setenv CFLAGS "$CFLAGS -I$::env(ABINIT_DIR)/include -L$::env(ABINIT_DIR)/lib"
prepend-path CPATH $::env(ABINIT_DIR)/include
prepend-path LD_LIBRARY_PATH $::env(ABINIT_DIR)
MODULE_FILE
) > modules/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
mkdir -p ${CHEMISTRY_MODULES}/${NAME}
cp modules/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION} ${CHEMISTRY_MODULES}/${NAME}
