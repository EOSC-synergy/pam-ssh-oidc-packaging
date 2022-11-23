PKG_NAME  = pam-ssh-oidc
PKG_NAME_UPSTREAM = pam-ssh-oidc

SPECFILE := rpm/${PKG_NAME}.spec
#RPM_VERSION := $(shell grep ^Version ${SPECFILE} | cut -d : -f 2 | sed s/\ //g)

BASE_VERSION := $(shell head debian/changelog  -n 1 | cut -d \( -f 2 | cut -d \) -f 1 | cut -d \- -f 1)
DEBIAN_VERSION := $(shell head debian/changelog  -n 1 | cut -d \( -f 2 | cut -d \) -f 1 | sed s/-[0-9][0-9]*//)
RPM_VERSION := $(DEBIAN_VERSION)
VERSION := $(DEBIAN_VERSION)
BASE_VERSION := $(shell head debian/changelog  -n 1 | cut -d \( -f 2 | cut -d \) -f 1 | cut -d \- -f 1)


# Parallel builds:
MAKEFLAGS += -j9

BASEDIR = $(PWD)
BASENAME := $(notdir $(PWD))
DOCKER_BASE=`dirname ${PWD}`
PACKAGE=`basename ${PWD}`
SRC_TAR:=$(PKG_NAME).tar.gz

PKG_NAME_AC:=pam-ssh-oidc-autoconfig
SRC_TAR_AC:=$(PKG_NAME_AC).tar.gz

SHELL=bash

### Actual targets
SUBDIRS = pam-password-token
CLEANDIRS = $(SUBDIRS)


all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

INSTALLDIRS = $(SUBDIRS:%=install-%)

install: $(INSTALLDIRS)
$(INSTALLDIRS):
	$(MAKE) -C $(@:install-%=%) install

CLEANDIRS = $(SUBDIRS:%=clean-%)

clean: $(CLEANDIRS)
$(CLEANDIRS):
	@if [ -d $(@:clean-%=%) ]; then \
		$(MAKE) -C $(@:clean-%=%) clean; \
	fi

distclean: clean
	rm -rf rpm/rpmbuild

package-clean:
	@echo PACKAGE_CLEAN
	quilt pop -a -f || true
	./debian/rules clean
	rm -rf common pam-password-token jsmn-web-tokens .patched .pc

.PHONY: subdirs $(INSTALLDIRS)
.PHONY: subdirs $(SUBDIRS)
.PHONY: subdirs $(CLEANDIRS)
.PHONY: all install clean

### pam-oidc source code handling targets
get-sources:
	@echo GET-SOURCES
	git clone https://git.man.poznan.pl/stash/scm/pracelab/pam.git upstream -b develop
	# the (broken) master was using  2730181aa31
	(cd upstream; git checkout 2b253ede076)
	mv upstream/common upstream/pam-password-token upstream/jsmn-web-tokens .
	ls -la common
	ls -la jsmn-web-tokens
	ls -la pam-password-token
	rm -rf upstream
	rm -f .patched

info:
	@echo "DESTDIR:         $(DESTDIR)"
	@echo "INSTALLDIRS:     $(INSTALLDIRS)"
	@echo "VERSION:         $(VERSION)"
	@echo "RPM_VERSION:     $(RPM_VERSION)"
	@echo "DEBIAN_VERSION:  $(DEBIAN_VERSION)"
	@echo "BASE_VERSION:    ${BASE_VERSION}"

### Dockers
dockerised_most_packages: dockerised_deb_debian_buster\
	dockerised_rpm_centos7\
	dockerised_rpm_centos8\
	dockerised_rpm_opensuse_tumbleweed

dockerised_all_packages: dockerised_deb_debian_buster\
	dockerised_deb_debian_bullseye\
	dockerised_deb_ubuntu_bionic\
	dockerised_deb_ubuntu_focal\
	dockerised_rpm_centos7\
	dockerised_rpm_centos8\
	dockerised_rpm_opensuse15.2\
	dockerised_rpm_opensuse15.3\
	dockerised_rpm_opensuse_tumbleweed

.PHONY: docker_images
docker_images: docker_centos8\
	docker_centos7\
	docker_debian_bullseye\
	docker_debian_buster\
	docker_ubuntu_bionic\
	docker_ubuntu_focal\
	docker_opensuse15.2\
	docker_opensuse15.3\
	docker_opensuse_tumbleweed

.PHONY: docker_debian_buster
docker_debian_buster:
	@echo -e "\ndebian_buster"
	@echo -e "FROM debian:buster\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv dh-virtualenv python3-venv devscripts git "\
    	"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag debian_buster -f - .  >> docker.log
.PHONY: docker_debian_bullseye
docker_debian_bullseye:
	@echo -e "\ndebian_bullseye"
	@echo -e "FROM debian:bullseye\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv dh-virtualenv python3-venv devscripts git "\
		"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag debian_bullseye -f - .  >> docker.log
.PHONY: docker_ubuntu_bionic
docker_ubuntu_bionic:
	@echo -e "\nubuntu_bionic"
	@echo -e "FROM ubuntu:bionic\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv dh-virtualenv python3-venv devscripts git "\
		"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag ubuntu_bionic -f - .  >> docker.log
.PHONY: docker_ubuntu_focal
docker_ubuntu_focal:
	@echo -e "\nubuntu_focal"
	@echo -e "FROM ubuntu:focal\n"\
	"ENV DEBIAN_FRONTEND=noninteractive\n"\
	"ENV  TZ=Europe/Berlin\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv python3-venv devscripts git "\
		"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag ubuntu_focal -f - .  >> docker.log
.PHONY: docker_centos7
docker_centos7:
	@echo -e "\ncentos7"
	@echo -e "FROM centos:7\n"\
	"RUN yum -y install make rpm-build\n"\
	"RUN yum -y groups mark convert\n"\
	"RUN yum -y groupinstall \"Development tools\"\n" | \
	docker build --tag centos7 -f - .  >> docker.log
.PHONY: docker_centos8
docker_centos8:
	@echo -e "\ncentos8"
	@echo -e "FROM centos:8\n"\
	"RUN yum install -y make rpm-build\n" \
	"RUN dnf -y group install \"Development Tools\"\n" | \
	docker build --tag centos8 -f -  .  >> docker.log
.PHONY: docker_opensuse15.2
docker_opensuse15.2:
	@echo -e "\nopensuse-15.2"
	@echo -e "FROM registry.opensuse.org/opensuse/leap:15.2\n"\
	"RUN zypper -n install make rpm-build\n" \
	"RUN zypper -n install -t pattern devel_C_C++" | \
	docker build --tag opensuse15.2 -f -  .  >> docker.log
.PHONY: docker_opensuse15.3
docker_opensuse15.3:
	@echo -e "\nopensuse-15.3"
	@echo -e "FROM registry.opensuse.org/opensuse/leap:15.3\n"\
	"RUN zypper -n install make rpm-build\n" \
	"RUN zypper -n install -t pattern devel_C_C++" | \
	docker build --tag opensuse15.3 -f -  .  >> docker.log
.PHONY: docker_opensuse_tumbleweed
docker_opensuse_tumbleweed:
	@echo -e "\nopensuse_tumbleweed"
	@echo -e "FROM registry.opensuse.org/opensuse/tumbleweed:latest\n"\
	"RUN zypper -n install make rpm-build\n" \
	"RUN zypper -n install -t pattern devel_C_C++" | \
	docker build --tag opensuse_tumbleweed -f -  .  >> docker.log
.PHONY: docker_sle15
docker_sle15:
	@echo -e "\nsle15"
	@echo -e "FROM registry.suse.com/suse/sle15\n"\
	"RUN zypper -n install make rpm-build\n" \
	"RUN zypper -n install -t pattern devel_C_C++" | \
	docker build --tag sle15 -f -  .  >> docker.log

.PHONY: docker_clean
docker_clean:
	docker image rm sle15 || true
	docker image rm	opensuse_tumbleweed || true
	docker image rm opensuse15.2 || true
	docker image rm	opensuse15.3 || true
	docker image rm centos8 || true
	docker image rm	centos7 || true
	docker image rm ubuntu_bionic || true
	docker image rm	ubuntu_focal || true
	docker image rm debian_buster || true
	docker image rm	debian_bullseye || true

.PHONY: dockerised_deb_debian_buster
dockerised_deb_debian_buster: docker_debian_buster
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build debian_buster \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} debian_buster ${PKG_NAME} > $@.log

