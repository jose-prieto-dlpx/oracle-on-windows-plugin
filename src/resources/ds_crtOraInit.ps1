#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'ds_crtOraInit.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oracleHome = $env:ORACLE_HOME
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraBase = $env:ORACLE_BASE
$oraSrc = $env:ORA_SRC
$stgMnt = $env:STG_MNT_PATH
$oraUnq = $env:ORA_UNQ_NAME
$initParams = $env:CUSTOM_INIT_PARAMS
$initParamsFile = $env:CUSTOM_INIT_PARAMS_FILE
$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

log "Init Params, $initParams"
log "Init Params File, $initParamsFile"

$initfile = "${oracleHome}\database\init${oraUnq}.ora"
$spfile = "${oracleHome}\database\SPFILE${oraUnq}.ora"

if ((Test-Path $initfile)) {
#make a copy if any initfile already exists
  mv $initfile "$initfile.bak" -force
}

if ((Test-Path $initfile)) {
#make a copy if any spfile already exists
  mv $spfile "$spfile.bak" -force
}


# set powershell default encoding to UTF8
$PSDefaultParameterValues['*:Encoding'] = 'ascii'

log "Creation of base init.ora $initfile STARTED"

echo "*.audit_file_dest='$oraBase\admin\$oraSrc\adump" > ${initfile}
echo "*.audit_trail='db'" >> ${initfile}
echo "*.control_files='$stgMnt\$oraSrc\control01.ctl'" >> ${initfile}
echo "*.db_block_size=8192" >> ${initfile}
echo "*.db_domain=''" >> ${initfile}
echo "*.db_name=$oraSrc" >> ${initfile}
echo "*.db_unique_name='$oraUnq'" >> ${initfile}
echo "*.db_recovery_file_dest='$stgMnt\$oraSrc\flash_recovery_area'" >> ${initfile}
echo "*.db_recovery_file_dest_size=20G" >> ${initfile}
echo "*.diagnostic_dest='$oraBase'" >> ${initfile}
echo "*.dispatchers='(PROTOCOL=TCP) (SERVICE=${oraSrc}XDB)'" >> ${initfile}
echo "*.log_archive_format='%t_%s_%r.arc'" >> ${initfile}
echo "*.open_cursors=1000" >> ${initfile}
echo "*.pga_aggregate_target=385875968" >> ${initfile}
echo "*.processes=1500" >> ${initfile}
echo "*.remote_login_passwordfile='EXCLUSIVE'" >> ${initfile}
echo "*.sga_target=3G" >> ${initfile}
echo "*.db_files=1500" >> ${initfile}
echo "*._omf=disabled" >> ${initfile}
#echo "enable_pluggable_database=TRUE" >> ${initfile}
#echo "${oraUnq}.undo_tablespace='UNDOTBS1'" >> ${initfile}

log "Creation of base init.ora $initfile FINISHED"

$baseinitOra = Get-Content $initfile

log "Contents of base init.ora, $baseinitOra"

## Update init file as per custom init.ora

log "Checking for custom init.ora, $initParams STARTED"

$initParams = $initParams -replace "u'","'"

log "Check one, $initParams"

$initParams = $initParams -replace "'","`""

log "Check two, $initParams"

$jstr = $initParams | convertfrom-json

foreach($obj in $jstr)
{
   $param=$obj.propertyName
   $value=$obj.value
   $SEL = Select-String -Path $initfile -Pattern $param
    if ($SEL -ne $null) {
       Set-Content -Path $initfile -Value (get-content -Path $initfile | Select-String -Pattern $param -NotMatch)
        echo "*.$param=$value" >> $initfile
      }
    else {
        echo "*.$param=$value" >> $initfile
      }
}

log "Checking for custom init.ora, $initParams FINISHED"

### Check for init.ora file
log "Checking for custom init.ora file, $initParamsFile STARTED"

if (-not ([string]::IsNullOrEmpty($initParamsFile))){

log "Custom init.ora file, $initParamsFile supplied"

remove_empty_lines $initParamsFile

foreach($line in Get-Content $initParamsFile) {
    $index = $line.IndexOf("=")
    $param = $line.Substring(0,$index).trim()
    $value = $line.Substring($index+1).trim()
    $SEL = Select-String -Path $initfile -Pattern $param
     if ($SEL -ne $null) {
        Set-Content -Path $initfile -Value (get-content -Path $initfile | Select-String -Pattern $param -NotMatch)
         echo "*.$param=$value" >> $initfile
       }
     else {
         echo "*.$param=$value" >> $initfile
       }
 }
}

else {
  log "Custom init.ora file not supplied"
}

log "Checking for custom init.ora file, $initParamsFile FINISHED"

$newinitOra = Get-Content $initfile

log "Contents of new init.ora, $newinitOra"
