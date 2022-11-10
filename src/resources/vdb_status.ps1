#
# Copyright (c) 2021 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_status.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraUnq = $env:ORA_UNQ_NAME
$oraDBName = $env:ORA_DB_NAME
$oraBase = $env:ORACLE_BASE
$oracleHome = $env:ORACLE_HOME

$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

$Env:ORACLE_BASE=$oraBase
$Env:ORACLE_SID=$oraUnq
$Env:ORACLE_HOME=$oracleHome

log "ORACLE_BASE: $oraBase"
log "ORACLE_HOME: $oracleHome"
log "ORACLE_SID: $oraUnq"

######### VDB Status ######

log "Status VDB, $oraUnq STARTED"

$srvc_status = check_srvc_status $oraUnq

log "Status of $oraUnq Service, $srvc_status"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set serveroutput off
set feedback off
set heading off
set echo off
select open_mode from v`$database;
exit
"@

log "[SQL Query - vdb_status] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[SQL - vdb_status] $result"

if (($result -eq "READ WRITE") -and ($srvc_status -eq "Running")) {
  Write-Output "ACTIVE"
}
else {
   Write-Output "INACTIVE"
}

exit 0
