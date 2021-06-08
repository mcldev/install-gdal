# Install GDAL

An attempt to keep a 'working' repository of installing GDAL on Amazon Linux 2 and Windows with Python libraries.


## GDAL and Python
There are two python wrappers for accessing GDAL C library functions.

1. `django.contrib.gis` the built in django wrapper for basic access to GDAL.
   - **Only** installs the Python bindings as `django.contrib.gis.gdal`
   - Requires GDAL libraries to be installed separately on the system 
   - It is only a simple version of the full GDAL libary
   >GeoDjango provides a high-level Python interface for some of the capabilities of OGR, including the reading and coordinate transformation of vector spatial data and minimal support for GDAL’s features with respect to raster (image) data.

2. `osgeo` (installed as `pip install gdal==3.1.4`) installs the OSGeo wrapper and GDAL libraries
   - Installs and builds **BOTH** Python bindings **AND** GDAL Libraries
   - GDAL Libraries are installed to the python env site-packages gdal directory
   - OSGeo will use these local library files
   - `django.contrib.gis` will **NOT** use these library files

