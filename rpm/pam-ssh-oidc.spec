Name: pam-ssh-oidc
%define ver %(head debian/changelog -n 1|cut -d \\\( -f 2|cut -d \\\) -f 1|cut -d \- -f 1)
%define rel %(head debian/changelog -n 1|cut -d \\\( -f 2|cut -d \\\) -f 1|cut -d \- -f 2)
Version: %{ver}
Release: %{rel}

Summary: PAM Plugin allowing consumption of OIDC AccessTokens
Group: System/Libraries
License: MIT
URL: https://github.com/EOSC-synergy/ssh-oidc
Source0: pam-ssh-oidc.tar.gz

BuildRequires: gcc
BuildRequires: pam-devel
BuildRequires: curl-devel
BuildRequires: libcurl-devel

BuildRoot:	%{_tmppath}/%{name}

# define PAM_LIB_DIR, which is platform dependent
%if 0%{?suse_version} > 0 && !0%{?usrmerged}
%define PAM_LIB_DIR /%{_lib}/security
%else
%define PAM_LIB_DIR %{_libdir}/security
%endif

%define debug_package %{nil}

%description
PAM (Pluggable Authentication Modules) Plugin allowing consumption of OIDC
AccessTokens

%prep
%setup -q

%build
cd pam-password-token && make

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=${RPM_BUILD_ROOT}
install -D -d -m 755 $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}
install -m 644 documentation/README-pam-ssh-oidc.md $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/README.md

# On some OpenSUSE need to move module to /lib64/security
%if 0%{?suse_version} > 0 && !0%{?usrmerged}
mkdir -p ${RPM_BUILD_ROOT}%{PAM_LIB_DIR}
mv -f ${RPM_BUILD_ROOT}%{_libdir}/security/* ${RPM_BUILD_ROOT}%{PAM_LIB_DIR}
%endif

%files
%defattr(-,root,root,-)
%config(noreplace) %{_sysconfdir}/pam.d/pam-ssh-oidc-config.ini
%{PAM_LIB_DIR}/pam_oidc_token.so
%docdir /usr/share/doc/
/usr/share/doc/%{name}-%{version}/README.md

%changelog
* Thu May  6 2021 Mischa Salle <mischa.salle@gmail.com> 0.1.2-2
- cleanup spec file
* Fri Apr 23 2021 Marcus Hardt <hardt@kit.edu> 0.1.0-1
- initial packaging of upstream

%post
# Test /etc/ssh/sshd for adequate config
SSHD=%{_sysconfdir}/ssh/sshd_config
# Check if ChalleneResponseAuthentication is already enabled:
test -e $SSHD && {
    grep -q "^ChallengeResponseAuthentication yes" ${SSHD} || {
        echo "### WARNING ##########################################################"
        echo "#  pam-ssh-oidc detected that your ${SSHD}              #"
        echo "#  does not contain 'ChallengeResponseAuthentication yes'            #"
        echo "#  Consider setting this to yes, if login via pam-ssh does           #"
        echo "#  not show the 'AccessToken: ' prompt. Note that this will          #"
        echo "#  enable password login, even if 'Passwordauthentication no' is set #"
        echo "######################################################################"
    }
}
test -e $SSHD || {
    echo "### WARNING ##########################################################"
    echo "#  ssh daemon is not installed. At least I cannot find the           #"
    echo "#  config file at ${SSHD}.                              #"
    echo "#  This may be ok, just thought I should tell you.                   #"
    echo "######################################################################"
}
