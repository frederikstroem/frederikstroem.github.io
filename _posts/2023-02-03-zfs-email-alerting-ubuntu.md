---
layout: post
is_post: true

title: Setup monthly ZFS scrubs with email alerts on Ubuntu Server 22.04
last_modified: 2023-02-03
---
## A preliminary note of caution
I would advice against using email alerting for anything industry or mission critical, as email has issues with reliability among other things.

## Prerequisites
ZFS is installed and configured, ([install ZFS on Ubuntu Server](https://ubuntu.com/tutorials/setup-zfs-storage-pool)).

## Install msmtp and dependencies
[msmtp](https://marlam.de/msmtp/) is an SMTP client that is simple and easy to configure.

Fetch the latest version of the package list:
```bash
sudo apt update
```

Install `msmtp` along with `msmtp-mta` and `mailutils`:
```bash
sudo apt install -y msmtp msmtp-mta mailutils
```

## Configure msmtp
Edit the `/etc/msmtprc` file (with root privileges), you can do this on Ubuntu using the `sudoedit` command:
```bash
sudoedit /etc/msmtprc
```

***Note:** [You can easily change the `sudoedit` editor by setting the `SUDO_EDITOR` environment variable.](https://web.archive.org/web/20230202181924/https://linuxconfig.org/how-to-edit-a-system-file-with-sudoedit-preserving-the-invoking-user-environment)*

Edit the `/etc/msmtprc` file:
```
# Set default values for all following accounts.
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

# Outlook.
account        outlook
host           smtp-mail.outlook.com
port           587
from           example_sender@outlook.com
user           example_sender@outlook.com
password       very_secret_password

# Gmail.
account        gmail
host           smtp.gmail.com
port           587
from           example_sender@gmail.com
user           example_sender@gmail.com
password       much_different_password
```

***Note:** In this example, I have added templating for sending emails over TLS using either [Gmail](https://web.archive.org/web/20230202191939/https://support.google.com/mail/answer/7126229) or [Outlook](https://web.archive.org/web/20230202191935/https://support.microsoft.com/en-us/office/pop-imap-and-smtp-settings-for-outlook-com-d088b986-291d-42b8-9564-9c414e2aa040). You can add other accounts by following the same format, (the `account` variable is required, but its value does not matter, it will not be used as an identifier).*

## Install ZED
ZED (ZFS Event Daemon) listens for ZFS events, and it can be configured to send email alerts after automated scrubs.

Install ZED:

```bash
sudo apt install zfs-zed
```

## Configure ZED
Edit the ZED config file `/etc/zfs/zed.d/zed.rc`:

This configuration file is a little long, so I have included the relevant lines below. First up, the recipient email address of the alerts is set:

```bash
##
# Email address of the zpool administrator for receipt of notifications;
#   multiple addresses can be specified if they are delimited by whitespace.
# Email will only be sent if ZED_EMAIL_ADDR is defined.
# Disabled by default; uncomment to enable.
#
ZED_EMAIL_ADDR="alert_me@example.com"
```

Then the mail command is set:

```bash
##
# Name or path of executable responsible for sending notifications via email;
#   the mail program must be capable of reading a message body from stdin.
# Email will only be sent if ZED_EMAIL_ADDR is defined.
#
ZED_EMAIL_PROG="mail"
```

Then the command-line options for the mail command is set:

```bash
##
# Command-line options for ZED_EMAIL_PROG.
# The string @ADDRESS@ will be replaced with the recipient email address(es).
# The string @SUBJECT@ will be replaced with the notification subject;
#   this should be protected with quotes to prevent word-splitting.
# Email will only be sent if ZED_EMAIL_ADDR is defined.
#
ZED_EMAIL_OPTS="-s '@SUBJECT@' @ADDRESS@ -r example_sender@outlook.com"
```

***Note:** The e-mail address after `-r` will determine the sender address of the alert email.*

Finally (and optionally), the alerting verbosity is set, setting it to `1` will send alerts regardless of the pool health:
```bash
##
# Notification verbosity.
#   If set to 0, suppress notification if the pool is healthy.
#   If set to 1, send notification regardless of pool health.
#
ZED_NOTIFY_VERBOSE=1
```

***Note:** [If you want to test the email alerts, set this variable to `1`.](#optional-test-zfs-scrub-email-alerts)*

## [Optional] Configure ZED scrubbing schedule
Interestingly, ZED on Ubuntu and Debian is pre-configured to perform a scrub on the second Sunday of each month ([not a 🐛](https://github.com/openzfs/zfs/issues/9858)).

This feels like a pretty sane default, but if you want to change it, you can do so by editing the `/etc/cron.d/zfsutils-linux` file.

```bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Scrub the second Sunday of every month.
24 0 8-14 * * root if [ $(date +\%w) -eq 0 ] && [ -x /usr/lib/zfs-linux/scrub ]; then /usr/lib/zfs-linux/scrub; fi
```

***Note:** This does a scrub on all ZFS storage pools. You can alternatively also delete the `/etc/cron.d/zfsutils-linux` file and configure a (root) cron job for each pool individually.*

## [Optional] Test ZFS scrub email alerts
If you want to test the email alerts, you can do so by creating a small ZFS test pool, scrubbing it, and then discarding it ([source](https://web.archive.org/web/20230202235421/https://old.reddit.com/r/zfs/comments/fb8utq/how_to_test_zed_notification_emails/)).

```bash
cd /tmp
dd if=/dev/zero of=zpool_test bs=1 count=0 seek=512M
sudo zpool create test /tmp/zpool_test
sudo zpool scrub test
sudo zpool export test
rm /tmp/zpool_test
```

***Note:** `ZED_NOTIFY_VERBOSE=1` must be set in the ZED config file for this to work.*
