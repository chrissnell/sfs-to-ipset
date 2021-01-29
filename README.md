# sfs-to-ipset
Loads IP blocklists from StopForumSpam into a Linux ipset for easy IPTables filtering

# Installation
1. Open `sfs-to-ipset.sh` in your text editor and edit the configuration.  By default, this script loads the SFS blocklists from the last 180 days.  There are a number of different lists available.  See this page for more info:  https://www.stopforumspam.com/downloads

Be aware that StopForumSpam rate-limits your downloading of these lists.  I recommend not adjusting the systemd timer beyond `daily` unless you are using one of the shorter-duration lists with more permissive rate limits.

2. As root, install the files:
```
% cp sfs-to-ipset.sh /usr/bin
% chmod 755 /usr/bin/sfs-to-ipset.sh
% cp sfs-to-ipset.service /etc/systemd/system/
% cp sfs-to-ipset.timer /etc/systemd/system/
```
3. Install the sfs-to-ipset systemd units:
```
% systemctl daemon-reload
% systemctl enable sfs-to-ipset.timer
% systemctl start sfs-to-ipset.timer
```
This should start the `sfs-to-ipset.service`.  You can manually force the unit to run by executing:
```
% systemctl start sfs-to-ipset.service
```
4. Verify that everything worked as it should:
```
% journalctl -u sfs-to-ipset.service
```

# Usage
To make use of these blocklists, you need to write IPTables filters that utilize the ipset(8) sets that are created by this script.  Instruction on IPTables is beyond the scope of this document but here's how I do it:
```
:LOGNDROPBADACTOR - [0:0]
-I INPUT -i eth0 -m set --match-set sfs-ipv4 src -j LOGNDROPBADACTOR
-A LOGNDROPBADACTOR -m limit --limit 5/min -j LOG --log-prefix "Denied bad actor: " --log-level 7
```
This drops all packets originating from the StopForumSpam blocklists and logs a message (no more than 5 times a minute) when it happens.
