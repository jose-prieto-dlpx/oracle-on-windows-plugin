#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript, mask_object
from generated.definitions import RepositoryDefinition, SourceConfigDefinition
import json


def initial_provision (virtual_connection,parameters,snapshot,repository):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "initial_provision",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "VDB_MNT_PATH" : parameters.mount_path,
            "ORA_UNQ_NAME" : parameters.dbunique_name,
            "ORA_DB_NAME" : parameters.db_name,
            "ARCHIVE_LOG_MODE" : str(parameters.archivelog_mode),
            "CUSTOM_INIT_PARAMS" : str(parameters.custom_init_params),
            "CUSTOM_INIT_PARAMS_FILE" : parameters.custom_init_params_file,
            "ORA_SRC" : snapshot.ora_src,
            "ORA_STG" : snapshot.ora_inst,
            "ORA_SRC_TYPE" : snapshot.src_type,
            "ORA_VDB_SRC" : snapshot.ora_unq
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Virtual Parameters: {}".format(masked_params))

    logger.debug("Virtual Repository Parameters: {}".format(repository))
    logger.debug("Snapshot Parameters: {}".format(snapshot))

    crt_svc =  executeScript.execute_powershell(virtual_connection,'crtOraSvc.ps1',env)
    logger.debug("Creating Service: {}".format(crt_svc))

    copy_to_vdbdir =  executeScript.execute_powershell(virtual_connection,'vdb_rename_vdbdir.ps1',env)
    logger.debug("Copying dSource to VDB Dir: {}".format(copy_to_vdbdir))

    crt_dirs =  executeScript.execute_powershell(virtual_connection,'vdb_crtDirectories.ps1',env)
    logger.debug("Creating Directories: {}".format(crt_dirs))

    vdb_prep_pfile = executeScript.execute_powershell(virtual_connection,'vdb_prep_pfile.ps1',env)
    logger.debug("VDB Prep pFile: {}".format(vdb_prep_pfile))

    if (snapshot.src_type=='dSource'):
        vdb_startup_mount = executeScript.execute_powershell(virtual_connection,'vdb_startup_mount.ps1',env)
        logger.debug("VDB StartUp Mount: {}".format(vdb_startup_mount))

        vdb_rename_files = executeScript.execute_powershell(virtual_connection,'vdb_rename_files.ps1',env)
        logger.debug("VDB Rename Files: {}".format(vdb_rename_files))

        vdb_configure = executeScript.execute_powershell(virtual_connection,'vdb_configure.ps1',env)
        logger.debug("VDB Configure: {}".format(vdb_configure))

        vdb_change_dbname_dbid = executeScript.execute_powershell(virtual_connection,'vdb_change_dbname_dbid.ps1',env)
        logger.debug("VDB Change DB ID: {}".format(vdb_change_dbname_dbid))

        vdb_finalize = executeScript.execute_powershell(virtual_connection,'vdb_finalize.ps1',env)
        logger.debug("VDB Finalize: {}".format(vdb_finalize))

    else: ### snapshot.src_type=='VDB'
        child_vdb_provision = executeScript.execute_powershell(virtual_connection,'vdb_childProvision.ps1',env)
        logger.debug("Child VDB Provision: {}".format(child_vdb_provision))

    if (str(parameters.archivelog_mode)=='True'):
        vdb_disable_archivelog = executeScript.execute_powershell(virtual_connection,'vdb_disable_archivelog.ps1',env)
        logger.debug("VDB Disable Archive Log: {}".format(vdb_disable_archivelog))

    db_name = parameters.db_name
    db_uniq_name = parameters.dbunique_name
    db_identity_name = parameters.instance_name

    return SourceConfigDefinition(db_name=db_name, db_uniq_name=db_uniq_name,db_identity_name=db_identity_name)
