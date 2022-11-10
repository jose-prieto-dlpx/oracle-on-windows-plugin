#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_finalize.ps1'
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
$DBlogDir = ${delphixToolkitPath}+"\logs\"+${oraUnq}
$addtempfile = "$DBlogDir\${oraUnq}.addtemp"
$nid_log = "$DBlogDir\${oraUnq}_nid.log"
$scriptDir = "${delphixToolkitPath}\scripts"

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

######### VDB mount with pfile ######

log "Updating init${oraUnq}.ora.master file STARTED"

(Get-Content -path $virtMnt\$oraUnq\init${oraUnq}.ora.master -Raw) -replace "db_name=${oraSrc}","db_name=${oraUnq}" | Set-Content -Path $virtMnt\$oraUnq\init${oraUnq}.ora.master

log "Updating init${oraUnq}.ora.master file FINISHED"

log "Copying init${oraUnq}.ora.master file to $initfile STARTED"

Copy-Item "$virtMnt\$oraUnq\init${oraUnq}.ora.master" $initfile

log "Copying init${oraUnq}.ora.master file to $initfile FINISHED"

######### Create spfile from pfile #########
log "Create spfile from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
create spfile from pfile='$virtMnt\$oraUnq\init${oraUnq}.ora.master'
exit
"@

log "[SQL Query - crt_sp_file] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[crt_sp_file] $result"

if ($LASTEXITCODE -ne 0){
Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

log "Create spfile from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master FINISHED"

######### Startup mount VDB ###########

start_mount_pfile $initfile

######### open with reset log ########

db_open_resetlogs

######### add temp file ########

log "Adding back temporary files to VDB"

$PSDefaultParameterValues['*:Encoding'] = 'ascii'

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set linesize 200 heading off feedback off
col cmd format a200
select 'alter tablespace '||tablespace_name||' add tempfile ''$virtMnt\$oraUnq\'||tablespace_name||'_01.dbf'' size 1000M reuse autoextend on;' as cmd 
from dba_tablespaces 
where contents='TEMPORARY';
exit
"@

log "[SQL Query - add_temp_files] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[add_temp_files] $result"

if ($LASTEXITCODE -ne 0){
    Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

Write-Output $result > $addtempfile
Write-Output "exit" >> $addtempfile

## remove empty lines
remove_empty_lines $addtempfile

#### Executing add temp files

log "Executing add temp files script, $addtempfile STARTED"

$add_temp =  . $Env:ORACLE_HOME\bin\sqlplus.exe "/ as sysdba" "@$addtempfile"

log "[SQL- add_temp_files] $add_temp"

log "Executing add temp files script, $addtempfile FINISHED"


######### VDB shutdown ######

shutdown "immediate"

######### Create spfile from pfile on mount path #########

log "Create spfile, $virtMnt\$oraUnq\spfile${oraUnq}.ora from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
create spfile='$virtMnt\$oraUnq\spfile${oraUnq}.ora' from pfile='$virtMnt\$oraUnq\init${oraUnq}.ora.master';
exit
"@

log "[SQL Query - crt_sp_file] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[crt_sp_file] $result"

if ($LASTEXITCODE -ne 0){
Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

log "Create spfile, $virtMnt\$oraUnq\spfile${oraUnq}.ora from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master FINISHED"

log "Copying spfile $virtMnt\$oraUnq\spfile${oraUnq}.ora to Oracle home $oracleHome\database\ STARTED"

if ((Test-Path "$oracleHome\database\spfile${oraUnq}.ora")) {
	Move-Item "$oracleHome\database\spfile${oraUnq}.ora" "$oracleHome\database\spfile${oraUnq}.ora.bak" -force	
}

Copy-Item "$virtMnt\$oraUnq\spfile${oraUnq}.ora" "$oracleHome\database\spfile${oraUnq}.ora"

log "Copying spfile $virtMnt\$oraUnq\spfile${oraUnq}.ora to Oracle home $oracleHome\database\ FINISHED"

######### VDB restart with spfile ######

stop_OraService ${oraUnq} "srvc,inst" "immediate"
start_OraService ${oraUnq} "srvc,inst"

######### control file create #####

log "Moving ccf.sql file to ccf.sql.orig STARTED"

Move-Item "$virtMnt\$oraUnq\ccf.sql" "$virtMnt\$oraUnq\ccf.sql.orig"

log "Moving ccf.sql file to ccf.sql.original FINISHED"

create_control_file $virtMnt $oraUnq

######### show database status ###########

get_db_status
