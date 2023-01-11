#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'ds_restore_controlfile.ps1'
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

$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

# set powershell default encoding to UTF8
$PSDefaultParameterValues['*:Encoding'] = 'ascii'

$Env:ORACLE_BASE=$oraBase
$Env:ORACLE_SID=$oraUnq
$Env:ORACLE_HOME=$oracleHome
$initfile = "$oracleHome\database\init${oraUnq}.ora"

log "ORACLE_BASE: $oraBase"
log "ORACLE_HOME: $oracleHome"
log "ORACLE_SID: $oraUnq"

$oraCtrlbkp = $oraBkpLoc+"\"+$oraCtrlbkp

log "Restore ControlFile from backup, $oraCtrlbkp STARTED"

$rmanQuery = @"
		set DBID=$oraDbid;
    restore controlfile from '$oraCtrlbkp';
    alter database mount;
"@

log "[RMAN Query - restore_ctrlfile_backup] $rmanQuery"

$result = $rmanQuery | rman target /

log "[restore_ctrlfile_backup] $result"

$error_string=$result | select-string -Pattern "RMAN-[0-9[0-9][0-9][0-9][0-9]"

if ($error_string) { 
    log "RMAN restore controlfile failed with $error_string"
    exit 1
} 


##### move existing to last
if (Test-Path $stgMnt\$oraSrc\new_ctl_bkp_piece.txt) {
mv $stgMnt\$oraSrc\new_ctl_bkp_piece.txt $stgMnt\$oraSrc\last_ctl_bkp_piece.txt -force
}

echo $oraCtrlbkp > "$stgMnt\$oraSrc\new_ctl_bkp_piece.txt"

remove_empty_lines "$stgMnt\$oraSrc\new_ctl_bkp_piece.txt"

log "Restore ControlFile from backup, $oraCtrlbkp FINISHED"

######### get dSource status #####

get_db_status

######## get undo tablespaces list #######

log "Get Undo TBS list, $oraUnq STARTED"

$sqlQuery = @"
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    set serveroutput off
    set feedback off
    set heading off
    set echo off
    set NewPage none
    SELECT SUBSTR (SYS_CONNECT_BY_PATH (NAME , ','), 2) csv FROM (SELECT B.NAME , ROW_NUMBER () OVER (ORDER BY B.NAME ) rn, COUNT (*) OVER () cnt from v`$tablespace B where upper(B.NAME) like 'UNDO%') WHERE rn = cnt START WITH rn = 1 CONNECT BY rn = PRIOR rn + 1;
		exit
"@

log "[SQL Query - sql_get_undo_tbs] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe -silent  " /as sysdba"

log "[get_undo_tbs] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

if ([string]::IsNullOrEmpty($result))
{
  log "No UNDO% tablespace found"
	exit 0
}
else
{
	$first_undo = $result.split(",")[0]
	echo "${oraUnq}.undo_tablespace='$first_undo'" >> ${initfile}
}

log "Get Undo TBS list, $oraUnq FINISHED"

$newinitOra = Get-Content $initfile

log "Contents of new init.ora, $newinitOra"
