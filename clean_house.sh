#!/bin/sh
#umount mounts to .snapshot directories
umount -f `mount | grep snap | awk '{print $3}' | xargs`
#now clean up Network Sockets for RealVNC and DCV:
/usr/local/bin/clean_obsolete_dcv_vnc_sockets.pl
/usr/local/bin/drop_caches 1
/usr/local/bin/drop_caches 2
/usr/local/bin/drop_caches 3
/usr/local/bin/compact_memory
# Just Info : see for /etc/gamin/gaminrc, very important to reduce load by gam_server, the most useless tool ever
/usr/bin/tmpwatch  20d -a --force -s /tmp > /dev/null
