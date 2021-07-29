#!/bin/bash
#
# Copyright (c) 2017-2021 VMware, Inc. or its affiliates
# SPDX-License-Identifier: Apache-2.0

set -eux -o pipefail

source gpupgrade_src/ci/scripts/ci-helpers.bash

USE_LINK_MODE=${USE_LINK_MODE:-0}
FILTER_DIFF=${FILTER_DIFF:-0}
DIFF_FILE=${DIFF_FILE:-"icw.diff"}

export GPHOME_SOURCE=/usr/local/greenplum-db-source
export GPHOME_TARGET=/usr/local/greenplum-db-target
export PGPORT=5432

./ccp_src/scripts/setup_ssh_to_cluster.sh

if ! is_GPDB5 ${GPHOME_SOURCE}; then
    echo "Configuring GUCs before dumping the source cluster..."
    configure_gpdb_gucs ${GPHOME_SOURCE}
fi

echo "Performing gpupgrade..."

time ssh -n mdw '
    set -ex -o pipefail

    export GPHOME_SOURCE=/usr/local/greenplum-db-source
    export GPHOME_TARGET=/usr/local/greenplum-db-target
    export PGPORT=5432

    gpupgrade initialize \
             --mode=link \
              --automatic \
              --target-gphome ${GPHOME_TARGET} \
              --source-gphome ${GPHOME_SOURCE} \
              --source-master-port $PGPORT \
              --temp-port-range 6020-6040

    gpupgrade execute --verbose

    sleep 500

    source /usr/local/greenplum-db-target/greenplum_path.sh
    export MASTER_DATA_DIRECTORY=$(gpupgrade config show --target-datadir)
    export PGPORT=$(gpupgrade config show --target-port)
#    gpstart -a
'

