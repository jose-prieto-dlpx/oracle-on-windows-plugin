#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_rename_files.ps1'
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
$renamevdbfile = "$DBlogDir\${oraUnq}.rnm"
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

log "Rename VDB files script, $renamevdbfile STARTED"

#### Creating DB Log Directory

if(!(Test-Path $DBlogDir)) {
      md $DBlogDir
log "[Creating DBLogDir] md $DBlogDir"
}
else {
log "[DBLogDir Already Exists] $DBlogDir"
   }

# set powershell default encoding to UTF8
$PSDefaultParameterValues['*:Encoding'] = 'ascii'

### rename datafiles

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set linesize 500 heading off feedback off
col file_name format a200
select 'alter database rename file ''' ||name|| ''' to '||'''$virtMnt'||'\$oraUnq\'||SUBSTR(NAME,(INSTR(REPLACE(NAME,'/','\'),'\',-1)+1),LENGTH(NAME))||''';' filename from v`$datafile;

exit
"@

log "[SQL Query - rename_datafiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[rename_datafiles] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

echo $result > $renamevdbfile

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set linesize 500 heading off feedback off
col file_name format a200
select 'alter database rename file ''' ||member|| ''' to '||'''$virtMnt'||'\$oraUnq\'||SUBSTR(member,(INSTR(REPLACE(member,'/','\'),'\',-1)+1),LENGTH(member))||''';' member from v`$logfile;
exit
"@

log "[SQL Query - rename_logfiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[rename_logfiles] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

echo $result >> $renamevdbfile

$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
set linesize 500 heading off feedback off
col file_name format a200
select 'alter database rename file ''' ||name|| ''' to '||'''$virtMnt'||'\$oraUnq\'||SUBSTR(name,(INSTR(REPLACE(NAME,'/','\'),'\',-1)+1),LENGTH(name))||''';' name from v`$tempfile;
exit
"@

log "[SQL Query - rename_tempfiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[rename_tempfiles] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

echo $result >> $renamevdbfile
echo "exit" >> $renamevdbfile

## remove empty lines
remove_empty_lines $renamevdbfile

log "Rename VDB files script, $renamevdbfile FINISHED"

#### rename files

log "Executing rename VDB files script, $renamevdbfile STARTED"

$rename_files =  . $Env:ORACLE_HOME\bin\sqlplus.exe "/ as sysdba" "@$renamevdbfile"

log "[SQL- rename_files] $rename_files"

log "Executing rename VDB files script, $renamevdbfile FINISHED"
