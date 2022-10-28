#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'ds_crtRestoreScripts.ps1'
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
$rmanChannels = $env:RMAN_CHANNELS
$DBlogDir = ${delphixToolkitPath}+"\logs\"+${oraUnq}
$restorecmdfile = "$DBlogDir\${oraUnq}.rstr"
$renamelogtempfile = "$DBlogDir\${oraUnq}.rnm"
$recovercmdfile = "$DBlogDir\${oraUnq}.rcv"

$scriptDir = "${delphixToolkitPath}\scripts"

$Env:ORACLE_BASE=$oraBase
$Env:ORACLE_SID=$oraInstName
$Env:ORACLE_HOME=$oracleHome

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

log "ORACLE_HOME: $oracleHome"
log "ORACLE_SID: $oraInstName"
log "ORACLE_USER: $oraUser"
log "ORACLE_BASE: $oraBase"
log "ORACLE_BKP_LOC: $oraBkpLoc"
log "STG_MNT_PATH: $stgMnt"
log "ORACLE_DBID: $oraDbid"
log "ORACLE_SRC_NAME: $oraSrc"
log "DB_LOG_DIR: $DBlogDir"
log "RESTORE_FILE: $restorecmdfile"
log "RENAME_LOG_TEMP_FILE: $renamelogtempfile"
log "RECOVERY_FILE: $recovercmdfile"

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


 #### there are two reasons for connecting to RMAN
 #### 1) v$rman views might not be present in a mounted database unless you first connect to it with RMAN

 $testRman ='exit;' 

 $result = $testRman | . $Env:ORACLE_HOME\bin\rman.exe target /

 #### 2) the control file might have some SBT backups in its catalog, which will cause error during restore
 $testRman =@"
 allocate channel for maintenance device type sbt parms 'SBT_LIBRARY=oracle.disksbt, ENV=(BACKUP_DIR=c:\tmp)';
 delete force noprompt obsolete device type SBT;
 crosscheck backup;
 delete force noprompt expired backup device type SBT;
 crosscheck backup;
 delete force nonprompt backup device type SBT;
 exit
