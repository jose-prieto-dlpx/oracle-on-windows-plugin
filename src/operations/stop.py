#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript, mask_object
from generated.definitions import RepositoryDefinition, SourceConfigDefinition
import json

def vdb_stop (virtual_connection,parameters,repository,source_config):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "vdb_stop",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "VDB_MNT_PATH" : parameters.mount_path,
            "ORA_UNQ_NAME" : parameters.dbunique_name,
            "ORA_DB_NAME" : parameters.db_name,
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Virtual Parameters: {}".format(masked_params))
    logger.debug("Virtual Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))

    stop_vdb =  executeScript.execute_powershell(virtual_connection,'vdb_stop.ps1',env)
    logger.debug("Stop VDB: {}".format(stop_vdb))
