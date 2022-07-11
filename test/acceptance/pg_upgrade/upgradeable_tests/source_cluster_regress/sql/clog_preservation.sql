-- Copyright (c) 2017-2022 VMware, Inc. or its affiliates
-- SPDX-License-Identifier: Apache-2.0

-- Check to ensure that we don't accidentally truncate CLOG during segment
-- upgrade and end up with unfrozen user tuples referring to truncated CLOG.

--------------------------------------------------------------------------------
-- Create and setup upgradeable objects
--------------------------------------------------------------------------------

CREATE TABLE foo(i int);
-- Insert some tuples in a segment that will refer to the current clog file
INSERT INTO foo SELECT 1 FROM generate_series(1, 5);

-- Burn through 1 CLOG segment on the master and seg 0

!\retcode (/bin/bash -c "source ${GPHOME_SOURCE}/greenplum_path.sh && ${GPHOME_SOURCE}/bin/gpconfig -c debug_burn_xids -v on --skipvalidation");
!\retcode (/bin/bash -c "source ${GPHOME_SOURCE}/greenplum_path.sh && ${GPHOME_SOURCE}/bin/gpstop -au");

!\retcode echo "INSERT INTO foo VALUES(1);" > /tmp/clog_preservation.sql;
!\retcode $GPHOME_SOURCE/bin/pgbench -n -f /tmp/clog_preservation.sql -c 8 -t 512 isolation2test;

!\retcode (/bin/bash -c "source ${GPHOME_SOURCE}/greenplum_path.sh && ${GPHOME_SOURCE}/bin/gpconfig -r debug_burn_xids --skipvalidation");
!\retcode (/bin/bash -c "source ${GPHOME_SOURCE}/greenplum_path.sh && ${GPHOME_SOURCE}/bin/gpstop -au");
!\retcode rm /tmp/clog_preservation.sql;

SELECT count(*) FROM foo;
