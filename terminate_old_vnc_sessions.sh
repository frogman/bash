#!/bin/bash -x
#________________________________________________________________
#
# Terminate VNC server sessions older than 24 hours
#
# Note: The OpenLava job time limit has been set to 24 hours
#       but the jobs older than 24 hours will be killed by this
#       script executed as cronjob at midnight
#
#       This procedure has been suggested by P. Tibaut @ May 2015
#
# Variables:
#
#       tcur    ... The script execution epoch time (=secs since 1970)
#       tjob    ... The jobs epoch time
#       dt      ... Difference of tcur and tjob (tcur > tjob)
#       thour   ... Secs per hour (acts as time unit)
#       tlimit  ... Time limit N*thour for terminating VNC sessions
#       tlimit2 ... Time limit 7 days
#________________________________________________________________

typeset -i tcur
typeset -i tjob
typeset -i dt
typeset -i thour
typeset -i tlimit
typeset -i tlimit2
thour=3600

JOBLIST=( 0 )
mkdir -p /var/run/dcv/
echo "" > /var/run/dcv/Error_termVNCjobs.log
ErrorLog="/var/run/dcv/Error_termVNCjobs.log"
touch $ErrorLog
BJOBS="/opt/openlava-2.0/bin/bjobs -r -u all"
# BKILL=/bin/echo
BKILL=/opt/openlava-2.0/bin/bkill
MY_PROTECTIONFILELIST=`/bin/ls /tmp/ | /bin/grep -i do_not_kill | xargs`
echo "$MY_PROTECTIONFILELIST" >> "$ErrorLog"
HN=$(hostname -s)
MY_RCPNT="Zeljko.Milinovic@qpunkt.at"
SUBJECT="ATTENTION: Failed to terminate VNC session on $HN"
echo "This mail has been send by termVNCjobs.sh from $HN" > /tmp/dcv.mail
#
# Set current time limit of 24 hours
#
tlimit=24*thour
tlimit2=5*tlimit
#
# Get the current script execution epoch time (= secs since 1970)
#
# tcur=$(date +%s -d"`date`")
tcur=$(date +%s )

# ---------------------------------------------------------------
# Exit if there are no jobs in the queue at all
# ---------------------------------------------------------------

$BJOBS > /dev/null 2>&1

if [ $? != 0 ]; then
        exit 0
fi

# ---------------------------------------------------------------
# Setup the complete list of jobIDs from "bjobs -u all"
# ---------------------------------------------------------------

JOBLIST=$($BJOBS | grep -v JOBID | awk '{ print $1 }' |  xargs )

/bin/echo "Debug1: Joblist $JOBLIST"  >>  "$ErrorLog"
#
# ===============================================================
# Loop and kill all jobs older than tlimit
# ===============================================================
#

for j in $JOBLIST; do

        BKILL="/opt/openlava-2.0/bin/bkill"
# ---------------------------------------------------------------
# Get Age (secs since 1970) for job time
# ---------------------------------------------------------------

        tmp=$($BJOBS | grep $j | awk '{ print $9 " " $10 " " $11 }')
        tjob=$(date +%s -d"$tmp")
        /bin/echo "tmp $tmp for JobID $j"    >> "$ErrorLog"
        /bin/echo "tjob $tjob for JobID $j"  >> "$ErrorLog"
        /bin/echo "tcur $tcur for JobID $j"  >> "$ErrorLog"
        dt=tcur-tjob
        /bin/echo "DT $dt for JobID $j"  >> "$ErrorLog"
# ---------------------------------------------------------------
# Kill job older than 24 hours
# ---------------------------------------------------------------
# Protect all sessions running shorter than tlimit

if [ "$dt" -lt "$tlimit" ]; then
                JOBLIST=`echo $JOBLIST | sed -e s'/$j//g'`
                BKILL="/bin/echo"
fi

        if [ "$dt" -ge "$tlimit" ]; then
                JOBLIST=`echo $JOBLIST | sed -e s'/$j//g'`
        if [ -f "/tmp/do_not_kill_${j}"  ]; then
                echo "removing /tmp/do_not_kill_${j} Short Term protected Job $j" >> "$ErrorLog"
                /bin/rm /tmp/do_not_kill_${j}
                BKILL="/bin/echo"
                echo "Short Term protected Job $j" >> "$ErrorLog"
                DONOTMAIL="TRUE"
        fi
        fi
        /bin/echo "Debug2: Joblist $JOBLIST after short term protect" >>  "$ErrorLog"

# exception for long running sessions
        if [ "$dt" -le "$tlimit2" ]; then
        if [ -f /tmp/do_not_kill_one_week_${j}  ]; then
                BKILL="/bin/echo"
                echo "Found Long Term protected Job $j" >> "$ErrorLog"
                JOBLIST=`echo $JOBLIST | sed -e s'/$j//g'`
                /bin/touch  /tmp/do_not_kill_${j}
                DONOTMAIL="TRUE"
        fi
        fi


        if [ "$dt" -ge "$tlimit2" ]; then
        if [ -f /tmp/do_not_kill_one_week_${j}  ]; then
                /bin/echo "removing /tmp/do_not_kill_one_week_${j} Long Term protected Job $j" >> "$ErrorLog"
                /bin/rm /tmp/do_not_kill_one_week_${j}
        fi
        fi
        /bin/echo "Debug3: Joblist directly before kill  $JOBLIST" >>  "$ErrorLog"
                echo "$BKILL $j  Job $j" >> "$ErrorLog"
# for simulation runs mask bkill by echo
#               BKILL="bin/echo"
                $BKILL $j > /dev/null 2>&1
                sleep 5
                $BKILL $j > /dev/null 2>&1
                BKILL=/opt/openlava-2.0/bin/bkill



# ---------------------------------------------------------------
# Write error msg when jobs older than 24 hours still remain !
# ---------------------------------------------------------------

                $BJOBS | grep $j > /dev/null 2>&1

                if [ $? = 0 ]; then
                        DATE=$(date)
                        printf  "$DATE:\tThe job ID=$j has intentionally not been killed \n" >> $ErrorLog
#                        mail -s "$SUBJECT" -a "$ErrorLog" $MY_RCPNT < /tmp/dcv.mail
                fi

#    fi

            DONOTMAIL="FALSE"
done
#now clean up Network Sockets for RealVNC and DCV:
# /root/clean_obsolete_dcv_vnc_sockets.pl  > /dev/null
/usr/local/bin/drop_caches 1
/usr/local/bin/drop_caches 2
/usr/local/bin/drop_caches 3
/usr/local/bin/compact_memory
# Just Info : see for /etc/gamin/gaminrc, very important to reduce load by gam_server, the most useless tool ever
/usr/bin/tmpwatch  10d -a --force -s /tmp > /dev/null
