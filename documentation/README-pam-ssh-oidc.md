# pam-ssh-oidc

This package provides a module that allows `sshd` to accept OIDC Access
Tokens for authenticating a user. This is done by using the PAM module
`pam_oidc_token`.

While that PAM module may be used stand-along, this package ships together
with the daemon `motley-cue`, which is used for:
- evaluating the Access Token
- enforcing authorisation
- creating accounts for authorised users
- provide suspend/resume capabilities for authorised personnel (typically CERT/CSIRT)

To enable this module, the Pluggable Authentication Module `PAM` must be
configured. The setup is different, depending on the linux distribution
you use. We provide the package `pam-ssh-oidc-autoconfig` that should work
on those distributions for which we provide packages.

Manual installation works as follows:

- Ensure that either `ChallengeResponseAuthentication yes` or
    `KbdInteractiveAuthentication yes` exist your sshd config (typically
    `/etc/ssh/sshd_config`).

    **Note**: This will enable Password Authentication, which may not be
    intended. You can disable Password Authentication in `/etc/pam.d/sshd`
    by commenting other lines starting with `auth`. (Also check `@include`
    statements).

- Add this line at the top of your `/etc/pam.d/sshd` config:
    ```
    auth   sufficient pam_oidc_token.so config=/etc/pam.d/pam-ssh-oidc-config.ini
    ```

`Suse` based distributions don't come with a specific `/etc/pam.d/sshd`
file. In this case, create a file like this:
```
#%PAM-1.0

# use pam-ssh-oidc
auth       sufficient   pam_oidc_token.so config=/etc/pam.d/pam-ssh-oidc-config.ini
#auth       include      common-auth
account    include      common-account

# Comment out next line to disable password login:
password   include      common-password

session    include      common-session
```
