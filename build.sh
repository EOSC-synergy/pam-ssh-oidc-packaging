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
    apt-get -y install libpam0g-dev libcurl4-openssl-dev
    }
debian_build_package() {
    make debsource && \
    dpkg-buildpackage -uc -us
}

debian_copy_output() {
    echo "Moving output:"
    ls -l ..
    mv ../pam-ssh_* $OUTPUT/$DIST
    mv ../pam-ssh-dbgsym_* $OUTPUT/$DIST
}

mkdir -p /tmp/build
mkdir -p $OUTPUT/$DIST
cp -af $BASE/$PACKAGE /tmp/build
cd /tmp/build/$PACKAGE 

case "$DIST" in
    debian_buster|debian_bullseye|ubuntu_bionic)
        debian_install_dependencies
        debian_build_package
        debian_copy_output
    ;;
    ubuntu_focal)   
        debian_install_dependencies
        debian_build_package
        debian_copy_output
    ;;
esac



