#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript, mask_object
from dlpx.virtualization.platform import Status
import json

def vdb_status (virtual_connection,parameters,repository,source_config):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "vdb_status",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "VDB_MNT_PATH" : parameters.mount_path,
            "ORA_UNQ_NAME" : parameters.dbunique_name,
            "ORA_DB_NAME" : parameters.db_name
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Virtual Parameters: {}".format(masked_params))
    logger.debug("Virtual Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))

    status_vdb =  executeScript.execute_powershell(virtual_connection,'vdb_status.ps1',env)
    logger.debug("Status VDB: {}".format(status_vdb))
    status = Status.ACTIVE if (status_vdb == "ACTIVE") else Status.INACTIVE
    logger.debug("status for {} : {}".format(parameters.dbunique_name, status))
    return status

def ds_status (source_connection,parameters,repository,source_config):
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
    logger.debug("Source Config Parameters: {}".format(source_config))

    status_ds =  executeScript.execute_powershell(source_connection,'ds_status.ps1',env)
    logger.debug("Status dSource: {}".format(status_ds))
    status = Status.ACTIVE if ( status_ds == "ACTIVE") else Status.INACTIVE
    logger.debug("status for {} : {}".format(source_config.db_uniq_name, status))
    return status
