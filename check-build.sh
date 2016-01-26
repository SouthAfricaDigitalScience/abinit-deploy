#!/bin/bash -e
# check-build script for abinit
. /etc/profile.d/modules.sh

# We provide the base module which all jobs need to get their environment on the build slaves
module add ci
module add gsl
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add netcdf/4.3.2-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}/tests
./runtests.py -n2

echo "tests have passed, now doing install"
make install
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
make install

echo "installation complete, now making module file"

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
setenv ABINIT_DIR /apprepo/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/${VERSION}/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}
setenv ABINIT_ROOT $::env(ABINIT_DIR)
setenv CFLAGS "$CFLAGS -I$::env(ABINIT_DIR)/include -L$::env(ABINIT_DIR)/lib"
prepend-path CPATH $::env(ABINIT_DIR)/include
prepend-path LD_LIBRARY_PATH $::env(ABINIT_DIR)
MODULE_FILE
) > modules/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
mkdir -p ${CHEMISTRY_MODULES}/${NAME}
cp modules/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION} ${CHEMISTRY_MODULES}/${NAME}
