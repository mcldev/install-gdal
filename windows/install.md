# Install on Windows

## PyCURL
 https://stackoverflow.com/questions/28287446/having-trouble-installing-pycurl-on-windows/58847770#58847770


## Django
Follow the notes on Django for GIS install:
https://docs.djangoproject.com/en/3.2/ref/contrib/gis/install/geolibs/

1. Find max version of GDAL from the table **THAT is available from BOTH sources below**:
   - Django 3.2 supports GDAL 	3.2*not yet*, 3.1, 3.0, 2.4, 2.3, 2.2, 2.1, 2.0
   - e.g. `3.1.4`
    
2. Install matching of GDAL (for windows) from:
   - https://trac.osgeo.org/osgeo4w/
   - Set PATH and other paths as per Django instructions
   OR
   - https://www.gisinternals.com/release.php
   - Set PATH as per the installer (i.e. c:\programs\gdal\proj etc)

3. Install matching version of GDAL for Python from:
   - https://www.lfd.uci.edu/~gohlke/pythonlibs/#gdal
   - Remove `PROJ_LIB` and `GDAL_LIB` from the path settings 
   - Python will find automatically in site-packages directory
   
## Django Contrib GIS
Django 3.2.3+ can support GDAL 3.2 - see here: 
   https://docs.djangoproject.com/en/3.2/ref/contrib/gis/install/geolibs/

