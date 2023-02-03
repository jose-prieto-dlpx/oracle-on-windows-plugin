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

log "$programName - STARTED"

# Left intentionally blank as scafolding for any future needs

log "$programName - FINISHED"

exit 0
