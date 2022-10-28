Name: pam-ssh-oidc-autoconfig
%define ver %(head debian/changelog -n 1|cut -d \\\( -f 2|cut -d \\\) -f 1|cut -d \- -f 1)
%define rel %(head debian/changelog -n 1|cut -d \\\( -f 2|cut -d \\\) -f 1|cut -d \- -f 2)
Version: %{ver}
Release: %{rel}

Summary: PAM Plugin allowing consumption of OIDC AccessTokens - Autoconfig
Group: System/Libraries
License: MIT
URL: https://github.com/EOSC-synergy/ssh-oidc
Source0: pam-ssh-oidc-autoconfig.tar.gz
Requires: pam-ssh-oidc >= 0.1.2-6

BuildRoot:	%{_tmppath}/%{name}

%description
PAM (Pluggable Authentication Modules) Plugin allowing consumption of OIDC
AccessTokens. This package automatically configures PAM to support
pam-ssh-oidc

# definitions
%if 0%{?suse_version} > 0 && !0%{?usrmerged}
%define PAM_LIB_DIR /%{_lib}/security
%define PAM_SSHD %{_sysconfdir}/pam.d/sshd
%else
%define PAM_LIB_DIR %{_libdir}/security
%define PAM_SSHD %{_sysconfdir}/pam.d/sshd
%endif

%prep
%setup -q

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT
install -D -d -m 755 $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}
install -m 644 documentation/README-autoconfig.md $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/README.md

%files
%defattr(-,root,root,-)
%docdir /usr/share/doc/
/usr/share/doc/%{name}-%{version}/README.md

%changelog
* Fri Apr 23 2021 Marcus Hardt <hardt@kit.edu> 0.1.0-1
- initial packaging of upstream


%post
PAM_SSHD=%{PAM_SSHD}
PAM_LIB_DIR=%{PAM_LIB_DIR}
# Test %{_sysconfdir}/pam.d/sshd for adequate config:
cat ${PAM_SSHD} | grep -v ^# | grep -q  "pam_oidc_token.so" && {
    echo "### pam-ssh-oidc is already configured. Nothing to do ###"
}
cat ${PAM_SSHD} | grep -v ^# | grep -q  "pam_oidc_token.so" || {
    echo "######################################################################"
    echo "#  Enabling configuration for pam_oidc_token.so in ${PAM_SSHD}"
    echo "#  A backup is in ${PAM_SSHD}.rpmsave"
    echo "######################################################################"
    HEADLINE=`head -n 1 ${PAM_SSHD}`
    echo "pam_sshd: ${PAM_SSHD}"
    ls -la ${PAM_SSHD}
    ls -la /etc/pam.d
    test -e  ${PAM_SSHD}.rpmsave || {
        cp ${PAM_SSHD} ${PAM_SSHD}.rpmsave
    }
    test -e  ${PAM_SSHD}.rpmtemp &&  rm -f ${PAM_SSHD}.rpmtemp
    mv ${PAM_SSHD} ${PAM_SSHD}.rpmtemp
    ls -la /etc/pam.d
    echo ${HEADLINE} > ${PAM_SSHD}
    echo "" >> ${PAM_SSHD}
    echo "# use pam-ssh-oidc" >> ${PAM_SSHD}
    echo "auth   sufficient pam_oidc_token.so config=%{_sysconfdir}/pam.d/pam-ssh-oidc-config.ini" >> ${PAM_SSHD}
    cat ${PAM_SSHD}.rpmtemp | grep -v "${HEADLINE}" >> ${PAM_SSHD}
}
