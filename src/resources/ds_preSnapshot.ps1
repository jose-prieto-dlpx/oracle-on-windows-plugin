#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jose Rodriguez
# Date: 10-Jan-2023
###########################################################

$programName = 'ds_preSnapshot.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraUnq = $env:ORA_UNQ_NAME
$oraSrc = $env:ORACLE_SRC_NAME
$virtMnt = $env:VDB_MNT_PATH
$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

# Creating new controlfile copy only if the service is running. Otherwise we may be in the very first ingestion and there is no database yet.

$svc_status = check_srvc_status $oraUnq

if ($svc_status -eq "Running"){
    $ccf_file_old = "$virtMnt\$oraSrc\ccf_old.sql"
    $ccf_file_new = "$virtMnt\$oraSrc\CCF.SQL"
    log "Restarting database to kill any zombie processes"
    startup_force_mount
    
    log "Checking for the existence of $ccf_file_new and moving to $ccf_file_old if necessary"
    
    if ((Test-Path "$virtMnt\$oraSrc\CCF.SQL")) {
        log "Moving ccf.sql file to ccf.sql.old STARTED"
        Move-Item $ccf_file_new $ccf_file_old -force
        log "Moving ccf.sql file to ccf.sql.old FINISHED"
    }
    
    create_control_file $virtMnt $oraSrc
  }
else {
    log "Service not running, assuming first ingestion of the database doing nothing."
}


exit 0
