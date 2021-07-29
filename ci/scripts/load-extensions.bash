#! /bin/bash
#
# Copyright (c) 2017-2021 VMware, Inc. or its affiliates
# SPDX-License-Identifier: Apache-2.0

set -eux -o pipefail

./ccp_src/scripts/setup_ssh_to_cluster.sh

echo "Copying extensions to the source cluster..."

# hostname | dbid |         fselocation
#----------+------+-----------------------------
# mdw      |    1 | /data/gpdata/master/gpseg-1
# smdw     |   14 | /data/gpdata/master/gpseg-1

# sdw1     |    2 | /data/gpdata/primary/gpseg0
# sdw1     |    3 | /data/gpdata/primary/gpseg1

# sdw2     |    4 | /data/gpdata/primary/gpseg2
# sdw2     |    5 | /data/gpdata/primary/gpseg3

# sdw3     |    6 | /data/gpdata/primary/gpseg4
# sdw3     |    7 | /data/gpdata/primary/gpseg5

# sdw2     |    8 | /data/gpdata/mirror/gpseg0
# sdw2     |    9 | /data/gpdata/mirror/gpseg1

# sdw3     |   10 | /data/gpdata/mirror/gpseg2
# sdw3     |   11 | /data/gpdata/mirror/gpseg3

# sdw1     |   12 | /data/gpdata/mirror/gpseg4
# sdw1     |   13 | /data/gpdata/mirror/gpseg5

echo "Installing extensions and sample data on source cluster..."
time ssh -n mdw "
    set -eux -o pipefail

    source /usr/local/greenplum-db-source/greenplum_path.sh
    export MASTER_DATA_DIRECTORY=/data/gpdata/master/gpseg-1
    export PGPORT=5432

    echo 'Creating filespace...'
    ssh mdw "mkdir -p /tmp/fs/master"
    ssh smdw "mkdir -p /tmp/fs/master"
    ssh sdw1 "mkdir -p /tmp/fs/master /tmp/fs/primary /tmp/fs/mirror"
    ssh sdw2 "mkdir -p /tmp/fs/master /tmp/fs/primary /tmp/fs/mirror"
    ssh sdw3 "mkdir -p /tmp/fs/master /tmp/fs/primary /tmp/fs/mirror"

    cat << EOF > /tmp/gpfilespace_config
        filespace:fs
        mdw:1:/tmp/fs/master/gpseg-1
        smdw:14:/tmp/fs/master/standby

        sdw1:2:/tmp/fs/primary/gpseg0
        sdw1:3:/tmp/fs/primary/gpseg1

        sdw2:4:/tmp/fs/primary/gpseg2
        sdw2:5:/tmp/fs/primary/gpseg3

        sdw3:6:/tmp/fs/primary/gpseg4
        sdw3:7:/tmp/fs/primary/gpseg5

        sdw2:8:/tmp/fs/mirror/gpseg0
        sdw2:9:/tmp/fs/mirror/gpseg1

        sdw3:10:/tmp/fs/mirror/gpseg2
        sdw3:11:/tmp/fs/mirror/gpseg3

        sdw1:12:/tmp/fs/mirror/gpseg4
        sdw1:13:/tmp/fs/mirror/gpseg5
EOF

    gpfilespace --config /tmp/gpfilespace_config

    echo 'Loading data...'
    psql -d postgres <<SQL_EOF
        CREATE TABLESPACE ts1 FILESPACE fs;
        CREATE TABLESPACE ts2 FILESPACE fs;

        CREATE TABLE foo(i int) TABLESPACE ts1;
        CREATE TABLE bar(i int) TABLESPACE ts2;
SQL_EOF
"

echo "Running the data migration scripts on the source cluster..."
time ssh -n mdw '
    set -eux -o pipefail

    source /usr/local/greenplum-db-source/greenplum_path.sh
    export GPHOME_SOURCE=/usr/local/greenplum-db-source
    export PGPORT=5432

    gpupgrade-migration-sql-generator.bash "$GPHOME_SOURCE" "$PGPORT" /tmp/migration
    gpupgrade-migration-sql-executor.bash "$GPHOME_SOURCE" "$PGPORT" /tmp/migration/pre-initialize || true
'
