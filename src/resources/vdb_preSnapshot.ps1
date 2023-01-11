#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jose Rodriguez
# Date: 10-Jan-2023
###########################################################

$programName = 'vdb_preSnapshot.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraUnq = $env:ORA_UNQ_NAME
$virtMnt = $env:VDB_MNT_PATH
$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

# Rotating redo logs
switchlogfiles

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

Copy-Item "$virtMnt\$oraUnq\CCF.SQL" "$virtMnt\$oraUnq\CCF_manual.SQL"

# Adding some wait time and an additional write to ensure the snapshot includes the control file trace.
Start-Sleep 5 
Write-Output "--- Corruption test - Ignore if seen  " >> "$virtMnt\$oraUnq\CCF.SQL"

exit 0
