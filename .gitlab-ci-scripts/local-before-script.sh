#!/bin/bash

info() {
    echo "### pam-ssh-before-script (local) ##############################################"
    echo "CI_COMMIT_REF_NAME: ${CI_COMMIT_REF_NAME}"
    echo "CI_COMMIT_BRANCH:   ${CI_COMMIT_BRANCH}"
    echo "CI_DEFAULT_BRANCH:  ${CI_DEFAULT_BRANCH}"
    echo "CI_PIPELINE_SOURCE: ${CI_PIPELINE_SOURCE}"
    echo "CI_UPSTREAM_PIPELINE_SOURCE:  ${CI_UPSTREAM_PIPELINE_SOURCE}"
    echo "CI_UPSTREAM_COMMIT_BRANCH:    $CI_UPSTREAM_COMMT_BRANCH"
    echo "CI_UPSTREAM_DEFAULT_BRANCH:   $CI_UPSTREAM_DEFAULT_BRANCH"
    echo "### /pam-ssh-before-script (local) ##############################################"
}

echo "======== oidc-agent-local-before-script starting======="

case ${DISTRO} in
    debian|ubuntu)
        make get-sources
        info
    ;;
    opensuse)
        make get-sources
        make srctar
        mkdir -p /usr/src/packages/SOURCES
        mv rpm/rpmbuild/SOURCES/* /usr/src/packages/SOURCES/
        rm -rf rpm/rpmbuild
    ;;
    *) # We expect only RPM by default
        make get-sources
        make srctar
        # place source tarballs
        mkdir -p /root/rpmbuild/SOURCES
        mkdir -p /root/rpmbuild/RPMS
        mv rpm/rpmbuild/SOURCES/* /root/rpmbuild/SOURCES/
        rm -rf rpm/rpmbuild

        info()
    ;;
esac

echo "======== oidc-agent-local-before-script done   ========"
