PKG_NAME  = pam-ssh-oidc
PKG_NAME_UPSTREAM = pam-ssh-oidc
VERSION := $(shell git tag -l  | tail -n 1 | sed s/v//)

BASEDIR = $(PWD)
BASENAME := $(notdir $(PWD))
DOCKER_BASE=`dirname ${PWD}`
PACKAGE=`basename ${PWD}`
SRC_TAR:=$(PKG_NAME).tar


### Actual targets
SUBDIRS = pam-password-token
CLEANDIRS = $(SUBDIRS)


all: info $(SUBDIRS)

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
	rm -rf common pam-password-token jsmn-web-tokens

.PHONY: subdirs $(INSTALLDIRS)
.PHONY: subdirs $(SUBDIRS)
.PHONY: subdirs $(CLEANDIRS)
.PHONY: all install clean

### pam-oidc source code handling targets
get-sources:
	@echo GET-SOURCES
	git clone https://git.man.poznan.pl/stash/scm/pracelab/pam.git upstream -b develop
	mv upstream/common upstream/pam-password-token upstream/jsmn-web-tokens .
	rm -rf upstream
	#quilt push -a

info:
	@echo "DESTDIR:         $(DESTDIR)"
	@echo "INSTALLDIRS:     $(INSTALLDIRS)"

### Dockers
dockerised_all_packages: dockerised_deb_debian_buster dockerised_deb_debian_bullseye dockerised_deb_ubuntu_bionic dockerised_deb_ubuntu_focal dockerised_rpm_centos7 dockerised_rpm_centos8

docker_images: docker_centos8 docker_centos7 docker_debian_bullseye docker_debian_buster docker_ubuntu_bionic docker_ubuntu_focal
docker_debian_buster:
	echo "\ndebian_buster"
	@echo "FROM debian:buster\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv dh-virtualenv python3-venv devscripts git "\
    	"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag debian_buster -f - .
docker_debian_bullseye:
	echo "\ndebian_bullseye"
	@echo "FROM debian:bullseye\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv dh-virtualenv python3-venv devscripts git "\
		"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag debian_bullseye -f - .
docker_ubuntu_bionic:
	echo "\nubuntu_bionic"
	@echo "FROM ubuntu:bionic\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv dh-virtualenv python3-venv devscripts git "\
		"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag ubuntu_bionic -f - .
docker_ubuntu_focal:
	echo "\nubuntu_focal"
	@echo "FROM ubuntu:focal\n"\
	"ENV DEBIAN_FRONTEND=noninteractive\n"\
	"ENV  TZ=Europe/Berlin\n"\
	"RUN apt-get update && "\
		"apt-get -y upgrade && "\
		"apt-get -y install build-essential dh-make quilt "\
		"python3-virtualenv python3-venv devscripts git "\
		"python3 python3-dev python3-pip python3-setuptools "| \
	docker build --tag ubuntu_focal -f - .
docker_centos7:
	echo "\ncentos7"
	@echo "FROM centos:7\n"\
	"RUN yum -y install make rpm-build\n"\
	"RUN yum -y groups mark convert\n"\
	"RUN yum -y groupinstall \"Development tools\"\n" | \
	docker build --tag centos7 -f - .
docker_centos8:
	echo "\ncentos8"
	@echo "FROM centos:8\n"\
	"RUN yum install -y make rpm-build\n" \
	"RUN dnf -y group install \"Development Tools\"\n" | \
	docker build --tag centos8 -f -  .

.PHONY: dockerised_deb_debian_buster
dockerised_deb_debian_buster: docker_debian_buster
	@docker run -it --rm -v ${DOCKER_BASE}:/home/build debian_buster /home/build/${PACKAGE}/build.sh ${PACKAGE} debian_buster

.PHONY: dockerised_deb_debian_bullseye
dockerised_deb_debian_bullseye: docker_debian_bullseye
	@docker run -it --rm -v ${DOCKER_BASE}:/home/build debian_bullseye \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} debian_bullseye

.PHONY: dockerised_deb_ubuntu_bionic
dockerised_deb_ubuntu_bionic: docker_ubuntu_bionic
	@docker run -it --rm -v ${DOCKER_BASE}:/home/build ubuntu_bionic \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} ubuntu_bionic

.PHONY: dockerised_deb_ubuntu_focal
dockerised_deb_ubuntu_focal: docker_ubuntu_focal
	@docker run -it --rm -v ${DOCKER_BASE}:/home/build ubuntu_focal \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} ubuntu_focal

.PHONY: dockerised_rpm_centos7
dockerised_rpm_centos7: docker_centos7
	@docker run -it --rm -v ${DOCKER_BASE}:/home/build centos7 \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} centos7

.PHONY: dockerised_rpm_centos8
dockerised_rpm_centos8: docker_centos8
	@docker run -it --rm -v ${DOCKER_BASE}:/home/build centos8 \
		/home/build/${PACKAGE}/build.sh ${PACKAGE} centos8

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
.PHONY: unpatch-for-rpm
unpatch-for-rpm:
	@if [ -e ".patched" ]; then \
		echo "Removing patches"; \
		for i in `cat rpm/patches/series | grep -v "^#"`; do \
			echo Reverting patch: $$i; \
			cat rpm/patches/$$i | patch -p1 -R; \
		done; \
		rm .patched; \
	else \
		echo "Patches already removed"; \
	fi

.PHONY: srctar
srctar: patch-for-rpm
	@(cd ..; tar cf $(BASENAME)/$(SRC_TAR) $(PKG_NAME) --transform='s_${PKG_NAME}_${PKG_NAME}-$(VERSION)_')
	mkdir -p rpm/rpmbuild/SOURCES
	mv $(SRC_TAR) rpm/rpmbuild/SOURCES/${PKG_NAME}.tar

.PHONY: rpm
rpm: srctar
	rpmbuild --define "_topdir ${PWD}/rpm/rpmbuild" -bb  rpm/${PKG_NAME}.spec

