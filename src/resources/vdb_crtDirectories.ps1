#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'vdb_crtDirectories.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraUnq = $env:ORA_UNQ_NAME
$oraBase = $env:ORACLE_BASE
$oraDBName = $env:ORA_DB_NAME
$virtMnt = $env:VDB_MNT_PATH
$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1

$audit_dest="$oraBase\admin\$oraUnq\adump"

log "Creating Directories, $audit_dest STARTED"

#### Create audit file dest

 if(!(Test-Path $audit_dest)) {
       md $audit_dest
 log "[Creating audit_dest] md $audit_dest"
 }
 else {
 log "[audit_dest already Exist] $audit_dest"
    }

log "Creating Directories, $audit_dest FINISHED"
