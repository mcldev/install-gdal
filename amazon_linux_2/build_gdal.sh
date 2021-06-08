#!/bin/bash

# Installation of GDAL and dependencies.
# Based on https://gist.github.com/hervenivon/fe3a327bc28b142e51beb38ef11844c0

export PYTHON_SHORT_VERSION=3.8
export PYTHON_SHORT_VERSION_WHL=38
export GEOS_VERSION=3.9.0
export PROJ_VERSION=6.1.1
export GDAL_VERSION=3.1.4
# Be careful not to install PROJ version 6.2.0 or newer
# because the one from the yum packages is only SQLite version 3.7.17.

yum-config-manager --enable epel
yum install -y make cmake3 automake gcc gcc-c++ cpp libcurl-devel sqlite-devel libtiff bzip2 numpy

# Remove Existing Builds
rm -f /tmp/geos-${GEOS_VERSION}.tar.gz
rm -f /tmp/proj-${PROJ_VERSION}.tar.gz
rm -f /tmp/gdal-${INSTALL_GDAL_VER}.tar.gz

rm -r /usr/local/geos
rm -r /usr/local/proj
rm -r /usr/local/gdal

rm -r /tmp/geos*
rm -r /tmp/proj*
rm -r /tmp/gdal*

# Compilation work for geos
mkdir -p "/tmp/geos-${GEOS_VERSION}-build"
cd "/tmp/geos-${GEOS_VERSION}-build"
curl -o "geos-${GEOS_VERSION}.tar.bz2" \
    "http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2" \
    && bunzip2 "geos-${GEOS_VERSION}.tar.bz2" \
    && tar xvf "geos-${GEOS_VERSION}.tar"
cd "/tmp/geos-${GEOS_VERSION}-build/geos-${GEOS_VERSION}"
./configure --prefix=/usr/local/geos

# Make in parallel with 2x the number of processors.
make -j $(( 2 * $(cat /proc/cpuinfo | egrep ^processor | wc -l) )) \
 && make install \
 && ldconfig

# Compiltation work for proj
mkdir -p "/tmp/proj-${PROJ_VERSION}-build"
cd "/tmp/proj-${PROJ_VERSION}-build"
curl -o "proj-${PROJ_VERSION}.tar.gz" \
    "http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz" \
    && tar xfz "proj-${PROJ_VERSION}.tar.gz"
cd "/tmp/proj-${PROJ_VERSION}-build/proj-${PROJ_VERSION}"
./configure --prefix=/usr/local/proj

# Make in parallel with 2x the number of processors.
make -j $(( 2 * $(cat /proc/cpuinfo | egrep ^processor | wc -l) )) \
 && make install \
 && ldconfig

# Compilation work for GDAL
pip${PYTHON_SHORT_VERSION} install numpy

mkdir -p "/tmp/gdal-${GDAL_VERSION}-build"
cd "/tmp/gdal-${GDAL_VERSION}-build"
curl -o "gdal-${GDAL_VERSION}.tar.gz" \
    "http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz" \
    && tar xfz "gdal-${GDAL_VERSION}.tar.gz"
cd "/tmp/gdal-${GDAL_VERSION}-build/gdal-${GDAL_VERSION}"
./configure --prefix=/usr/local/gdal \
            --with-curl=yes \
            --with-proj=/usr/local/proj \
            --without-python
            # With or Without Python... NFI.
            # --without-python
            # --with-python=python${PYTHON_SHORT_VERSION}

# Make in parallel with 2x the number of processors.
make -j $(( 2 * $(cat /proc/cpuinfo | egrep ^processor | wc -l) )) \
 && make install \
 && ldconfig

# Compile the GDAL Python with correct bindings
export GDAL_LIBRARY_PATH=/usr/local/gdal/lib/libgdal.so
export LD_LIBRARY_PATH=/usr/local/gdal/lib:$LD_LIBRARY_PATH
export PROJ_LIB=/usr/local/proj/share/proj
export GDAL_DATA=/usr/local/gdal/share/gdal
export PATH=/usr/local/gdal/bin:$PATH
ldconfig
echo "Check GDAL Version here:"
gdal-config --version

# Need to have Numpy installed to avoid _gdal_array errors
yum install -y numpy
pip${PYTHON_SHORT_VERSION} uninstall -y GDAL
pip${PYTHON_SHORT_VERSION} install numpy
pip${PYTHON_SHORT_VERSION} wheel GDAL==${GDAL_VERSION} -w /tmp
pip${PYTHON_SHORT_VERSION} install /tmp/GDAL-${GDAL_VERSION}-cp${PYTHON_SHORT_VERSION_WHL}-cp${PYTHON_SHORT_VERSION_WHL}-linux_x86_64.whl --force-reinstall
echo "Check Python GDAL Version and File here:"
python${PYTHON_SHORT_VERSION} -c 'import osgeo.gdal; print(osgeo.gdal.__version__); print(osgeo.gdal.__file__)'

# Bundle resources.
cd /usr/local/geos
tar zcvf "/tmp/geos-${GEOS_VERSION}.tar.gz" *

cd /usr/local/proj
tar zcvf "/tmp/proj-${PROJ_VERSION}.tar.gz" *

cd /usr/local/gdal
tar zcvf "/tmp/gdal-${GDAL_VERSION}.tar.gz" *

#And: /tmp/GDAL-${GDAL_VERSION}-cp38-cp38-linux_x86_64.whl
