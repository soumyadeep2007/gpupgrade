-- Copyright (c) 2017-2021 VMware, Inc. or its affiliates
-- SPDX-License-Identifier: Apache-2.0

--------------------------------------------------------------------------------
-- Validate that the upgradeable objects are functional post-upgrade
--------------------------------------------------------------------------------

SELECT * FROM p_basic;

SELECT * FROM p_add_partition_test;

SELECT * FROM p_add_list_partition_test;

SELECT * FROM p_split_partition_test;

SELECT id, age FROM p_subpart_heap_1_prt_partition_id_2_prt_subpartition_age_first;
SELECT id, age FROM p_subpart_heap_1_prt_partition_id_2_prt_subpartition_age_second;
SELECT id, age FROM p_subpart_heap;

SELECT c, d FROM p_dropcol WHERE a=10;
