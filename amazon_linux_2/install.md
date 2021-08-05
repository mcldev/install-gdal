# Compile and Install GDAL
From these:
- https://gist.github.com/mojodna/2f596ca2fca48f08438e#gistcomment-3137909
- https://gist.github.com/hervenivon/fe3a327bc28b142e51beb38ef11844c0
- https://gist.github.com/abelcallejo/e75eb93d73db6f163b076d0232fc7d7e

## Compile on Amazon Linux 2 on Windows
Use the link: https://aws.amazon.com/blogs/developer/developing-on-amazon-linux-2-using-windows/

Make sure AL2 is up to date:
```shell
yum install amazon-linux-extras
yum upgrade -y && yum update -y
amazon-linux-extras install -y kernel-ng
```

## Compile and build Commands:

[1] USe the script `build_gdal.sh` 

[2] Run the script on an EC2 instance or local Amazon Linux (e.g. WSL) after which you should have the 4 bundled files available:
```
/tmp/geos-3.9.0.tar.gz
/tmp/proj-6.1.1.tar.gz
/tmp/gdal-3.1.4.tar.gz
/tmp/GDAL-3.1.4-cp38-cp38-linux_x86_64.whl
```

[3] Upload these to your S3 bucket under `/gdal/*`.

[4] Add the following variables to Beanstalk Config - only need to change here to reflect above builds.
```yaml
OptionSettings:
  aws:elasticbeanstalk:application:environment:
    INSTALL_BUCKET_NAME: jomopans-build-files
    INSTALL_PROJ_VER: 6.2.1
    INSTALL_GEOS_VER: 3.9.0
    INSTALL_GDAL_VER: 3.1.4
```

[5] Add the `001_install_gdal.config` to your .ebextensions which will download and unzip the source files. It will also reinstall GDAL and Numpy.


[6] The file above will also add the following to your option_settings.
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    PATH: /usr/local/bin:$PATH
    LD_LIBRARY_PATH: /usr/local/lib:$LD_LIBRARY_PATH
    GDAL_LIBRARY_PATH: /usr/local/lib/libgdal.so
    PROJ_LIB: /usr/local/share/proj
    GDAL_DATA: /usr/local/share/gdal
```
[7] Remove GDAL from your `requirements.txt` (or similar) and only install via the config file.
