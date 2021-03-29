Name: pam-ssh-oidc
Version: 0.1.1
Release: 1
Summary: PAM Plugin allowing consumption of OIDC AccessTokens
Group: Misc
License: MIT-License
URL: https://git.scc.kit.edu:fum/fum_ldf-interface.git
Source0: pam-ssh-oidc.tar

BuildRequires: cpp >= 6

BuildRoot:	%{_tmppath}/%{name}

%define debug_package %{nil}

%description
PAM Plugin allowing consumption of OIDC AccessTokens

%prep
%setup -q

%build
make 

%install
echo "Buildroot: ${RPM_BUILD_ROOT}"
echo "ENV: "
env | grep -i rpm
echo "PWD"
pwd
#make install INSTALL_PATH=${RPM_BUILD_ROOT}/usr MAN_PATH=${RPM_BUILD_ROOT}/usr/share/man CONFIG_PATH=${RPM_BUILD_ROOT}/etc
make install DESTDIR=${RPM_BUILD_ROOT}

%files
%defattr(-,root,root,-)
/etc/pam.d/config.ini
/lib64/security/pam_oidc_token.so

%changelog

