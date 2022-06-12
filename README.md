# Keycron bt connect

A simple shell script that allows the user to connect his Keychron Bluetooth Keyboard with a Linux powered machine.
This - alt least for me - is sometimes a problem. The device does not want to reconnect and i have to manually unpair and re-pair the two devices.
Because of this i created this script and if you want you can use it too.

```
In no way affiliated with Keycron! Use at your own risk!
```

## HowTo
_replace any metion of USER in these instructions and in the files from this repository with your own user logon name (see /home/USER/)_

 1. Create a new group using `~# groupadd keychron` _(as root or sudo)_
 2. Add yourself to the group using `~# usermod -a -G keychron USER` _(as root or sudo)_
 3. Copy /etc/sudoers.d/keychron (from this repository) into the same folder on your device _(as root or sudo)_
 4. Set the needed File-Permissions on the copied File with `~# chmod 400 /etc/sudoers.d/keychron` _(as root or sudo)_
 5. Logout and log back in once to let the group change take effect.
 6. Copy /home/USER/.local/bin/keychron-keyboard-connect.sh (from this repository) into the same folder on your device _(as your unprivileged user)_
 7. Make the File executable by the owner by using `~$ chmod u+x /home/USER/.local/bin/keychron-keyboard-connect.sh` _(as your unprivileged user)_
 8. Copy "/home/USER/.local/share/applications/Keychron Connect.desktop" 
