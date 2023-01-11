#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_finalize.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraUnq = $env:ORA_UNQ_NAME
$virtMnt = $env:VDB_MNT_PATH
$oraSrc = $env:ORA_SRC
$oraBase = $env:ORACLE_BASE
$oracleHome = $env:ORACLE_HOME
$DBlogDir = ${delphixToolkitPath}+"\logs\"+${oraUnq}
$addtempfiles = "$DBlogDir\${oraUnq}_addtmpfiles.sql"


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
	log "Sql Query failed with ORA-$LASTEXITCODE"
	Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
	exit 1
}

log "Create spfile from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master FINISHED"

######### Startup mount VDB ###########

start_mount_pfile $initfile

######### open with reset log ########

db_open_resetlogs

######### add temp files ########

log "VDB add temp files STARTED"

Write-Output "WHENEVER SQLERROR EXIT SQL.SQLCODE" > $addtempfiles

$sqlQuery = @"
    whenever sqlerror exit sql.sqlcode
	set linesize 500 heading off feedback off pages 0
	col sqlcode format a500	
	select 'alter tablespace '||tsnam||' add tempfile ''$virtmnt\$oraunq\'||tsnam||'_01.dbf'' size 1000m reuse;' as sqlcode from x`$kccts where bitand(tsflg, 1+2) = 1 and tstsn <> -1 order by 1;
	exit
"@

log "[SQL Query - add_temp_file_script] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[add_temp_file_script] $result"
if ($LASTEXITCODE -ne 0){
	log "Sql Query failed with ORA-$LASTEXITCODE"
	Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
	exit 1
}


Write-Output $result >> $addtempfiles
Write-Output exit >> $addtempfiles

remove_empty_lines $addtempfiles

log "Executing add temp files script, $addtempfiles STARTED"

$add_temp_files =  . $Env:ORACLE_HOME\bin\sqlplus.exe "/ as sysdba" "@$addtempfiles"

log "[SQL- add_temp_files] $add_temp_files"
if ($LASTEXITCODE -ne 0){
	log "Sql Query failed with ORA-$LASTEXITCODE"
	Write-Output "Sql Query failed with ORA-$LASTEXITCODE"
	exit 1
	}
	

log "VDB add temp files FINISHED"

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
	log "Sql Query failed with ORA-$LASTEXITCODE"
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

######### show database status ###########

get_db_status
