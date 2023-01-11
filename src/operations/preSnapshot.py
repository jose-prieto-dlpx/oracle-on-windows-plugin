#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript, mask_object
from generated.definitions import RepositoryDefinition, SourceConfigDefinition, SnapshotDefinition
import json


def exec_ds_presnapshot (source_connection,parameters,repository,source_config,snapshot_parameters=None):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "exec_ds_presnapshot",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_SRC_NAME" : source_config.db_name,
            "ORACLE_DB_IDENTITY_NAME" : source_config.db_identity_name,
            "ORA_UNQ_NAME" : source_config.db_uniq_name,
            "VDB_MNT_PATH" : parameters.mount_path,
            "ORACLE_SID" : parameters.instance_name            
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Staged Parameters: {}".format(masked_params))
    logger.debug("Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))

    executeScript.execute_powershell(source_connection,'vdb_preSnapshot.ps1',env)
    

    

def exec_vdb_presnapshot (source_connection,parameters,repository,source_config):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "exec_vdb_presnapshot",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_SRC_NAME" : source_config.db_name,
            "ORACLE_DB_IDENTITY_NAME" : source_config.db_identity_name,
            "ORA_UNQ_NAME" : source_config.db_uniq_name,
            "VDB_MNT_PATH" : parameters.mount_path,
            "ORACLE_SID" : parameters.instance_name            
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Staged Parameters: {}".format(masked_params))
    logger.debug("Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))

    executeScript.execute_powershell(source_connection,'vdb_preSnapshot.ps1',env)
    