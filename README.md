# Packaging tools for pam-ssh-oidc

This package is for packaging https://git.man.poznan.pl/stash/scm/pracelab/pam.git

Since that package was developed in a different context, and since some of
its components are not required, the Makefile selects the necessary
components (by removing unused ones).

There are two debian-quilt style patch sets available. One for debian
packaging, one for rpm packaging, both in (rpm|debian)/patches/.  They are
applied along the packaging process.

# Usage

Using the magic of `make`, everything **should just work** (TM) by
specifying the desired target. The following make targets should create
the required docker images, run them and build the package inside.

After building files reside in the `../results` folder

- `make dockerised_deb_debian_bullseye` (current debian-unstable)
- `make dockerised_deb_debian_buster` (current debian-testing)
- `make dockerised_deb_ubuntu_bionic` (ubuntu 18.04 LTS "Bionic Beaver")
- `make dockerised_deb_ubuntu_focal` (ubuntu 20.04 LTS "Focal Fossa")
- `make dockerised_rpm_centos8` (centos 8)
- `make dockerised_rpm_centos7` (centos 7)

The debian and ubuntu packages are available from
[https://repo.data.kit.edu](https://repo.data.kit.edu)

