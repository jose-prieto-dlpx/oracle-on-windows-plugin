#
# Copyright (c) 2022 by Delphix. All rights reserved.
#
# Author: Jose Rodriguez
# Date: 19-10-2022
###########################################################

$programName = 'vdb_status.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oraUnq = $env:ORA_UNQ_NAME
$oraBase = $env:ORACLE_BASE
$oracleHome = $env:ORACLE_HOME
$delphixPluginPath = $env:DLPX_TOOLKIT_PATH

$scriptDir = "${delphixToolkitPath}\scripts"

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

log "ORACLE_BASE: $oraBase"
log "ORACLE_HOME: $oracleHome"
log "ORACLE_SID: $oraUnq"

log "Deleting Oracle pfile ${$oracleHome}\database\init${oraUnq}.ora"
if (Test-Path ${$oracleHome}\database\init${oraUnq}.ora) {
    Remove-Item -Force ${$oracleHome}\database\init${oraUnq}.ora
}

log "Deleting Oracle spfile ${$oracleHome}\database\spfile${oraUnq}.ora"
if (Test-Path ${$oracleHome}\database\spfile${oraUnq}.ora){
    Remove-Item -Force ${$oracleHome}\database\spfile${oraUnq}.ora
}

log "Deleting log files under $delphixPluginPath\logs\${oraUnq}"
if (Test-Path $delphixPluginPath\logs\${oraUnq}) {
    Remove-Item -Recurse -Force "$delphixPluginPath\logs\${oraUnq}"
}

log "Deleting Oracle service for ${oraUnq}"
delete_OraService ${oraUnq}
exit 0
