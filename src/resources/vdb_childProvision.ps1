#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_childProvision.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraUnq = $env:ORA_UNQ_NAME
$oraDBName = $env:ORA_DB_NAME
$oraBase = $env:ORACLE_BASE
$oracleHome = $env:ORACLE_HOME
$virtMnt = $env:VDB_MNT_PATH
$oraVDBSrc = $env:ORA_VDB_SRC

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
log "PARENT_VDB: $oraVDBSrc"

$initfile = "${virtMnt}\${oraUnq}\init${oraUnq}.ora"
$masterinit = ${initfile}+".master"

$DBlogDir = ${delphixToolkitPath}+"\logs\"+${oraUnq}
$addtempfiles = "$DBlogDir\${oraUnq}_addtmpfiles.sql"

log "Provision Child VDB, $oraUnq STARTED"

$PSDefaultParameterValues['*:Encoding'] = 'ascii'

## copy master init to database

log "Copy master file ${masterinit} to $oracleHome\database\init${oraUnq}.ora"

if ((Test-Path "$oracleHome\database\init${oraUnq}.ora")) {
	Move-Item "$oracleHome\database\init${oraUnq}.ora" "$oracleHome\database\init${oraUnq}.ora.bak" -force
	Copy-Item ${masterinit} "$oracleHome\database\init${oraUnq}.ora"
}
else {
	Copy-Item ${masterinit} "$oracleHome\database\init${oraUnq}.ora"
}

######### Create new ccf.sql file ######

log "Moving ccf.sql file to ccf.sql.old STARTED"

$ccf_file_old = "$virtMnt\$oraUnq\ccf_old.sql"
$ccf_file_new = "$virtMnt\$oraUnq\CCF.SQL"

Move-Item $ccf_file_new $ccf_file_old -force

log "Moving ccf.sql file to ccf.sql.old FINISHED"

log "Create Script for new control file, $ccf_file_new STARTED"

extract_string "STARTUP NOMOUNT" ";" $ccf_file_old > $ccf_file_new
Write-Output ";" >> $ccf_file_new

(Get-Content -path $ccf_file_new -Raw) -replace 'REUSE DATABASE','REUSE SET DATABASE' | Set-Content -Path $ccf_file_new
(Get-Content -path $ccf_file_new -Raw) -replace 'NORESETLOGS','RESETLOGS' | Set-Content -Path $ccf_file_new
(Get-Content -path $ccf_file_new -Raw) -replace $oraVDBSrc, $oraUnq | Set-Content -Path $ccf_file_new

# Using a regular expression to replace any existing paths with the new VDB virtMnt path maintaining the original redo and datafiles
log "Chaging database file path to point to $virtMnt\$oraUnq"
(Get-Content -path $ccf_file_new -Raw) -replace "\'(.:.*\\)(.*)\'","'$virtMnt\$oraUnq\`$2'" | Set-Content -Path $ccf_file_new
(Get-Content -path $ccf_file_new -Raw) -replace '-- STANDBY LOGFILE','' | Set-Content -Path $ccf_file_new

# Adding line feeds after each ',' to prevent SQL*Plus error SP2-0027: Input is too long if there are a high number of datafiles
(Get-Content -path $ccf_file_new -Raw) -replace ',',", `r`n" | Set-Content -Path $ccf_file_new

remove_empty_lines $ccf_file_new

log "Create Script for new control file, $ccf_file_new FINISHED"

########### startup nomount #############

startup_nomount

###########  create control file ############

execute_ctrl_file $ccf_file_new

######### get database sate ##########

get_db_status

########## Perform Media recovery ##########

$logFiles = "$delphixToolkitPath\logs\$oraUnq\logFileslist.txt"

