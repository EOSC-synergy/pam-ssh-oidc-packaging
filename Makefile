PKG_NAME  = pam-ssh-oidc
PKG_NAME_UPSTREAM = pam-ssh-oidc
#VERSION := $(shell git tag -l  | tail -n 1 | sed s/v//)
VERSION := 0.0.1

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
	quilt push -a

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
