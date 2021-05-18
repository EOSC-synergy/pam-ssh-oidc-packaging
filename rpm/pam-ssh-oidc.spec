Name: pam-ssh-oidc
%define version %(head debian/changelog  -n 1 | cut -d \\\( -f 2 | cut -d \\\) -f 1 | cut -d \- -f 1)
%define release %(head debian/changelog  -n 1 | cut -d \\\( -f 2 | cut -d \\\) -f 1 | cut -d \- -f 2)
Version: %{version}
Release: %{release}

Summary: PAM Plugin allowing consumption of OIDC AccessTokens
Group: Misc
License: MIT
URL: https://github.com/EOSC-synergy/ssh-oidc
Source0: pam-ssh-oidc.tar.gz

# OpenSUSE likes to have a Group
%if 0%{?suse_version} > 0
Group: System/Libraries
%endif

BuildRequires: gcc
BuildRequires: pam-devel
BuildRequires: curl-devel
BuildRequires: libcurl-devel

# audit libs devel name is platform dependent
%if 0%{?fedora} || 0%{?rhel}
BuildRequires: audit-libs-devel
%else
BuildRequires: audit-devel
%endif

BuildRoot:	%{_tmppath}/%{name}

# define pamdir, which is platform dependent
%if 0%{?suse_version} > 0 && !0%{?usrmerged}
%define pamdir /%{_lib}/security
%else
%define pamdir %{_libdir}/security
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

# On some OpenSUSE need to move module to /lib64/security
%if 0%{?suse_version} > 0 && !0%{?usrmerged}
mkdir -p ${RPM_BUILD_ROOT}%{pamdir}
mv -f ${RPM_BUILD_ROOT}%{_libdir}/security/* ${RPM_BUILD_ROOT}%{pamdir}
%endif

%files
%defattr(-,root,root,-)
%config(noreplace) %{_sysconfdir}/pam.d/pam-ssh-oidc-config.ini
%{pamdir}/pam_oidc_token.so
%docdir /usr/share/doc/
/usr/share/doc/%{name}-%{version}/README.md

%changelog
* Thu May  6 2021 Mischa Salle <mischa.salle@gmail.com> 0.1.2-2
- cleanup spec file
* Fri Apr 23 2021 Marcus Hardt <hardt@kit.edu> 0.1.0-1
- initial packaging of upstream

%post
# Test /etc/ssh/sshd for adequate config
SSHD=/etc/ssh/sshd_config
# Check if ChalleneResponseAuthentication is already enabled:
grep -q "^ChallengeResponseAuthentication yes" ${SSHD} || {
    echo "######################################################################"
    echo "#  pam-ssh-oidc detected that your /etc/ssh/sshd_config              #"
    echo "#  does not contain 'ChallengeResponseAuthentication yes'            #"
    echo "#  Consider setting this to yes, if login via pam-ssh does           #"
    echo "#  not show the 'AccessToken: ' prompt. Note that this will          #"
    echo "#  enable password login, even if 'Passwordauthentication no' is set #"
    echo "######################################################################"
}
