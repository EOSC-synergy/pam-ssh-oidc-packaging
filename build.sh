#!/bin/bash

### Build using:

#DIST=ubuntu_bionic ; docker run -it --rm -v `dirname $PWD`:/home/build $DIST /home/build/`basename $PWD`/build.sh `basename $PWD` $DIST

## ASSUMPTION: /home/build/$PACKAGE holds the sources for the package to be built
## ASSUMPTION: /home/build is on the host system.

BASE="/home/build"
PACKAGE=$1
DIST=$2
OUTPUT="$BASE/results"

echo "PACKAGE: $PACKAGE"
echo "DIST: $DIST"

test -z $DIST && {
    echo "Must specify DIST as 2nd parameter"
    exit
}

debian_install_dependencies() {
    apt-get update
    apt-get -y install libpam0g-dev libcurl4-openssl-dev libaudit-dev
}
ubuntu_bionic_install_dependencies() {
    echo " deb http://security.ubuntu.com/ubuntu/ focal-security main restricted" >> /etc/apt/sources.list
    apt-get update
}
    
debian_build_package() {
    make debsource && \
    dpkg-buildpackage -uc -us
}

debian_copy_output() {
    echo "Moving output:"
    ls -l ..
    mv ../${PACKAGE}_* $OUTPUT/$DIST
    mv ../${PACKAGE}-dbgsym_* $OUTPUT/$DIST 2>/dev/null
}

common_prepare_dirs() {
    mkdir -p /tmp/build
    mkdir -p $OUTPUT/$DIST
    cp -af $BASE/$PACKAGE /tmp/build
    cd /tmp/build/$PACKAGE 
}

#centos8_install_libcurl-devel() {
#    yum -y install git openssl-devel
#    mkdir -p /tmp/curl
#    cd /tmp/curl
#    git clone https://github.com/curl/curl.git
#    cd curl
#    git checkout curl-7_75_0
#    autoreconf -fi
#    #./configure --with-openssl
#    ./configure --with-openssl --with-ssl --with-zlib --with-gssapi --with-nghttp2 --with-ngtcp2 --with-quiche
#    make
#    make install
#}
centos8_install_dependencies () {
    dnf -y group install "Development Tools"
    yum install -y gcc gcc-c++ libcurl-devel pam-devel audit-libs-devel
    #centos8_install_libcurl-devel
    #libpam0g-dev libcurl4-openssl-dev libaudit-dev
}
#rpm_prepare_dirs() {
#    mkdir -p rpm/rpmbuild/SOURCES
#    # FIXME: location and name of tarball is only known in Makefile
#    cp -afxx v$(SRC_TAR) rpm/rpmbuild/SOURCES/
#}
rpm_build_package() {
    cd /tmp/build/$PACKAGE 
    make srctar
    make rpm
}
rpm_copy_output() {
    ls -lrpm/rpmbuild/RPMS/*/*
    echo "-----"
    mv rpm/rpmbuild/RPMS/x86_64/${PACKAGE}*rpm $OUTPUT/$DIST .
}
    
###########################################################################
common_prepare_dirs

case "$DIST" in
    debian_buster|debian_bullseye|ubuntu_focal)
        debian_install_dependencies
        debian_build_package
        debian_copy_output
    ;;
    ubuntu_bionic)
        debian_install_dependencies
        ubuntu_bionic_install_dependencies
        debian_build_package
        debian_copy_output
    ;;
centos8)
        #rpm_prepare_dirs
        centos8_install_dependencies
        rpm_build_package
        rpm_copy_output
esac


