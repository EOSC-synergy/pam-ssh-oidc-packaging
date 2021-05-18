Name: pam-ssh-oidc
Version: 0.1.2
Release: 6
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
/etc/pam.d/pam-ssh-oidc-config.ini
/usr/lib64/security/pam_oidc_token.so

%changelog

%post
# Test /etc/pam.d/sshd for adequate config:
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