log "Extract Log Files for Child VDB, $logFiles STARTED"

 $sqlQuery=@"
 WHENEVER SQLERROR EXIT SQL.SQLCODE
 set serveroutput off
 set feedback off
 set heading off
 set echo off
 select member from v`$logfile order by group# ;
 exit
"@

log "[SQL Query - get_childVDB_LogFiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[SQL - get_childVDB_LogFiles] $result"

if ($LASTEXITCODE -ne 0){
	log "Extract Log files failed with ORA-$LASTEXITCODE"
	Write-Output "Extract Log files failed with ORA-$LASTEXITCODE"
	exit 1
	}
	
Write-Output $result > $logFiles

remove_empty_lines $logFiles

log "Extract Log Files for Child VDB, $logFiles FINISHED"

### apply each log for media recovery

$applyRedoLog = "$delphixToolkitPath\logs\$oraUnq\applyredo_$(get-date -Format yyyyMMddHHmm).log"

log "Perform Media Recovery for Child VDB, $oraUnq STARTED"

ForEach ($log in (Get-Content $logFiles))
{
Write-Output $log > $applyRedoLog
$sqlQuery=@"
RECOVER DATABASE USING BACKUP CONTROLFILE
$log
"@

log "[SQL Query - Media Recovery]: $sqlQuery"

$sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe " /as sysdba" > $applyRedoLog
}

$error_string=Select-String -Pattern "ORA-00279|ORA-00289|ORA-00280|ORA-00310|ORA-00334|ORA-00339" -Path $applyRedoLog -NotMatch | Select-String -Pattern "ORA-[0-9[0-9][0-9][0-9][0-9]"

if ($error_string) { 
    log "Media recovery command failed with $error_string"
	Write-Output "Media recovery command failed with $error_string"
    exit 1
} 

log "Media Recovery LogFile, $applyRedoLog"
log "Perform Media Recovery for Child VDB, $oraUnq FINISHED"

##### open db with reset logs ########

db_open_resetlogs


######### add temp files

log "VDB add temp files STARTED"

Write-Output "WHENEVER SQLERROR EXIT SQL.SQLCODE" > $addtempfiles

# Collecting temp files information from the control file
extract_string "-- Other tempfiles may require adjustment." "-- End of tempfile additions." $ccf_file_old >> $addtempfiles
(Get-Content -path $addtempfiles -Raw) -replace "\'(.:.*\\)(.*)\'","'$virtMnt\$oraUnq\`$2'" | Set-Content -Path $addtempfiles

Write-Output "exit" >> $addtempfiles

log "Executing add temp files script, $addtempfiles STARTED"

$add_temp_files =  . $Env:ORACLE_HOME\bin\sqlplus.exe "/ as sysdba" "@$addtempfiles"

log "[SQL- add_temp_files] $add_temp_files"
if ($LASTEXITCODE -ne 0){
	log "Add tempfiles query failed with ORA-$LASTEXITCODE"
	Write-Output "Add tempfiles query failed with ORA-$LASTEXITCODE"
	exit 1
	}
	

log "VDB add temp files FINISHED"



######### control file create #####

log "Moving ccf.sql file to ccf.sql.orig STARTED"

Move-Item "$virtMnt\$oraUnq\ccf.sql" "$virtMnt\$oraUnq\ccf_orig.sql" -force

log "Moving ccf.sql file to ccf.sql.original FINISHED"

create_control_file $virtMnt $oraUnq

####### get database state ##########

get_db_status

####### Create spfile and restart VDB #######

log "Checking if spfile is already in use STARTED"
$sqlQuery=@"
 WHENEVER SQLERROR EXIT SQL.SQLCODE
 set serveroutput off
 set feedback off
 set heading off
 set echo off
 select value from v`$parameter where name='spfile';
 exit
"@


$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[SQL - Check spfile use] $result"

if ($LASTEXITCODE -ne 0){
	log "Check spfile use failed with ORA-$LASTEXITCODE"
	Write-Output "Check spfile use failed with ORA-$LASTEXITCODE"
	exit 1
}

log "Checking if spfile is already in use FINISHED"

if ($result) {
	log "spfile already in use no further action required"
}
else {
	log "Create spfile from pfile, $oracleHome\database\init${oraUnq}.ora STARTED"


	if ((Test-Path "$oracleHome\database\spfile${oraUnq}.ora")) {
		Move-Item "$oracleHome\database\spfile${oraUnq}.ora" "$oracleHome\database\spfile${oraUnq}.ora.bak" -force	
	}


	$sqlQuery=@"
WHENEVER SQLERROR EXIT SQL.SQLCODE
create spfile from pfile='$oracleHome\database\init${oraUnq}.ora';
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

	log "Create spfile from pfile, $oracleHome\database\init${oraUnq}.ora FINISHED"

	log "Restarting VDB to use spfile"

	stop_OraService ${oraUnq} "srvc,inst" "immediate"
	start_OraService ${oraUnq} "srvc,inst"
}
log "Provision Child VDB, $oraUnq FINISHED"