.PHONY: dockerised_deb_debian_bullseye
dockerised_deb_debian_bullseye: docker_debian_bullseye
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build debian_bullseye \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} debian_bullseye ${PKG_NAME} > $@.log

.PHONY: dockerised_deb_ubuntu_bionic
dockerised_deb_ubuntu_bionic: docker_ubuntu_bionic
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build ubuntu_bionic \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} ubuntu_bionic ${PKG_NAME} > $@.log

.PHONY: dockerised_deb_ubuntu_focal
dockerised_deb_ubuntu_focal: docker_ubuntu_focal
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build ubuntu_focal \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} ubuntu_focal ${PKG_NAME} > $@.log

.PHONY: dockerised_rpm_centos7
dockerised_rpm_centos7: docker_centos7
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build centos7 \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} centos7 ${PKG_NAME} > $@.log

.PHONY: dockerised_rpm_centos8
dockerised_rpm_centos8: docker_centos8
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build centos8 \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} centos8 ${PKG_NAME} > $@.log

.PHONY: dockerised_rpm_opensuse15.2
dockerised_rpm_opensuse15.2: docker_opensuse15.2
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build opensuse15.2 \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} opensuse15.2 ${PKG_NAME} > $@.log

.PHONY: dockerised_rpm_opensuse15.3
dockerised_rpm_opensuse15.3: docker_opensuse15.3
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build opensuse15.3 \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} opensuse15.3 ${PKG_NAME} > $@.log

