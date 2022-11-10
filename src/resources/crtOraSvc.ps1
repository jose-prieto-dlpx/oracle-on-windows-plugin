#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
###########################################################

$programName = 'crtOraSvc.ps1'
$delphixToolkitPath = $env:DLPX_TOOLKIT_PATH
$oracleHome = $env:ORACLE_HOME
$oraInstName = $env:ORACLE_INST
$oraUser = $env:ORACLE_USER
$oraPwd = $env:ORACLE_PASSWD
$oraBase = $env:ORACLE_BASE
$oraUnq = $env:ORA_UNQ_NAME
$scriptDir = "${delphixToolkitPath}\scripts"
$toolkitWF = $env:DLPX_TOOLKIT_WORKFLOW

. $scriptDir\delphixLibrary.ps1
. $scriptDir\oracleLibrary.ps1

log "Executing $programName"

$Env:ORACLE_BASE=$oraBase
$Env:ORACLE_SID=$oraUnq
$Env:ORACLE_HOME=$oracleHome

log "ORACLE_BASE: $oraBase"
log "ORACLE_HOME: $oracleHome"
log "ORACLE_SID: $oraUnq"

log "Creation of Oracle Service, $oraUnq STARTED"

if ($toolkitWF -eq "initial_sync") {
    create_OraService $oraInstName $oraUser $oraPwd
}
else {
    create_OraService $oraUnq $oraUser $oraPwd
}

log "Creation of Oracle Service, $oraUnq FINISHED"
