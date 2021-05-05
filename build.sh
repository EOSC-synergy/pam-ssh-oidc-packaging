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
echo "OUTPUT: $OUTPUT"

test -z $DIST && {
    echo "Must specify DIST as 2nd parameter"
    exit
}

common_prepare_dirs() {
    mkdir -p /tmp/build
    mkdir -p $OUTPUT/$DIST
    cp -af $BASE/$PACKAGE /tmp/build
    cd /tmp/build/$PACKAGE 
}
common_fix_output_permissions() {
    UP_UID=`stat -c '%u' $BASE`
    UP_GID=`stat -c '%g' $BASE`
    chown $UP_UID:$UP_GID $OUTPUT
    chown -R $UP_UID:$UP_GID $OUTPUT/$DIST
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
    mv ../${PACKAGE}[_-]* $OUTPUT/$DIST
    #mv ../${PACKAGE}-dbgsym_* $OUTPUT/$DIST 2>/dev/null
}

centos7_install_dependencies () {
    yum -y install centos-release-scl
    yum -y install devtoolset-7-gcc*
    yum -y install libcurl-devel pam-devel audit-libs-devel
}
centos7_patch_gcc_requirement () {
    # This is a workaround for rpmbuild vs devtoolset:
    # rpmbuild will not notice the actual version used by the system,
    # hence we reduce the required version of gcc, and rely on the newer
    # one actually being used.
    sed s/"BuildRequires: cpp >= 6"/"BuildRequires: cpp >= 4"/ -i rpm/pam-ssh-oidc.spec
    # Be futre proof :)
    sed s/"BuildRequires: cpp >= 7"/"BuildRequires: cpp >= 4"/ -i rpm/pam-ssh-oidc.spec
}
centos8_install_dependencies () {
    dnf -y group install "Development Tools"
    yum -y install libcurl-devel pam-devel audit-libs-devel
}
opensuse15_install_dependencies() {
    zypper -n install libcurl-devel pam-devel zypper audit-devel git
}
centos7_build_package() {
    cd /tmp/build/$PACKAGE 
    make srctar
    echo make rpms | scl enable devtoolset-7 - 
}
rpm_build_package() {
    make srctar
    make rpms
}
rpm_copy_output() {
    ls -l rpm/rpmbuild/RPMS/*/*
    ls -l rpm/rpmbuild/SRPMS/
    echo "-----"
    mv rpm/rpmbuild/RPMS/x86_64/${PACKAGE}*rpm $OUTPUT/$DIST
    mv rpm/rpmbuild/SRPMS/*rpm $OUTPUT/$DIST
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
    centos7)
        centos7_install_dependencies
        centos7_patch_gcc_requirement
        centos7_build_package
        centos7_build_srpm
        rpm_copy_output
    ;;
    centos8)
        centos8_install_dependencies
        rpm_build_package
        rpm_copy_output
    ;;
    opensuse15*|opensuse_tumbleweed|sle*)
        opensuse15_install_dependencies
        rpm_build_package
        rpm_copy_output
    ;;
esac

common_fix_output_permissions