"@ 

 $result = $testRman | . $Env:ORACLE_HOME\bin\rman.exe target /

 #### get end time 
 $sqlQuery=@"
 WHENEVER SQLERROR EXIT SQL.SQLCODE
 set serveroutput off
 set feedback off
 set heading off
 set echo off
 set NewPage none
 select to_char(max(END_TIME),'dd-mon-yyyy hh24:mi:ss') end_time from V`$RMAN_BACKUP_JOB_DETAILS where INPUT_TYPE in ('DB FULL','DB INCR') and status in ('COMPLETED','COMPLETED WITH WARNINGS');
 exit
"@

log "[SQL Query - get_end_time] $sqlQuery"

$end_time = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[end_time] $end_time"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

##### move existing to last
if (Test-Path $stgMnt\$oraSrc\new_ctl_bkp_endtime.txt) {
mv $stgMnt\$oraSrc\new_ctl_bkp_endtime.txt $stgMnt\$oraSrc\last_ctl_bkp_endtime.txt -force
}

echo $end_time > "$stgMnt\$oraSrc\new_ctl_bkp_endtime.txt"

remove_empty_lines "$stgMnt\$oraSrc\new_ctl_bkp_endtime.txt"

#### get end scn
 $sqlQuery=@"
 WHENEVER SQLERROR EXIT SQL.SQLCODE
 set serveroutput off
 set feedback off
 set heading off
 set echo off
 set NewPage none
 set numwidth 40
 select (greatest(max(absolute_fuzzy_change#),max(checkpoint_change#))) "endscn" from ( select file#, completion_time, checkpoint_change#, absolute_fuzzy_change# from v`$backup_datafile, ( select  max(start_TIME) start_time, max(END_TIME) end_time  from v`$RMAN_BACKUP_JOB_DETAILS  where INPUT_TYPE in ('DB FULL','DB INCR')  and status in ('COMPLETED','COMPLETED WITH WARNINGS') ) tsdata where ( incremental_level in (0, 1) OR incremental_level is null ) and file# <> 0 and completion_time between tsdata.start_time and tsdata.end_time and checkpoint_time between tsdata.start_time and tsdata.end_time order by completion_time desc ); 
 exit
"@

log "[SQL Query - get_end_scn] $sqlQuery"

$end_scn = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

$end_scn = $end_scn -replace '\s',''
log "[end_scn] $end_scn"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

##### move existing to last
if (Test-Path $stgMnt\$oraSrc\new_ctl_bkp_endscn.txt) {
mv $stgMnt\$oraSrc\new_ctl_bkp_endscn.txt $stgMnt\$oraSrc\last_ctl_bkp_endscn.txt -force
}

echo $end_scn > "$stgMnt\$oraSrc\new_ctl_bkp_endscn.txt"

remove_empty_lines "$stgMnt\$oraSrc\new_ctl_bkp_endscn.txt"

#### Create RMAN restore script

log "Creating Restore Scripts, $restorecmdfile STARTED"

echo "crosscheck backup;" > $restorecmdfile
echo "delete force noprompt expired backup;" >> $restorecmdfile
echo "catalog start with '$oraBkpLoc\' noprompt;" >> $restorecmdfile
echo "crosscheck backup;" >> $restorecmdfile
echo "set echo on" >> $restorecmdfile
echo "RUN" >> $restorecmdfile
echo "{" >> $restorecmdfile
for ($i=1; $i -le $rmanChannels; $i=$i+1)
{echo "ALLOCATE CHANNEL T${i} DEVICE TYPE disk;" >> $restorecmdfile}
#echo "ALLOCATE CHANNEL T1 DEVICE TYPE disk;" >> $restorecmdfile
#echo "ALLOCATE CHANNEL T2 DEVICE TYPE disk;" >> $restorecmdfile

### rename datafiles

 $sqlQuery=@"
 WHENEVER SQLERROR EXIT SQL.SQLCODE
 set linesize 200 heading off feedback off
 col file_name format a200
select 'set newname for datafile ' ||FILE#|| ' to '||'''$stgMnt'||'\$oraSrc\'||SUBSTR(NAME,(INSTR(REPLACE(NAME,'/','\'),'\',-1)+1),LENGTH(NAME))||''';' filename from v`$datafile;
exit
"@

log "[SQL Query - rename_datafiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[rename_datafiles] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

echo $result >> $restorecmdfile

echo "SET UNTIL SCN $end_scn;" >> $restorecmdfile

echo "RESTORE DATABASE;" >> $restorecmdfile
echo "SWITCH DATAFILE ALL;" >> $restorecmdfile
for ($i=1; $i -le $rmanChannels; $i=$i+1)
{echo "RELEASE CHANNEL T${i};" >> $restorecmdfile}
#echo "RELEASE CHANNEL T1;" >> $restorecmdfile
#echo "RELEASE CHANNEL T2;" >> $restorecmdfile
echo "}" >> $restorecmdfile
echo "EXIT" >> $restorecmdfile

## remove empty lines
remove_empty_lines $restorecmdfile

#### Create log file and temp files script

 $sqlQuery=@"
 WHENEVER SQLERROR EXIT SQL.SQLCODE
 set linesize 500 heading off feedback off
 col file_name format a200
select 'alter database rename file ''' ||member|| ''' to '||'''$stgMnt'||'\$oraSrc\'||SUBSTR(member,(INSTR(REPLACE(member,'/','\'),'\',-1)+1),LENGTH(member))||''';' member from v`$logfile;
exit
"@

log "[SQL Query - rename_logfiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[rename_logfiles] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

echo $result > $renamelogtempfile

 $sqlQuery=@"
 WHENEVER SQLERROR EXIT SQL.SQLCODE
 set linesize 200 heading off feedback off
 col file_name format a200
select 'alter database rename file ''' ||name|| ''' to '||'''$stgMnt'||'\$oraSrc\'||SUBSTR(name,(INSTR(REPLACE(NAME,'/','\'),'\',-1)+1),LENGTH(name))||''';' name from v`$tempfile;
exit
"@

log "[SQL Query - rename_tempfiles] $sqlQuery"

$result = $sqlQuery |  . $Env:ORACLE_HOME\bin\sqlplus.exe -silent " /as sysdba"

log "[rename_tempfiles] $result"

if ($LASTEXITCODE -ne 0){
echo "Sql Query failed with ORA-$LASTEXITCODE"
exit 1
}

echo $result >> $renamelogtempfile
echo "exit" >> $renamelogtempfile

## remove empty lines
remove_empty_lines $renamelogtempfile

log "Creating Restore Scripts, $restorecmdfile FINISHED"

##### create recovery script

log "Creating Recovery Script, $recovercmdfile STARTED"

#echo "catalog start with '$oraBkpLoc' noprompt;" > $recovercmdfile
echo "set echo on" > $recovercmdfile
echo "RUN" >> $recovercmdfile
echo "{" >> $recovercmdfile
for ($i=1; $i -le $rmanChannels; $i=$i+1)
{echo "ALLOCATE CHANNEL T${i} DEVICE TYPE disk;" >> $recovercmdfile}
echo "SET UNTIL SCN $end_scn;" >> $recovercmdfile
echo "recover database;" >> $recovercmdfile
for ($i=1; $i -le $rmanChannels; $i=$i+1)
{echo "RELEASE CHANNEL T${i};" >> $recovercmdfile}
echo "}" >> $recovercmdfile
echo "EXIT" >> $recovercmdfile

log "Creating Recovery Script, $recovercmdfile FINISHED"