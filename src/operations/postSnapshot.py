#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from utils import setupLogger, executeScript, mask_object
from generated.definitions import RepositoryDefinition, SourceConfigDefinition, SnapshotDefinition
import json


def _make_ds_postsnapshot (source_connection,parameters,repository,source_config,snapshot_parameters=None):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "_make_ds_postsnapshot",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_SRC_NAME" : source_config.db_name,
            "ORACLE_DB_IDENTITY_NAME" : source_config.db_identity_name,
            "ORA_UNQ_NAME" : source_config.db_uniq_name
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Staged Parameters: {}".format(masked_params))
    logger.debug("Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))
    logger.debug("Snapshot Parameters: {}".format(snapshot_parameters))

    snapshotMetadata = executeScript.execute_powershell(source_connection,'ds_postSnapshot.ps1',env)
    logger.debug("Snapshot Metadata: {}".format(snapshotMetadata))
    parsedSnapshotMeta = json.loads(snapshotMetadata)
    logger.debug("parsedSnapshotMeta: {}".format(parsedSnapshotMeta))
    return SnapshotDefinition(oracle_home=parsedSnapshotMeta["oracleHome"],
    delphix_tookit_path=parsedSnapshotMeta["delphixToolkitPath"],
    ora_inst=parsedSnapshotMeta["oraInstName"],
    ora_user=parsedSnapshotMeta["oraUser"],
    ora_base=parsedSnapshotMeta["oraBase"],
    ora_bkp_loc=parsedSnapshotMeta["oraBkpLoc"],
    ora_src=parsedSnapshotMeta["oraSrc"],
    ora_unq=parsedSnapshotMeta["oraUnq"],
    src_type=parsedSnapshotMeta["srcType"])
    #return [RepositoryDefinition(toolkit_name=installedRepository["toolkitName"],delphix_tookit_path=installed
    #return SnapshotDefinition(ora_src = "ORCL", db_name = "oratest")
    #return SnapshotDefinition(oracle_home="D:\\dbhome_1",delphix_tookit_path="C:\\\\Program Files\\\\Delphix\\\\DelphixConnector\\\\Oracle on Windows",ora_inst="ORASTG",ora_user="oracle",ora_base="D:\\app\\oracle",ora_bkp_loc="D:\\ora_backups\\orcl",ora_src="ORCL")


def _make_vdb_postsnapshot (source_connection,parameters,repository,source_config):
    logger = setupLogger._setup_logger(__name__)

    env = {
            "DLPX_TOOLKIT_NAME" : "Oracle on Windows",
            "DLPX_TOOLKIT_WORKFLOW" : "_make_vdb_postsnapshot",
            "DLPX_TOOLKIT_PATH" : repository.delphix_tookit_path,
            "ORACLE_HOME" : repository.ora_home,
            "ORACLE_INST" : parameters.instance_name,
            "ORACLE_USER" : parameters.username,
            "ORACLE_PASSWD" : parameters.password,
            "ORACLE_BASE" : repository.ora_base,
            "ORACLE_SRC_NAME" : source_config.db_name,
            "ORACLE_DB_IDENTITY_NAME" : source_config.db_identity_name,
            "ORA_UNQ_NAME" : source_config.db_uniq_name
           }

    masked_params = mask_object.mask_object(parameters,['password'])
    logger.debug("Staged Parameters: {}".format(masked_params))
    logger.debug("Repository Parameters: {}".format(repository))
    logger.debug("Source Config Parameters: {}".format(source_config))

    snapshotMetadata = executeScript.execute_powershell(source_connection,'vdb_postSnapshot.ps1',env)
    logger.debug("Snapshot Metadata: {}".format(snapshotMetadata))
    parsedSnapshotMeta = json.loads(snapshotMetadata)
    logger.debug("parsedSnapshotMeta: {}".format(parsedSnapshotMeta))
    return SnapshotDefinition(oracle_home=parsedSnapshotMeta["oracleHome"],
    delphix_tookit_path=parsedSnapshotMeta["delphixToolkitPath"],
    ora_inst=parsedSnapshotMeta["oraInstName"],
    ora_user=parsedSnapshotMeta["oraUser"],
    ora_base=parsedSnapshotMeta["oraBase"],
    ora_bkp_loc=parsedSnapshotMeta["oraBkpLoc"],
    ora_src=parsedSnapshotMeta["oraSrc"],
    ora_unq=parsedSnapshotMeta["oraUnq"],
    src_type=parsedSnapshotMeta["srcType"])
    #return [RepositoryDefinition(toolkit_name=installedRepository["toolkitName"],delphix_tookit_path=installed
    #return SnapshotDefinition(ora_src = "ORCL", db_name = "oratest")
    #return SnapshotDefinition(oracle_home="D:\\dbhome_1",delphix_tookit_path="C:\\\\Program Files\\\\Delphix\\\\DelphixConnector\\\\Oracle on Windows",ora_inst="ORASTG",ora_user="oracle",ora_base="D:\\app\\oracle",ora_bkp_loc="D:\\ora_backups\\orcl",ora_src="ORCL")
