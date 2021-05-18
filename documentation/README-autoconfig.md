# pam-ssh-oidc-autoconfig

This package is for automatically configuring PAM (via) `/etc/pam.d/sshd`
to use `pam_oidc_token` provided by the package `pam-ssh-oidc`.

This is done in different ways, depending on the linux distribution used:

- `Centos` and `Debian` based: Modify the existing file to add (as the first statement):
    ```
    auth   sufficient pam_oidc_token.so config=%{_sysconfdir}/pam.d/pam-ssh-oidc-config.ini
    ```
- `Suse` based: Install `/etc/pam.d/sshd` as a configuration file (`%config(noreplace)`)


# Configuration of `sshd`

**We do not modify any sshd configuration files**

** IMPORTANT **

On installation of `pam-ssh-oidc` we check, if your
`sshd_config` has `ChallengeResponseAuthentication` enabled. This is
required to make the ssh module work.

A side effect of `ChallengeResponseAuthentication`, however, is that this
will allow users to log in with passwords, which may not be what you want.
To disable this, you need to disable the `sshd` part of your `PAM`
configuration as follows:

- `Suse`: make sure that this line in `/etc/pam.d/sshd` is commented out:
    ```
    password   include      common-password
    ```
- `Centos`: Comment out this line in `/etc/pam.d/sshd`:
    ```
    auth       substack     password-auth
    ```

# Words of Caution

- Make a backup of `/etc/pam.d`
- Once you save a configuration file, changes take effect **immediately**
- When modifying `PAM` config, it is **very much encouraged** to have as
    least of active session for rescue. 
- **TEST ALL ways to log in to your system before closing the last session**

I repeat(!):
**TEST ALL ways to log in to your system before closing the last session**
