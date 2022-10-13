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
$deletetempfile = "$DBlogDir\${oraUnq}.dltemp"
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

cp "$virtMnt\$oraUnq\init${oraUnq}.ora.master" $initfile

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
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

log "Create spfile from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master FINISHED"

######### Startup mount VDB ###########

start_mount_pfile $initfile

######### open with reset log ########

db_open_resetlogs

######### add temp file ########

log "VDB add temp file STARTED"

$sqlQuery = @"
    WHENEVER SQLERROR EXIT SQL.SQLCODE
		ALTER TABLESPACE TEMP ADD TEMPFILE '$virtMnt\$oraUnq\temp01.dbf' size 1000M reuse;
		exit
"@

log "[SQL Query - add_temp_file] $sqlQuery"

$result = $sqlQuery | . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba"

log "[add_temp_file] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

log "VDB add temp file FINISHED"

######### VDB shutdown ######

shutdown "immediate"

######### Create spfile from pfile on mount path #########

log "Create spfile, $virtMnt\$oraUnq\spfile${oraUnq}.ora from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master STARTED"

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
create spfile='$virtMnt\$oraUnq\spfile${oraUnq}.ora' from pfile='$virtMnt\$oraUnq\init${oraUnq}.ora.master'
exit
"@

log "[SQL Query - crt_sp_file] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[crt_sp_file] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

log "Create spfile, $virtMnt\$oraUnq\spfile${oraUnq}.ora from pfile, $virtMnt\$oraUnq\init${oraUnq}.ora.master FINISHED"

######### VDB restart with spfile ######

shutdown "immediate"
startup

######### control file create #####

log "Moving ccf.sql file to ccf.sql.orig STARTED"

mv "$virtMnt\$oraUnq\ccf.sql" "$virtMnt\$oraUnq\ccf.sql.orig"

log "Moving ccf.sql file to ccf.sql.original FINISHED"

create_control_file $virtMnt $oraUnq

######### show database status ###########

get_db_status
