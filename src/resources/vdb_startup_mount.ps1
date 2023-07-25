#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_startup_mount.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraUnq = $env:ORA_UNQ_NAME
$oraDBName = $env:ORA_DB_NAME
$virtMnt = $env:VDB_MNT_PATH
$oraSrc = $env:ORA_SRC
$oraStg = $env:ORA_STG
$oraBase = $env:ORACLE_BASE
$oracleHome = $env:ORACLE_HOME
$srcType = $env:ORA_SRC_TYPE
$scriptDir = "${delphixToolkitPath}\scripts"
$virtMnt = $env:VDB_MNT_PATH

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

$Env:ORACLE_BASE=$oraBase
$Env:ORACLE_SID=$oraUnq
$Env:ORACLE_HOME=$oracleHome
$initfile = "${oracleHome}\database\init${oraUnq}.ora"

log "ORACLE_BASE: $oraBase"
log "ORACLE_HOME: $oracleHome"
log "ORACLE_SID: $oraUnq"

start_mount_pfile $initfile

######## remove autobackup and set controlfile snapshot to Delphix path ##############

log "[remove_autobackup] STARTED"

$rmanQuery = @"
    CONFIGURE CONTROLFILE AUTOBACKUP OFF;
    CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '%F';
    CONFIGURE SNAPSHOT CONTROLFILE NAME TO '$virtMnt\$oraUnq\snapcf_$oraUnq.f';
"@

log "[RMAN Query - remove_autobackup ] $rmanQuery"

$result = $rmanQuery | rman target /

log "[remove_autobackup] $result"