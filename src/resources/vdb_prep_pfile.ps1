#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_prep_pfile.ps1'
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
$srcType = $env:ORA_SRC_TYPE
$initParams = $env:CUSTOM_INIT_PARAMS
$initParamsFile = $env:CUSTOM_INIT_PARAMS_FILE
$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

log "Init Params, $initParams"
log "Init Params File, $initParamsFile"

$initfile = "${virtMnt}\${oraUnq}\init${oraUnq}.ora"

if ((Test-Path $initfile)) {
#make a copy if any initfile already exists
  mv $initfile "$initfile.bak"
}

# set powershell default encoding to UTF8
$PSDefaultParameterValues['*:Encoding'] = 'ascii'

log "Creation of base init.ora $initfile STARTED"

echo "*.audit_file_dest='$oraBase\admin\$oraUnq\adump'" > ${initfile}
echo "*.audit_trail='db'" >> ${initfile}
echo "*.control_files='$virtMnt\$oraUnq\control01.ctl'" >> ${initfile}
echo "*.db_block_size=8192" >> ${initfile}
echo "*.db_domain=''" >> ${initfile}
if ($srcType -eq 'dSource'){
  echo "*.db_name=$oraSrc" >> ${initfile}
}
else { ## srcType is VDB
  echo "*.db_name=$oraUnq" >> ${initfile}
}
echo "*.db_unique_name='$oraUnq'" >> ${initfile}
echo "*.db_recovery_file_dest='$virtMnt\$oraUnq\flash_recovery_area'" >> ${initfile}
echo "*.db_recovery_file_dest_size=20G" >> ${initfile}
echo "*.diagnostic_dest='$oraBase'" >> ${initfile}
echo "*.dispatchers='(PROTOCOL=TCP) (SERVICE=${oraUnq}XDB)'" >> ${initfile}
echo "*.log_archive_format='%t_%s_%r.arc'" >> ${initfile}
echo "*.open_cursors=1000" >> ${initfile}
echo "*.pga_aggregate_target=385875968" >> ${initfile}
echo "*.processes=1500" >> ${initfile}
echo "*.remote_login_passwordfile='EXCLUSIVE'" >> ${initfile}
echo "*.sga_target=3G" >> ${initfile}
echo "*.db_files=1500" >> ${initfile}
echo "*._omf=disabled" >> ${initfile}
echo "${oraUnq}.undo_tablespace='UNDOTBS1'" >> ${initfile}

log "Creation of base init.ora $initfile FINISHED"

$baseinitOra = Get-Content $initfile

log "Contents of base init.ora ($initfile), $baseinitOra"

# Make mastercopy of init.ora for further usage

$masterinit = ${initfile}+".master"

log "Make Master Copy of init.ora, ${initfile} $masterinit"

cp ${initfile} $masterinit

## Update master file as per custom init.ora

log "Checking for custom init parameters, $initParams STARTED"

$initParams = $initParams -replace "u'","'"

log "Check one, $initParams"

$initParams = $initParams -replace "'","`""

log "Check two, $initParams"

$jstr = $initParams | convertfrom-json

foreach($obj in $jstr)
{
   $param=$obj.propertyName
   $value=$obj.value
   $SEL = Select-String -Path $masterinit -Pattern $param
    if ($SEL -ne $null) {
       Set-Content -Path $masterinit -Value (get-content -Path $masterinit | Select-String -Pattern $param -NotMatch)
        echo "*.$param=$value" >> $masterinit
      }
    else {
        echo "*.$param=$value" >> $masterinit
      }
}

log "Checking for custom init parameters, $initParams FINISHED"

### Check for init.ora file
log "Checking for custom init.ora file, $initParamsFile STARTED"

if (-not ([string]::IsNullOrEmpty($initParamsFile))){

log "Custom init.ora file, $initParamsFile supplied"

remove_empty_lines $initParamsFile

foreach($line in Get-Content $initParamsFile) {
    $index = $line.IndexOf("=")
    $param = $line.Substring(0,$index).trim()
    $value = $line.Substring($index+1).trim()
    $SEL = Select-String -Path $masterinit -Pattern $param
     if ($SEL -ne $null) {
        Set-Content -Path $masterinit -Value (get-content -Path $masterinit | Select-String -Pattern $param -NotMatch)
         echo "*.$param=$value" >> $masterinit
       }
     else {
         echo "*.$param=$value" >> $masterinit
       }
 }
}

else {
  log "Custom init.ora file not supplied"
}

log "Checking for custom init.ora file, $initParamsFile FINISHED"

$newinitOra = Get-Content $masterinit

log "Contents of new init.ora ($masterinit), $newinitOra"

# copy pfile to Oracle Home
log "Copy file ${initfile} to $oracleHome\database\init${oraUnq}.ora"

if ((Test-Path "$oracleHome\database\init${oraUnq}.ora")) {
	mv "$oracleHome\database\init${oraUnq}.ora" "$oracleHome\database\init${oraUnq}.ora.bak"
	cp ${masterinit} "$oracleHome\database\init${oraUnq}.ora"
}
else {
	cp ${masterinit} "$oracleHome\database\init${oraUnq}.ora"
}

# backup of spfile in Oracle Home
log "Backup spfile $oracleHome\database\spfile${oraUnq}.ora if exists"

if ((Test-Path "$oracleHome\database\spfile${oraUnq}.ora")) {
	Move-Item "$oracleHome\database\spfile${oraUnq}.ora" "$oracleHome\database\spfile${oraUnq}.ora.bak" -Force
}
