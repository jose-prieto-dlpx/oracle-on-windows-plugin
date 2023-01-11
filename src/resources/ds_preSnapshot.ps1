#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jose Rodriguez
# Date: 10-Jan-2023
###########################################################

$programName = 'ds_preSnapshot.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraUnq = $env:ORA_UNQ_NAME
$virtMnt = $env:VDB_MNT_PATH
$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

# Creating new controlfile copy

$ccf_file_old = "$virtMnt\$oraUnq\ccf_old.sql"
$ccf_file_new = "$virtMnt\$oraUnq\CCF.SQL"
log "Checking for the existence of $ccf_file_new and moving to $ccf_file_old if necessary"

if ((Test-Path "$virtMnt\$oraUnq\CCF.SQL")) {
    log "Moving ccf.sql file to ccf.sql.old STARTED"
	Move-Item $ccf_file_new $ccf_file_old -force
    log "Moving ccf.sql file to ccf.sql.old FINISHED"
}

create_control_file $virtMnt $oraUnq

exit 0
