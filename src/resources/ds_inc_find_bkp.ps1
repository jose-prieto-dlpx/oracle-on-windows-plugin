#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'ds_inc_find_bkp.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oracleHome = $env:ORACLE_HOME
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraBase = $env:ORACLE_BASE
$oraDbid = $env:ORACLE_DBID
$oraUnq = $env:ORA_UNQ_NAME
$stgMnt = $env:STG_MNT_PATH
$oraSrc = $env:ORA_SRC
$oraBkpLoc = $env:ORACLE_BKP_LOC
$oraCtrlbkp = $env:ORACLE_CTRL_FILE_BKP
$DBlogDir = ${delphixToolkitPath}+"\logs\"+${oraUnq}

$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

if((Test-Path "$stgMnt\$oraSrc\last_ctl_bkp_piece.txt")) {
$lastCtlBkp=Get-Content "$stgMnt\$oraSrc\last_ctl_bkp_piece.txt"
}
else {$lastCtlBkp=""}

if((Test-Path "$stgMnt\$oraSrc\last_ctl_bkp_endscn.txt")) {
$lastEndScn=Get-Content "$stgMnt\$oraSrc\last_ctl_bkp_endscn.txt"
}
else {$lastEndScn=""}

if((Test-Path "$stgMnt\$oraSrc\last_ctl_bkp_endtime.txt")) {
$lastEndTime=Get-Content "$stgMnt\$oraSrc\last_ctl_bkp_endtime.txt"
}
else {$lastEndTime=""}

$Env:ORACLE_BASE=$oraBase
$Env:ORACLE_SID=$oraUnq
$Env:ORACLE_HOME=$oracleHome
$initfile = "$oracleHome\database\init${oraUnq}.ora"

log "ORACLE_BASE: $oraBase"
log "ORACLE_HOME: $oracleHome"
log "ORACLE_SID: $oraUnq"

log "Catalog to backup location, $oraBkpLoc STARTED"

log "LAST_CTRL_BKP: $lastCtlBkp"
log "LAST_END_SCN: $lastEndScn"
log "LAST_END_TIME: $lastEndTime"

$rmanQuery = @"
		catalog start with '$oraBkpLoc\' noprompt;
"@

log "[RMAN Query - catalog_bkploc] $rmanQuery"

$result = $rmanQuery | rman target /

log "[catalog_bkploc] $result"

$error_string=$result | select-string -Pattern "RMAN-[0-9[0-9][0-9][0-9][0-9]"

if ($error_string) { 
    log "RMAN catalog command failed with $error_string"
    exit 1
} 


log "Catalog to backup location, $oraBkpLoc FINISHED"

## get new control file backup

log "Get New CTRL File BKP from backup location, $oraBkpLoc STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set serveroutput off
set feedback off
set heading off
set echo off
set NewPage none
select handle from (SELECT DISTINCT replace(HANDLE,chr(10)) HANDLE, rank() over (order by b.set_stamp desc) latest from V`$BACKUP_CONTROLFILE_DETAILS A, V`$BACKUP_PIECE_DETAILS B where A.BTYPE_KEY = B.BS_KEY and A.ID1 = B.SET_STAMP and A.ID2 = B.SET_COUNT and  CHECKPOINT_TIME = (select max(CHECKPOINT_TIME) from V`$BACKUP_CONTROLFILE_DETAILS C, V`$BACKUP_PIECE_DETAILS D where C.BTYPE_KEY = D.BS_KEY and C.ID1 = D.SET_STAMP and C.ID2 = D.SET_COUNT and D.HANDLE like UPPER('$oraBkpLoc\%')) and HANDLE like UPPER('$oraBkpLoc\%'))  where latest=1;
exit
"@

log "[SQL Query - get_new_ctl_file] $sqlQuery"

$new_ctl_bkp = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

$new_ctl_bkp=$new_ctl_bkp.trim()

log "[get_new_ctl_file] $new_ctl_bkp"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

##### move existing to last
mv $stgMnt\$oraSrc\new_ctl_bkp_piece.txt $stgMnt\$oraSrc\last_ctl_bkp_piece.txt -force

echo $new_ctl_bkp > "$stgMnt\$oraSrc\new_ctl_bkp_piece.txt"

remove_empty_lines "$stgMnt\$oraSrc\new_ctl_bkp_piece.txt"

if ($new_ctl_bkp -eq $lastCtlBkp){
	log "!!!! No New Full/Differential Backup Found !!!!"
	echo "NoNewBackup"
exit 0
}

log "Get New CTRL File BKP from backup location, $oraBkpLoc FINISHED"

##### get list of existing datafiles

log "Get Pre DataFiles, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set serveroutput off
 set feedback off
 set heading off
 set echo off
 set NewPage none
select file# from v`$datafile order by 1;
"@

log "[SQL Query - get_pre_datafiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"
$result = $result -replace '\s',''
log "[get_pre_datafiles] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

echo $result > "$DBlogDir\pre_datafiles.txt"

log "Get Pre DataFiles, $oraUnq FINISHED"

##### shutdown database

shutdown "immediate"

#####

log "Backing up existing control file, $stgMnt\$oraSrc\CONTROL01.CTL STARTED"

mv $stgMnt\$oraSrc\CONTROL01.CTL $stgMnt\$oraSrc\CONTROL01.CTL.bak -force

log "mv $stgMnt\$oraSrc\CONTROL01.CTL $stgMnt\$oraSrc\CONTROL01.CTL.bak -force"

log "Backing up existing control file, $stgMnt\$oraSrc\CONTROL01.CTL FINISHED"

###### startup nomount

startup_nomount

###### restore new control file backup

log "Restore ControlFile from new backup, $new_ctl_bkp STARTED"

$rmanQuery = @"
    set echo on
		set DBID=$oraDbid;
    restore controlfile from '$new_ctl_bkp';
    alter database mount;
"@

log "[RMAN Query - restore_new_ctrlfile_backup] $rmanQuery"

$result = $rmanQuery | rman target /

log "[restore_new_ctrlfile_backup] $result"

$error_string=$result | select-string -Pattern "RMAN-[0-9[0-9][0-9][0-9][0-9]"

if ($error_string) { 
    log "RMAN restore controlfile command failed with $error_string"
    exit 1
} 


log "Restore ControlFile from new backup, $new_ctl_bkp FINISHED"

disable_flashback
