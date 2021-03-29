PKG_NAME  = pam-ssh-oidc
PKG_NAME_UPSTREAM = pam-ssh-oidc
VERSION := 0.1.1
BASEDIR = $(PWD)
BASENAME := $(notdir $(PWD))
#SRC_TAR:=$(PKG_NAME)-$(VERSION).tar
SRC_TAR:=$(PKG_NAME).tar
#VERSION := $(shell git tag -l  | tail -n 1 | sed s/v//)

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

##########################################
# Marcus Editing

get-sources:
	@echo GET-SOURCES
	git clone https://git.man.poznan.pl/stash/scm/pracelab/pam.git upstream -b develop
	mv upstream/common upstream/pam-password-token upstream/jsmn-web-tokens .
	rm -rf upstream
	#quilt push -a

info:
	@echo "DESTDIR:         $(DESTDIR)"
	@echo "INSTALLDIRS:     $(INSTALLDIRS)"

# Packaging
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

############ RPM Targets

.PHONY: patch-for-debian
patch-for-debian:
	@if [ -e ".patched" ]; then \
		echo "Patches already applied"; \
	else \
		echo "Applying patches"; \
		for i in `cat debian/patches/series | grep -v "^#"`; do \
			echo Applying patch: $$i; \
			cat debian/patches/$$i | patch -p1; \
		done; \
    fi
	@touch .patched
.PHONY: unpatch-for-debian
unpatch-for-debian:
	@if [ -e ".patched" ]; then \
		echo "Removing patches"; \
		for i in `cat debian/patches/series | grep -v "^#"`; do \
			echo Reverting patch: $$i; \
			cat debian/patches/$$i | patch -p1 -R; \
		done; \
		rm .patched; \
	else \
		echo "Patches already removed"; \
	fi
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
	@(cd ..; tar cf $(BASENAME)/$(SRC_TAR) $(PKG_NAME) --transform='s_pam-ssh-oidc_pam-ssh-oidc-$(VERSION)_')
	#@tar cf $(SRC_TAR) Makefile README.md Changelog $(SSH_KEY_RETRIEVER) $(CONFIG).example $(PKG_NAME).go   --transform='s_^_$(PKG_NAME)-$(VERSION)/_'

	mkdir -p rpm/rpmbuild/SOURCES
	mv $(SRC_TAR) rpm/rpmbuild/SOURCES/pam-ssh-oidc.tar

.PHONY: rpm
rpm: srctar
	#rpmbuild --define "_topdir $(PWD)/rpm/rpmbuild" -bb  rpm/pam-ssh-oidc.spec
	rpmbuild --define "_topdir ${PWD}/rpm/rpmbuild" -bb  /home/build/pam-ssh-oidc/rpm/pam-ssh-oidc.spec

