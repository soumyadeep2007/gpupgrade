-- generates create index statement to re-create indexes on tsquery type.
-- TODO: this doesn't preserve:
-- * COMMENTs
-- * CLUSTERed property
-- We need to emit COMMENT statements and ALTER statements if the index is
-- CLUSTERed. See pg_dump.c:dumpIndex.
SELECT pg_get_indexdef(xc.oid)
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
