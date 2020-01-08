#!/usr/bin/env bash

current=$(pwd)
mkdir $1 && cd $1
declare -a arr=("augmentstarter" "bacct" "badmin" "bapp" "batch-acct" "bbot" "bchkpnt" "bclusters" "bconf" "bentags" "bgadd" "bgbroker" "bgdel" "bgmod" "bgpinfo" "bhist" "bhosts" "bhpart" "bjdepinfo" "bjgroup" "bjobs" "bkill" "blaunch" "blimits" "bmg" "bmgroup" "bmig" "bmod" "bmodify" "bparams" "bpeek" "bpost" "bqc" "bqueues" "bread" "breboot" "breconfig" "brequeue" "bresize" "bresources" "brestart" "bresume" "brlainfo" "brsvadd" "brsvdel" "brsvmod" "brsvs" "brun" "bsla" "bslots" "bstatus" "bstop" "bsub" "bswitch" "btop" "bugroup" "busers" "ch" "clnqs" "daemons_old" "datactrl" "datainfo" "dnssec-keygen" "egoapplykey" "egoconfig" "egogenkey" "egosh" "gmmpirun_wrapper" "init_energy" "initialize_eas" "intelmpi_wrapper" "lammpirun_wrapper" "lsacct" "lsacctmrg" "lsadmin" "lsclusters" "lseligible" "lsfrestart" "lsfshutdown" "lsfstartup" "lsgrun" "lshosts" "lsid" "lsinfo" "lsload" "lsloadadj" "lslockhost" "lslogin" "lsltasks" "lsmake" "lsmakerm" "lsmon" "lspasswd" "lsplace" "lsrcp" "lsreconfig" "lsrtasks" "lsrun" "lsrun.sh" "lstcsh" "lsunlockhost" "mpdstartup" "mpich2_wrapper" "mpich_mx_wrapper" "mpichp4_wrapper" "mpichsharemem_wrapper" "mpirun.lsf" "mvapich_wrapper" "openmpi_rankfile.sh" "openmpi_wrapper" "pam" "pipeclient" "pjllib.sh" "pmd_w" "poejob" "poe_w" "ppmsetvar" "preservestarter" "pvmjob" "qdel" "qjlist" "qlimit" "qmapmgr" "qmgr" "qothers" "qps" "qrestart" "qrun" "qsa" "qsnapshot" "qstat" "qsub" "qwatch" "sca_mpimon_wrapper" "TaskStarter" "tspeek" "tssub" "user_post_exec_prog" "user_pre_exec_prog" "xagent" "zapit")

for i in "${arr[@]}"
do
   touch "$i"
done

chmod -R +x *
# Perl LSF module checks for version. Use dummy.
echo ">&2 echo 'LSF 9.1.3.0'" > lsid

cd $current
