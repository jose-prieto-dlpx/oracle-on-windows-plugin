#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1

function remove_empty_lines(){

$file = $args[0]

log "Remove Empty lines, $file STARTED"

(Get-Content $file) | Where-Object {$_.trim() -ne "" } | set-content $file
$content = [System.IO.File]::ReadAllText($file)
$content = $content.Trim()
[System.IO.File]::WriteAllText($file, $content)

log "Remove Empty lines, $file FINISHED"
}

# set powershell default encoding to UTF8
$PSDefaultParameterValues['*:Encoding'] = 'ascii'

#### stop Oracle Service #####

function stop_OraService(){

  $oraUnq = $args[0]
  $type = $args[1]
  $shutmode = $args[2]

  log "Stopping of Oracle Service, $oraUnq STARTED"

  $stopSvc = . $oracleHome\bin\oradim.exe -shutdown -sid $oraUnq -SHUTTYPE $type -SHUTMODE $shutmode

  log "[Oracle Service, $oracleHome\bin\oradim.exe -shutdown -sid $oraUnq -SHUTTYPE $type -SHUTMODE $shutmode] $stopSvc"

  if ($stopSvc -like "*(OS 1060)*"){
      log "[Oracle Service Not Present] $oraUnq"
      exit 0
  }

  if ($stopSvc -like "*DIM-00015*"){
      log "[Oracle Service Already Stopped] $oraUnq"
      exit 0
  }

  $svc_status = check_srvc_status $oraUnq

  log "Service status is $svc_status"
  log "Stopping of Oracle Service, $oraUnq FINISHED"

}

#### start Oracle Service #####

function start_OraService(){

  $oraUnq = $args[0]
  $type = $args[1]

  log "Starting of Oracle Service, $oraUnq STARTED"

  $startSvc = . $oracleHome\bin\oradim.exe -startup -sid $oraUnq -STARTTYPE $type
  log "[Oracle Service, $oracleHome\bin\oradim.exe -startup -sid $oraUnq -STARTTYPE $type] $startSvc"

  if ($startSvc -like "*(OS 1060)*"){
      log "[Oracle Service Not Present] $oraUnq"
      exit 0
  }

  if ($startSvc -like "*DIM-00015*"){
      log "[Oracle Service Already Started] $oraUnq"
      exit 0
  }

  $svc_status = check_srvc_status $oraUnq

  log "Service status is $svc_status"
  log "Starting of Oracle Service, $oraUnq FINISHED"

}

function delete_OraService(){

  $oraUnq = $args[0]

  log "Deletion of Oracle Service, $oraUnq STARTED"

  $delSvc = . $oracleHome\bin\oradim.exe -delete -sid $oraUnq
  log "[Oracle Service, $oracleHome\bin\oradim.exe -delete -sid $oraUnq] $delSvc"

  if ($delSvc -like "*(OS 1060)*"){
      log "[Oracle Service Not Present] $oraUnq"
      exit 0
  }

  log "Deletion of Oracle Service, $oraUnq FINISHED"

}

function create_OraService(){

  $oraUnq = $args[0]
  $oraUser = $args[1]
  $oraPwd = $args[2]

  log "Creation of Oracle Service, $oraUnq STARTED"

  $crtSvc = . $oracleHome\bin\oradim.exe -new -sid $oraUnq -RUNAS $oraUser/$oraPwd -spfile
  log "[Oracle Service, $oracleHome\bin\oradim.exe -new -sid $oraUnq -RUNAS $oraUser/***** -spfile] $crtSvc"

  if ($crtSvc -like "*(OS 1073)*"){
      log "[Oracle Service Already Exists - recreating it] $oraUnq"

      delete_OraService $oraUnq
      $crtSvc = . $oracleHome\bin\oradim.exe -new -sid $oraUnq -RUNAS $oraUser/$oraPwd -spfile
      log "[Oracle Service, $oracleHome\bin\oradim.exe -new -sid $oraUnq -RUNAS $oraUser/***** -spfile] $crtSvc"
    
  }

  $svc_status = check_srvc_status $oraUnq

  log "Service status after creation is $svc_status"

  log "Creation of Oracle Service, $oraUnq FINISHED"

}

function check_srvc_status(){

$oraUnq=$args[0]

log "Checking Status of Oracle Service, $oraUnq STARTED"

$svcName="OracleService$oraUnq"

$svcStatus = (Get-Service -name ${svcName}).Status

log "Status of Oracle Service, $oraUnq - $svcStatus"

log "Checking Status of Oracle Service, $oraUnq FINISHED"

return $svcStatus

}

function startup_mount(){

log "Startup Mount database, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set NewPage none
set heading off
set feedback off
startup mount;
exit
"@

log "[SQL Query - startup_mount] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[startup_mount] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Startup Mount database, $oraUnq FINISHED"

}

function startup(){

log "Startup database, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set NewPage none
set heading off
set feedback off
startup;
exit
"@

log "[SQL Query - startup] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[startup] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Startup database, $oraUnq FINISHED"

}

function shutdown(){

$shutdowntype = $args[0]

log "Shutdown $shutdowntype database, $oraUnq STARTED"

$sqlQuery=@"
set NewPage none
set heading off
set feedback off
shutdown $shutdowntype;
exit
"@

log "[SQL Query - shutdown] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[shutdown] $result"

log "Shutdown $shutdowntype database, $oraUnq FINISHED"

}
 
function get_db_status(){

log "Getting database status, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set lines 100
col instance_name format a20 wrap
col name format a20 wrap
col open_mode format a20 wrap
col status format a20 wrap
select instance_name,name,open_mode,status from gv`$instance, v`$database order by instance_name;
exit;
"@

log "[SQL Query - get_db_status] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[SQL - get_db_status] $result"

log "Getting database status, $oraUnq FINISHED"
}

