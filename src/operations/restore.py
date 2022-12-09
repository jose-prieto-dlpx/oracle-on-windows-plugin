#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript, mask_object
from generated.definitions import RepositoryDefinition, SourceConfigDefinition
import json


def initial_sync (source_connection,parameters,repository,source_config):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "initial_sync",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_DBID" : parameters.dbid,
            "ORACLE_CTRL_FILE_BKP" : parameters.dbctrlbkppiece,
            "ORACLE_BKP_LOC" : parameters.dbrmanbkploc,
            "STG_MNT_PATH" : parameters.mount_path,
            "ORA_SRC" : source_config.db_name,
            "ORACLE_DB_IDENTITY_NAME" : source_config.db_identity_name,
            "ORA_UNQ_NAME" : source_config.db_uniq_name,
            "CUSTOM_INIT_PARAMS" : str(parameters.custom_init_params),
            "CUSTOM_INIT_PARAMS_FILE" : parameters.custom_init_params_file,
            "RMAN_CHANNELS" : str(parameters.rman_channels)
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Staged Parameters: {}".format(masked_params))

    logger.debug("Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))

    reSyncPrep =  executeScript.execute_powershell(source_connection,'ds_resyncprep.ps1',env)
    logger.debug("reSyncPrep: {}".format(reSyncPrep))

    crt_svc =  executeScript.execute_powershell(source_connection,'crtOraSvc.ps1',env)
    logger.debug("Creating Service: {}".format(crt_svc))

    crt_init =  executeScript.execute_powershell(source_connection,'ds_crtOraInit.ps1',env)
    logger.debug("Creating Initial Init File: {}".format(crt_init))

    crt_dirs =  executeScript.execute_powershell(source_connection,'ds_crtDirectories.ps1',env)
    logger.debug("Creating Directories: {}".format(crt_dirs))

    start_nomount =  executeScript.execute_powershell(source_connection,'ds_startup_nomount.ps1',env)
    logger.debug("Startup No-Mount: {}".format(start_nomount))

    restore_ctrlfile =  executeScript.execute_powershell(source_connection,'ds_restore_controlfile.ps1',env)
    logger.debug("Restore Control File: {}".format(restore_ctrlfile))

    start_mount_spfile =  executeScript.execute_powershell(source_connection,'ds_startup_spfile.ps1',env)
    logger.debug("Startup Mount with SP File: {}".format(start_mount_spfile))

    crt_rstr_files =  executeScript.execute_powershell(source_connection,'ds_crtRestoreScripts.ps1',env)
    logger.debug("Create Restore Files: {}".format(crt_rstr_files))

    rstr_db =  executeScript.execute_powershell(source_connection,'ds_restore.ps1',env)
    logger.debug("Restore Database: {}".format(rstr_db))

def incremental_sync (source_connection,parameters,repository,source_config):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "initial_sync",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_DBID" : parameters.dbid,
            "ORACLE_CTRL_FILE_BKP" : parameters.dbctrlbkppiece,
            "ORACLE_BKP_LOC" : parameters.dbrmanbkploc,
            "STG_MNT_PATH" : parameters.mount_path,
            "ORA_SRC" : source_config.db_name,
            "ORACLE_DB_IDENTITY_NAME" : source_config.db_identity_name,
            "ORA_UNQ_NAME" : source_config.db_uniq_name
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Staged Parameters: {}".format(masked_params))
    logger.debug("Repository Parameters: {}".format(repository))

    ds_inc_find_bkp =  executeScript.execute_powershell(source_connection,'ds_inc_find_bkp.ps1',env)
    logger.debug("Find New Backups: {}".format(ds_inc_find_bkp))

    if (ds_inc_find_bkp != 'NoNewBackup'):
        crt_rstr_files =  executeScript.execute_powershell(source_connection,'ds_inc_crtRestoreScripts.ps1',env)
        logger.debug("Create Restore Files: {}".format(crt_rstr_files))

        rstr_db =  executeScript.execute_powershell(source_connection,'ds_inc_restore.ps1',env)
        logger.debug("Restore Database: {}".format(rstr_db))
