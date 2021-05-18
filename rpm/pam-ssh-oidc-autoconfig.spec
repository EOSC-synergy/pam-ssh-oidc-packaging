Name: pam-ssh-oidc-autoconfig
%define version %(head debian/changelog  -n 1 | cut -d \\\( -f 2 | cut -d \\\) -f 1 | cut -d \- -f 1)
%define release %(head debian/changelog  -n 1 | cut -d \\\( -f 2 | cut -d \\\) -f 1 | cut -d \- -f 2)
Version: %{version}
Release: %{release}

Summary: PAM Plugin allowing consumption of OIDC AccessTokens - Autoconfig
Group: Misc
License: MIT
URL: https://github.com/EOSC-synergy/ssh-oidc
Source0: pam-ssh-oidc-autoconfig.tar.gz

# OpenSUSE likes to have a Group
%if 0%{?suse_version} > 0
Group: System/Libraries
%endif

BuildRoot:	%{_tmppath}/%{name}

%description
PAM (Pluggable Authentication Modules) Plugin allowing consumption of OIDC
AccessTokens. This package automatically configures PAM to support
pam-ssh-oidc

Requires: pam-ssh-oidc >= 0.1.2-6

%prep
%setup -q

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT
echo "PWD: "
pwd
mkdir -p $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}
cp README.md $RPM_BUILD_ROOT/usr/share/doc/%{name}-%{version}/README.md

%files
%defattr(-,root,root,-)
%docdir /usr/share/doc/
/usr/share/doc/%{name}-%{version}/README.md

%changelog
* Fri Apr 23 2021 Marcus Hardt <hardt@kit.edu> 0.1.0-1
- initial packaging of upstream

%post
#T est /etc/pam.d/sshd for adequate config:
PAM_SSHD="/etc/pam.d/sshd"
cat ${PAM_SSHD} | grep -v ^# | grep -q  "pam_oidc_token.so" || {
    echo "######################################################################"
    echo "#  Enabling configuration for pam_oidc_token.so in ${PAM_SSHD}"
    echo "#  A backup is in ${PAM_SSHD}.dist"
    echo "######################################################################"
    test -e ${PAM_SSHD}.dist && mv ${PAM_SSHD}.dist /tmp
    HEADLINE=`head -n 1 ${PAM_SSHD}`
    mv ${PAM_SSHD} ${PAM_SSHD}.dist
    echo ${HEADLINE} > ${PAM_SSHD}
    echo "" >> ${PAM_SSHD}
    echo "# use pam-ssh-oidc" >> ${PAM_SSHD}
    echo "auth   sufficient pam_oidc_token.so config=/etc/pam.d/pam-ssh-oidc-config.ini" >> ${PAM_SSHD}
    cat ${PAM_SSHD}.dist | grep -v "${HEADLINE}" >> ${PAM_SSHD}
}
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