function alter_db_ro(){

log "Alter DB Open ReadOnly, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database open read only;
exit
"@

log "[SQL Query - open_readonly] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[open_readonly] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Alter DB Open ReadOnly, $oraUnq FINISHED"
}

function start_mount_pfile(){

$initfile = $args[0]

log "Startup Mount, $oraUnq with pFile, $initfile STARTED"

$sqlQuery = @"
    WHENEVER SQLERROR EXIT SQL.SQLCODE
		set NewPage none
		set heading off
		startup mount pfile='${initfile}'
		exit
"@

log "[SQL Query - sql_start_mount] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[start_mount] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Startup Mount, $oraUnq with pFile, $initfile FINISHED"
}

function start_mount_exclusive_restrict(){

log "Startup Mount Exclusive Restrict, $oraUnq STARTED"

$sqlQuery = @"
    WHENEVER SQLERROR EXIT SQL.SQLCODE
		set NewPage none
		set heading off
		startup mount exclusive restrict;
		exit
"@

log "[SQL Query - startup_mount_restrict] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[startup_mount_restrict] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Startup Mount Exclusive Restrict, $oraUnq FINISHED"

}

function disable_flashback(){

log "Disable Flashback on DB, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database flashback off;
exit
"@

log "[SQL Query - disable_flashback] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[disable_flashback] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Disable Flashback on DB, $oraUnq FINISHED"

}

function db_open_resetlogs(){

log "Open DB, $oraUnq with resetlogs STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database open resetlogs;
exit
"@

log "[SQL Query - open_resetlogs] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[open_resetlogs] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Open DB, $oraUnq with resetlogs FINISHED"

}

function create_control_file(){

$DLPX_MOUNT_POINT = $args[0]
$DB_NAME = $args[1]

log "Create Control file, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database backup controlfile to trace as '${DLPX_MOUNT_POINT}\${DB_NAME}\ccf.sql';
exit
"@

log "[SQL Query - crt_ctrl_file] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[crt_ctrl_file] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Create Control file, $oraUnq FINISHED"

}

function extract_string(){

$firstString = $args[0]
$secondString = $args[1]
$importPath = $args[2]

log "Extract content from file, $importPath STARTED"

$file = Get-Content $importPath -Raw

$pattern = "(?s)$firstString(.*?)$secondString"

$result = [regex]::Match($file,$pattern).Groups[1].Value

return $result

log "Extract content from file, $importPath FINISHED"

}

function startup_nomount(){

log "Startup NoMount database, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set NewPage none
set heading off
set feedback off
startup nomount;
exit
"@

log "[SQL Query - startup_nomount] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[startup_nomount] $result"

if ($LASTEXITCODE -ne 0){
  log "Startup nomount failed with ORA-$LASTEXITCODE"
  Write-Output "Startup nomount failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Startup NoMount database, $oraUnq FINISHED"

}

function execute_ctrl_file(){

$controlFileSql = $args[0]

log "Execute control File, $controlFileSql STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
@"$controlFileSql"
exit
"@

log "[SQL Query - crt_ctrl_file] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[crt_ctrl_file] $result"

if ($LASTEXITCODE -ne 0){
  log "Control file creation failed with ORA-$LASTEXITCODE"
  Write-Output "Control file creation failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Execute control File, $controlFileSql FINISHED"

}

function vdb_disable_archivelog(){

log "Alter VDB for noarchivelog, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database noarchivelog;
exit
"@

log "[SQL Query - disable_archivelog] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[disable_archivelog] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Alter VDB for noarchivelog, $oraUnq FINISHED"

}

function disable_bct(){

log "Disable BCT on DB, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database disable BLOCK CHANGE TRACKING;
exit
"@

log "[SQL Query - disable_bct] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[disable_bct] $result"

log "Disable BCT on DB, $oraUnq FINISHED"

}

function standby_max_perf(){

log "Set Standby to Max Performance on DB, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter database set standby database to maximize performance;
select * from dual;
exit
"@

log "[SQL Query - max_perf] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[max_perf] $result"

if ($LASTEXITCODE -ne 0){
  log "Sql Query failed with ORA-$LASTEXITCODE"
  Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
  exit 1
}

log "Set Standby to Max Performance on DB, $oraUnq FINISHED"

}

function get_db_version() {

log "Getting database version, $oraUnq STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set newpage 0; 
set echo off; 
set feedback off; 
set heading off; 
set trimout on;
set trimspool on; 
col version format a10 wrap
SELECT CASE WHEN BANNER like '%Standard%' THEN 'STANDARD'
            WHEN BANNER like '%Enterprise%' THEN 'ENTERPRISE'
       ELSE 'OTHER' END as version
FROM v`$version
WHERE rownum < 2;
exit
"@
  
log "[SQL Query - get_db_version] $sqlQuery"
  
$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"
  
log "[SQL - get_db_version] $result"
  
log "Getting database version, $oraUn FINISHED"

return $result
}

function switchlogfiles() {
log "Switching all redo log files STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
alter system switch all logfile;
exit
"@
  
log "[SQL Query - switch redo log files] $sqlQuery"
  
$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"
  
log "[SQL - switch redo log files] $result"

if ($LASTEXITCODE -ne 0){
  log "Redo log switch commad failed with ORA-$LASTEXITCODE"
  Write-Output "Redo log switch commad failed with ORA-$LASTEXITCODE"
  exit 1
  }
  
  
log "Switching all redo log files FINISHED"
  
}