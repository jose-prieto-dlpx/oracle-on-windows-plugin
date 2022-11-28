#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: Jatinder Luthra
# Date: 09-23-2020
############################################################

Set-PSDebug -off

$dlpxToolkitName = "Oracle on Windows"
$dlpxToolkitPath = $env:DLPX_TOOLKIT_PATH

$dlpxToolkitWorkflow = $env:DLPX_TOOLKIT_WORKFLOW
$dlpxLogDirectory = "${dlpxToolkitPath}\logs"
$dbName=$env:ORA_UNQ_NAME

$timestamp = "$(Get-Date -Format 'MM-dd-yy HH:mm:ss')"
$configOutputFile = "delphix_${dlpxToolkitName}_config.dat"
$baseLogDir = "${dlpxLogDirectory}\${dbName}"
$errorLog = "${baseLogDir}\error.log"
$debugLog = "${baseLogDir}\debug.log"

if(!(Test-Path $baseLogDir)) {
   md "$baseLogDir"
}

###########################################################
## Functions ...

#
# Log infomation and die if option -d is used.
#
function log {
   param(
      [Parameter(Mandatory=$false)]
      [string]
      $logMessage,
      [Parameter(Mandatory=$false)]
      [Switch]
      $die
   )

   $timestamp = "$(Get-Date -Format 'MM-dd-yy HH:mm:ss')"
   $Line = "[$timestamp][DEBUG][$dlpxToolkitWorkflow][${programName}]:[$logMessage]"
   Add-content $debugLog -value $Line
   if ($die) {
      exit 2
   }
}

# Log error and write to the errorlog
function errorLog {
   param(
      [Parameter(Mandatory=$false)]
      [string]
      $logMessage
   )

   log $logMessage
   $Line = "[$timestamp][DEBUG][$dlpxToolkitWorkflow][${programName}]:[$logMessage]"
   Add-content $errorLog -value $Line
}

# Write to log and errorlog before exiting with an error code
function die {
   param(
      [Parameter(Mandatory=$false)]
      [string]
      $logMessage
   )
   errorLog $logMessage
   exit 2
}

# Function to check for errors and die with passed in error message
function errorCheck {
   param(
      [Parameter(Mandatory=$false)]
      [string]
      $logMessage
   )

   if ( -not $? )
   {
      die $logMessage
   }
}

# Function to capture the error from sql queries
function sqlErrorCapture {
   param(
      [string]
      $exceptionType,
      [string]
      $exceptionMessage
   )
   log $exceptionType
   log $exceptionMessage
   $jsonError = [pscustomobject]@{
       'errorMessage'=$exceptionMessage
       'errorType'=$exceptionType
   }
   $jsonError = (ConvertTo-json $jsonError)
   log "jsonError = $jsonError"
   echo $jsonError

}
# Function to capture the error in postsnapshot
function postSnapErrorCapture {
   param(
      [Parameter(Mandatory=$true)]
      [string]
      $exceptionType,
      [Parameter(Mandatory=$true)]
      [string]
      $exceptionMessage
   )
   log $exceptionMessage
   log $exceptionType
   $jsonDataFiles = @()
   $jsonDataFiles += [pscustomobject]@{
        'fileId'="";
        'logicalName'="";
        'physicalPath'="";
        'logicalPhysicalPath'="";
        'fileGroup'="";
        'fileType'="";
   }
   $jsonDoc = [pscustomobject]@{
        dbName= $databaseName
        errorMessage = $exceptionMessage
        errorType = $exceptionType
        fileInfo=$jsonDataFiles
   }
   $jsonDoc = ( ConvertTo-Json $jsonDoc)
   log "json = $jsonDoc"
   echo $jsonDoc
}

log "ENVIRONMENT VARS"
