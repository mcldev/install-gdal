# Compile and Install GDAL
From these:
- https://gist.github.com/mojodna/2f596ca2fca48f08438e#gistcomment-3137909
- https://gist.github.com/hervenivon/fe3a327bc28b142e51beb38ef11844c0
- https://gist.github.com/abelcallejo/e75eb93d73db6f163b076d0232fc7d7e

## AWS Commands:


[1] Create a script install-gdal.sh:
```shell
#!/bin/bash

# Installation of GDAL and dependencies.
# Based on https://gist.github.com/hervenivon/fe3a327bc28b142e51beb38ef11844c0

export PYTHON_VERSION=3.8.7
export PYTHON_SHORT_VERSION=3.8
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


# Compiltation worf for proj
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
pip${PYTHON_SHORT_VERSION} install /tmp/GDAL-${GDAL_VERSION}-cp38-cp38-linux_x86_64.whl --force-reinstall
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

```

[2] Run the script on an EC2 instance (takes a long time) after which you should have the three bundled files available:
```
/tmp/geos-3.9.0.tar.gz
/tmp/proj-6.2.1.tar.gz
/tmp/gdal-3.1.4.tar.gz
```

[3] Upload these to your S3 bucket.

[4] Add the following variables to Beanstalk Config - only need to change here to reflect above builds.
```yaml
OptionSettings:
  aws:elasticbeanstalk:application:environment:
    INSTALL_BUCKET_NAME: jomopans-build-files
    INSTALL_PROJ_VER: 6.2.1
    INSTALL_GEOS_VER: 3.9.0
    INSTALL_GDAL_VER: 3.1.4
```

[5] Add the following to your .ebextensions. Each command tests for the existence of the directory on your instance and downloads and unzips the source as needed.

```yaml
commands:
  01_install_geos:
    command: |
      sudo aws s3 cp s3://${INSTALL_BUCKET_NAME}/geos-${INSTALL_GEOS_VER}.tar.gz /tmp/geos-${INSTALL_GEOS_VER}.tar.gz
      sudo mkdir -p /usr/local/geos
      sudo tar -xvf /tmp/geos-${INSTALL_GEOS_VER}.tar.gz -C /usr/local/geos
      sudo rm -f /tmp/geos-${INSTALL_GEOS_VER}.tar.gz
    test: "[ ! -d /usr/local/geos ]"
    env:
      INSTALL_BUCKET_NAME:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: INSTALL_BUCKET_NAME
      INSTALL_GEOS_VER:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: INSTALL_GEOS_VER

  02_install_proj:
    command: |
      sudo aws s3 cp s3://${INSTALL_BUCKET_NAME}/proj-${INSTALL_PROJ_VER}.tar.gz /tmp/proj-${INSTALL_PROJ_VER}.tar.gz
      sudo mkdir -p /usr/local/proj
      sudo tar -xvf /tmp/proj-${INSTALL_PROJ_VER}.tar.gz -C /usr/local/proj4
      sudo rm -f /tmp/proj-${INSTALL_PROJ_VER}.tar.gz
    test: "[ ! -d /usr/local/proj ]"
    env:
      INSTALL_BUCKET_NAME:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: INSTALL_BUCKET_NAME
      INSTALL_PROJ_VER:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: INSTALL_PROJ_VER

  03_install_gdal:
    command: |
      sudo aws s3 cp s3://${INSTALL_BUCKET_NAME}/gdal-${INSTALL_GDAL_VER}.tar.gz /tmp/gdal-${INSTALL_GDAL_VER}.tar.gz
      sudo mkdir -p /usr/local/gdal
      sudo tar -xvf /tmp/gdal-${INSTALL_GDAL_VER}.tar.gz -C /usr/local/gdal
      sudo rm -f /tmp/gdal-${INSTALL_GDAL_VER}.tar.gz
    test: "[ ! -d /usr/local/gdal ]"
    env:
      INSTALL_BUCKET_NAME:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: INSTALL_BUCKET_NAME
      INSTALL_GDAL_VER:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: INSTALL_GDAL_VER

```

[5] Finally, add the following to your .ebextensions/options.config file:
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    PATH: /usr/local/gdal/bin:$PATH
    LD_LIBRARY_PATH: /usr/local/proj/lib:/usr/local/geos/lib:/usr/local/gdal/lib:$LD_LIBRARY_PATH
    GDAL_DATA: /usr/local/gdal/share/gdal
    # GDAL_LIBRARY_PATH: /usr/local/gdal/lib/libgdal.so  # possible fix
```
Seems like a lot of steps now that I've typed it all out but it has been working reliably for me on EB running Python 3.6 running on 64bit Amazon Linux/2.9.4. Seems much cleaner than bundling the entire /usr/local directory too.