.PHONY: dockerised_rpm_opensuse_tumbleweed
dockerised_rpm_opensuse_tumbleweed: docker_opensuse_tumbleweed
	@echo "Writing build log to $@.log"
	@docker run --tty --rm -v ${DOCKER_BASE}:/home/build opensuse_tumbleweed \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} opensuse_tumbleweed ${PKG_NAME} > $@.log

# Debian Packaging

.PHONY: preparedeb
preparedeb: clean
	@quilt pop -a || true
	#@debian/rules clean
	( cd ..; tar czf ${PKG_NAME}_${VERSION}.orig.tar.gz --exclude-vcs --exclude=debian --exclude=.pc ${PKG_NAME_UPSTREAM})

.PHONY: debsource
debsource: clean preparedeb
	dpkg-source -b .

.PHONY: deb
deb: cleanapi create_obj_dir_structure preparedeb
	dpkg-buildpackage -i -b -uc -us
	@echo "Success: DEBs are in parent directory"

# RPM Packaging

.PHONY: patch-for-rpm
patch-for-rpm:
	@if [ -e ".patched" ]; then \
		echo "Patches already applied"; \
	else \
		echo "Applying patches"; \
		for i in `cat rpm/patches/series | grep -v "^#"`; do \
			echo Applying patch: $$i; \
			cat rpm/patches/$$i | patch -p1; \
		done; \
    fi
	@touch .patched
	#find rpm
.PHONY: unpatch-for-rpm
unpatch-for-rpm:
	@if [ -e ".patched" ]; then \
		echo "Removing patches"; \
		for i in `cat rpm/patches/series | grep -v "^#" | tac`; do \
			echo Reverting patch: $$i; \
			cat rpm/patches/$$i | patch -p1 -R; \
		done; \
		rm .patched; \
	else \
		echo "Patches already removed"; \
	fi

.PHONY: srctar
srctar: patch-for-rpm
	mkdir -p rpm/rpmbuild/SOURCES

	@(cd ..; tar czf $(SRC_TAR) --exclude-vcs --exclude=.pc --exclude $(PGK_NAME)/config $(PKG_NAME) --transform='s%${PKG_NAME}%${PKG_NAME}-$(BASE_VERSION)%')
	mv ../$(SRC_TAR) rpm/rpmbuild/SOURCES

	@(cd ..; tar czf $(SRC_TAR_AC) $(PKG_NAME)/documentation/README-autoconfig.md $(PKG_NAME)/config/pam.d-sshd-suse --transform='s%${PKG_NAME}%${PKG_NAME_AC}-$(BASE_VERSION)%')
	mv ../$(SRC_TAR_AC) rpm/rpmbuild/SOURCES

.PHONY: rpms
rpms: srpm rpm 

.PHONY: rpm
rpm: srctar
	#find rpm
	rpmbuild --define "_topdir ${PWD}/rpm/rpmbuild" -bb  rpm/${PKG_NAME}.spec
	#find rpm
	rpmbuild --define "_topdir ${PWD}/rpm/rpmbuild" -bb  rpm/${PKG_NAME}-autoconfig.spec
	#find rpm

.PHONY: srpm
srpm: srctar
	rpmbuild --define "_topdir ${PWD}/rpm/rpmbuild" -bs  rpm/${PKG_NAME}.spec
	rpmbuild --define "_topdir ${PWD}/rpm/rpmbuild" -bs  rpm/${PKG_NAME}-autoconfig.spec


