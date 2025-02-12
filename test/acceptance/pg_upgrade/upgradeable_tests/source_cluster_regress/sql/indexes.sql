-- Copyright (c) 2017-2022 VMware, Inc. or its affiliates
-- SPDX-License-Identifier: Apache-2.0

-- Test to ensure that bpchar_pattern_ops and bitmap indexes are invalidated
-- during an upgrade.

--------------------------------------------------------------------------------
-- Create and setup upgradeable objects
--------------------------------------------------------------------------------

CREATE TABLE tbl_with_bpchar_pattern_ops_index(a int, b bpchar, c bpchar);
CREATE INDEX bpchar_idx on tbl_with_bpchar_pattern_ops_index  (c, lower(b) bpchar_pattern_ops);
INSERT INTO tbl_with_bpchar_pattern_ops_index SELECT i, (i%2)::bpchar, '1' FROM GENERATE_SERIES(1,20)i;

CREATE TABLE tbl_with_bitmap_index(a int, b int);
CREATE INDEX bitmap_idx on tbl_with_bitmap_index using bitmap(b);
INSERT INTO tbl_with_bitmap_index SELECT i,i%2 FROM generate_series(1,10)i;
