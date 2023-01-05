#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'ds_crtDirectories.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oracleHome = $env:ORACLE_HOME
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraBase = $env:ORACLE_BASE
$oraSrc = $env:ORA_SRC
$stgMnt = $env:STG_MNT_PATH
$oraUnq = $env:ORA_UNQ_NAME
$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1

$fra="$stgMnt\$oraSrc\flash_recovery_area"
$audit_dest="$oraBase\admin\$oraSrc\adump"

log "Creating Directories, $fra , $audit_dest STARTED"

#### Create Flash recovery area

if(!(Test-Path $fra)) {
      md $fra
log "[Creating FRA] md $fra"
}
else {
log "[FRA Already Exists] $fra"
   }

#### Create audit file dest

 if(!(Test-Path $audit_dest)) {
       md $audit_dest
 log "[Creating audit_dest] md $audit_dest"
 }
 else {
 log "[audit_dest already Exist] $audit_dest"
    }

log "Creating Directories, $fra , $audit_dest FINISHED"

#### copy pfile from oracle home to mount

$source = "${oracleHome}\database"
$destination = "${stgMnt}\$oraSrc"

log "Copy pfile, init${oraUnq}.ora from $source to $destination STARTED"

cp "$source\init${oraUnq}.ora" "$destination\init${oraUnq}.ora"

log "Copy pfile, init${oraUnq}.ora from $source to $destination STARTED"
