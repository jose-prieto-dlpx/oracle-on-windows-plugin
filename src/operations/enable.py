#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript, mask_object
from generated.definitions import RepositoryDefinition, SourceConfigDefinition
import json

def vdb_enable (virtual_connection,parameters,repository,source_config, snapshot):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "vdb_enable",
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
    logger.debug("Snapshot Parameters: {}".format(snapshot))

    enable_vdb =  executeScript.execute_powershell(virtual_connection,'vdb_enable.ps1',env)
    logger.debug("Enable VDB: {}".format(enable_vdb))

    db_name = parameters.db_name
    db_uniq_name = parameters.dbunique_name
    db_identity_name = parameters.instance_name

    return SourceConfigDefinition(db_name=db_name, db_uniq_name=db_uniq_name,db_identity_name=db_identity_name)

def ds_enable (staged_connection,parameters,repository,source_config):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "ds_enable",
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
    logger.debug("Staged Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))

    enable_ds =  executeScript.execute_powershell(staged_connection,'ds_enable.ps1',env)
    logger.debug("Enable dSource: {}".format(enable_ds))
