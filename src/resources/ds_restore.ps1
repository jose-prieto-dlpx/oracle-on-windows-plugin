#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'ds_restore.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oracleHome = $env:ORACLE_HOME
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraBase = $env:ORACLE_BASE
$oraBkpLoc = $env:ORACLE_BKP_LOC
$stgMnt = $env:STG_MNT_PATH
$oraDbid = $env:ORACLE_DBID
$oraSrc = $env:ORA_SRC
$oraUnq = $env:ORA_UNQ_NAME
$DBlogDir = ${delphixToolkitPath}+"\logs\"+${oraUnq}
$restorecmdfile = "$DBlogDir\${oraUnq}.rstr"
$renamelogtempfile = "$DBlogDir\${oraUnq}.rnm"
$recovercmdfile = "$DBlogDir\${oraUnq}.rcv"

$scriptDir = "${delphixToolkitPath}\scripts"

$Env:ORACLE_BASE=$oraBase
$Env:ORACLE_SID=$oraUnq
$Env:ORACLE_HOME=$oracleHome

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

log "Backup restore of $oraUnq STARTED"

### restore rman backup
$rman_restore = rman target / cmdfile="'$restorecmdfile'"

log "[RMAN- rman_restore] $rman_restore"

$error_string=$rman_restore | select-string -Pattern "RMAN-[0-9[0-9][0-9][0-9][0-9]"

if ($error_string) { 
    log "RMAN restore failed with $error_string"
    exit 1
} 


##### recover database

$rman_recover = rman target / cmdfile="'$recovercmdfile'"

log "[RMAN- rman_recover] $rman_recover"

$error_string=$rman_recover | select-string -Pattern "RMAN-[0-9[0-9][0-9][0-9][0-9]"

if ($error_string) { 
    log "RMAN recover failed with $error_string"
    exit 1
} 


#### disable BCT

disable_bct

#### rename log and temp files

$rename_files = . $Env:ORACLE_HOME\bin\sqlplus.exe "/ as sysdba" "@$renamelogtempfile"

log "[SQL- rename_files] $rename_files"

if ($LASTEXITCODE -ne 0){
    log "Rename files action failed with ORA-$LASTEXITCODE"
    exit 1
    }
    

$versiondb = get_db_version

if (($versiondb -eq "ENTERPRISE" )) {

#### set standby to maximize performance

standby_max_perf

}

######### open database readonly ######

alter_db_ro

######### shutdown and mount

shutdown "immediate"

startup_mount

######### get dSource status #####

get_db_status

######### control file create #####

log "Moving $stgMnt\$oraSrc\ccf.sql file to $stgMnt\$oraSrc\ccf.sql.ds.orig STARTED"

if ((Test-Path "$stgMnt\$oraSrc\ccf.sql")) {
log "old $stgMnt\$oraSrc\ccf.sql file exists"
log "mv $stgMnt\$oraSrc\ccf.sql $stgMnt\$oraSrc\ccf.sql.ds.orig -force"
mv "$stgMnt\$oraSrc\ccf.sql" "$stgMnt\$oraSrc\ccf.sql.ds.orig" -force
}

log "Moving ccf.sql file to ccf.sql.ds.orig FINISHED"

create_control_file $stgMnt $oraSrc

log "Backup restore of $oraUnq FINISHED"
