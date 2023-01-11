#
# Copyright (c) 2021 by Delphix. All rights reserved.
#

from dlpx.virtualization.platform import Mount, MountSpecification, Plugin
from operations import discovery, restore, provision, postSnapshot, preSnapshot, enable, disable, start, stop, status

from generated.definitions import (
    RepositoryDefinition,
    SourceConfigDefinition,
    SnapshotDefinition,
    SnapshotParametersDefinition,
)

plugin = Plugin()

#
# Below is an example of the repository discovery operation.
#
# NOTE: The decorators are defined on the 'plugin' object created above.
#
# Mark the function below as the operation that does repository discovery.
@plugin.discovery.repository()
def repository_discovery(source_connection):
    #
    # This is an object generated from the repositoryDefinition schema.
    # In order to use it locally you must run the 'build -g' command provided
    # by the SDK tools from the plugin's root directory.
    #

    return discovery.find_repos(source_connection)


@plugin.discovery.source_config()
def source_config_discovery(source_connection, repository):
    #
    # To have automatic discovery of source configs, return a list of
    # SourceConfigDefinitions similar to the list of
    # RepositoryDefinitions above.
    #

    return []


@plugin.linked.post_snapshot()
def linked_post_snapshot(staged_source,repository,source_config,optional_snapshot_parameters):

    source_connection = staged_source.staged_connection
    parameters = staged_source.parameters

    return postSnapshot._make_ds_postsnapshot(source_connection,parameters,repository,source_config,optional_snapshot_parameters)
    #return SnapshotDefinition()


@plugin.linked.mount_specification()
def linked_mount_specification(staged_source, repository):

    mount_path = staged_source.parameters.mount_path
    environment = staged_source.staged_connection.environment
    mounts = [Mount(environment, mount_path)]
    return MountSpecification(mounts)

@plugin.linked.pre_snapshot()
def restore_oracle_backup(staged_source,repository,source_config,optional_snapshot_parameters):

    source_connection = staged_source.staged_connection
    parameters = staged_source.parameters

    if (optional_snapshot_parameters is not None) and (optional_snapshot_parameters.resync is True):
        return restore.initial_sync(source_connection,parameters,repository,source_config),
    else:
        return restore.incremental_sync(source_connection,parameters,repository,source_config)

@plugin.linked.status()
def linked_status(staged_source, repository, source_config):
    source_connection = staged_source.staged_connection
    parameters = staged_source.parameters
    return status.ds_status(source_connection,parameters,repository,source_config)

@plugin.linked.start_staging()
def start_staging(staged_source, repository, source_config):
    source_connection = staged_source.staged_connection
    parameters = staged_source.parameters
    enable.ds_enable(source_connection,parameters,repository,source_config)


@plugin.linked.stop_staging()
def stop_staging(staged_source, repository, source_config):
    source_connection = staged_source.staged_connection
    parameters = staged_source.parameters
    disable.ds_disable(source_connection,parameters,repository,source_config)

@plugin.virtual.configure()
def configure(virtual_source, snapshot, repository):
    db_name = virtual_source.parameters.db_name
    db_uniq_name = virtual_source.parameters.dbunique_name
    db_identity_name = virtual_source.parameters.instance_name
    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters
    #return SourceConfigDefinition(db_name=db_name, db_uniq_name=db_uniq_name,db_identity_name=db_identity_name)
    return provision.initial_provision(virtual_connection,parameters,snapshot,repository)

@plugin.virtual.reconfigure()
def reconfigure(virtual_source, repository, source_config, snapshot):
    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters
    return enable.vdb_enable(virtual_connection, parameters, repository, source_config, snapshot)

@plugin.virtual.pre_snapshot()
def virtual_pre_snapshot(virtual_source, repository, source_config):
    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters

    return preSnapshot.exec_vdb_presnapshot(virtual_connection,parameters,repository,source_config)  

@plugin.virtual.post_snapshot()
def virtual_post_snapshot(virtual_source, repository, source_config):

    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters

    return postSnapshot._make_vdb_postsnapshot(virtual_connection,parameters,repository,source_config)
    #return SnapshotDefinition()
    #raise NotImplementedError


@plugin.virtual.mount_specification()
def virtual_mount_specification(virtual_source, repository):
    mount_path = virtual_source.parameters.mount_path
    environment = virtual_source.connection.environment
    mounts = [Mount(environment, mount_path)]

    return MountSpecification(mounts)

@plugin.virtual.unconfigure()
def unconfigure(virtual_source, repository, source_config):
    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters
    disable.vdb_disable(virtual_connection, parameters, repository, source_config)

@plugin.virtual.stop()
def virtual_stop(virtual_source, repository, source_config):
    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters
    stop.vdb_stop(virtual_connection, parameters, repository, source_config)

@plugin.virtual.start()
def virtual_start(virtual_source, repository, source_config):
    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters
    start.vdb_start(virtual_connection, parameters, repository, source_config)

@plugin.virtual.status()
def virtual_status(virtual_source, repository, source_config):
    virtual_connection = virtual_source.connection
    parameters = virtual_source.parameters
    return status.vdb_status(virtual_connection, parameters, repository, source_config)
