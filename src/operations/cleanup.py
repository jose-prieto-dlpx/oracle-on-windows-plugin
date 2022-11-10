#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript
from generated.definitions import RepositoryDefinition, SourceConfigDefinition
import json


def vdb_cleanup(virtual_connection, repository, source_config):
    logger = setupLogger._setup_logger(__name__)  

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "vdb_cleanup",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_BASE" : repository.ora_base,            
            "ORA_UNQ_NAME" : source_config.dbUniqName
           }
           

    result = executeScript.execute_powershell(virtual_connection,'vdb_cleanup.ps1',env)
    logger.debug("VDB clean up complete for: {}".format(source_config.dbUniqName))
        
    # return result.stdout.strip()
