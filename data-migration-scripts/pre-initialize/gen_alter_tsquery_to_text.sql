-- Copyright (c) 2017-2021 VMware, Inc. or its affiliates
-- SPDX-License-Identifier: Apache-2.0

-- generates drop index statement to drop indexes on columns of tsquery type.
SELECT $$DROP INDEX $$ || n.nspname || '.' || xc.relname || ';'
FROM
    pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_index x ON c.oid = x.indrelid
        JOIN pg_class xc ON x.indexrelid = xc.oid
WHERE
    EXISTS (
            SELECT 1 FROM pg_catalog.pg_attribute
            WHERE attrelid = c.oid
              AND attnum = ANY(x.indkey)
              AND atttypid = 'pg_catalog.tsquery'::pg_catalog.regtype
              AND NOT attisdropped
        )
  AND c.relkind = 'r'
  AND xc.relkind = 'i'
  AND n.nspname NOT LIKE 'pg_temp_%'
  AND n.nspname NOT LIKE 'pg_toast_temp_%'
  AND n.nspname NOT IN ('pg_catalog',
                        'information_schema')
  AND c.oid NOT IN
      (SELECT DISTINCT parchildrelid
       FROM pg_catalog.pg_partition_rule);

-- generates alter statement to modify tsquery datatype to text datatype
SELECT $$ALTER TABLE $$|| n.nspname || '.' || c.relname || $$ ALTER COLUMN $$ || a.attname || $$ TYPE TEXT; $$
FROM pg_catalog.pg_class c,
     pg_catalog.pg_namespace n,
     pg_catalog.pg_attribute a
WHERE c.relkind = 'r'
  AND c.oid = a.attrelid
  AND NOT a.attisdropped
  AND a.atttypid = 'pg_catalog.tsquery'::pg_catalog.regtype
  AND c.relnamespace = n.oid
  AND n.nspname NOT LIKE 'pg_temp_%'
  AND n.nspname NOT LIKE 'pg_toast_temp_%'
  AND n.nspname NOT IN ('pg_catalog',
                        'information_schema')
  AND c.oid NOT IN
      (SELECT DISTINCT parchildrelid
       FROM pg_catalog.pg_partition_rule);
