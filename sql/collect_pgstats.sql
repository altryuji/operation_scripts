\t
\f ','
\a
\pset pager off

-- count of users table
SELECT reltuples FROM pg_class WHERE relname='users';
\g ${LOG_DIR}/pgstats_users.log.${HEROKU_APP}.${TIMESTAMP}

-- count of accounts table
SELECT reltuples FROM pg_class WHERE relname='accounts';
\g ${LOG_DIR}/pgstats_accounts.log.${HEROKU_APP}.${TIMESTAMP}

-- count of content_downloads table
SELECT reltuples FROM pg_class WHERE relname='content_downloads';
\g ${LOG_DIR}/pgstats_content_downloads.log.${HEROKU_APP}.${TIMESTAMP}

-- through put / error
SELECT xact_commit, xact_rollback FROM pg_stat_database WHERE datname = '${DBNAME}';
\g ${LOG_DIR}/pgstats_throughput_and_error.log.${HEROKU_APP}.${TIMESTAMP}

-- cache hit ratio
SELECT blks_hit, blks_read, round(blks_hit * 100 / (blks_hit+blks_read), 2) AS cache_hit_ratio FROM pg_stat_database WHERE blks_read > 0 AND datname = '${DBNAME}';
\g ${LOG_DIR}/pgstats_cache_hit_ratio.log.${HEROKU_APP}.${TIMESTAMP}

-- cache hit ratio per table
SELECT relname, heap_blks_hit, heap_blks_read, round(heap_blks_hit * 100 / (heap_blks_hit+heap_blks_read), 2) AS cache_hit_ratio FROM pg_statio_user_tables WHERE heap_blks_read > 0 ORDER BY cache_hit_ratio;
\g ${LOG_DIR}/pgstats_cache_hit_ratio_per_table.log.${HEROKU_APP}.${TIMESTAMP}

-- cache hit ratio per index
SELECT relname, idx_blks_hit, idx_blks_read, indexrelname, round(idx_blks_hit * 100 / (idx_blks_hit+idx_blks_read), 2) AS cache_hit_ratio FROM pg_statio_user_indexes WHERE idx_blks_read > 0 ORDER BY cache_hit_ratio;
\g ${LOG_DIR}/pgstats_cache_hit_ratio_per_index.log.${HEROKU_APP}.${TIMESTAMP}

-- seq scan
SELECT relname, seq_scan, seq_tup_read, seq_tup_read/seq_scan AS tup_per_read FROM pg_stat_user_tables WHERE seq_scan > 0 ORDER BY tup_per_read DESC;
\g ${LOG_DIR}/pgstats_seq_scan.log.${HEROKU_APP}.${TIMESTAMP}

-- garbage
SELECT relname, n_live_tup, n_dead_tup, round(n_dead_tup * 100 / (n_dead_tup+n_live_tup), 2)  AS dead_ratio, pg_size_pretty(pg_relation_size(relid)) FROM pg_stat_user_tables WHERE n_live_tup > 0 ORDER BY dead_ratio DESC;
\g ${LOG_DIR}/pgstats_garbage.log.${HEROKU_APP}.${TIMESTAMP}

-- hot
SELECT relname, n_tup_upd, n_tup_hot_upd, round(n_tup_hot_upd * 100 / n_tup_upd, 2) AS hot_upd_ratio FROM pg_stat_user_tables WHERE n_tup_upd > 0 ORDER BY hot_upd_ratio;
\g ${LOG_DIR}/pgstats_hot.log.${HEROKU_APP}.${TIMESTAMP}

-- long transaction
SELECT pid, waiting, (current_timestamp - xact_start)::interval(3) AS duration, query FROM pg_stat_activity WHERE pid <> pg_backend_pid();
\g ${LOG_DIR}/pgstats_long_transaction.log.${HEROKU_APP}.${TIMESTAMP}

-- lock
SELECT l.locktype, c.relname, l.pid, l.mode, substring(a.query, 1, 6) AS query, (current_timestamp - xact_start)::interval(3) AS duration FROM pg_locks l LEFT OUTER JOIN pg_stat_activity a ON l.pid = a.pid LEFT OUTER JOIN pg_class c ON l.relation = c.oid WHERE NOT l.granted ORDER BY l.pid;
\g ${LOG_DIR}/pgstats_lock.log.${HEROKU_APP}.${TIMESTAMP}

-- io of database
SELECT blk_read_time, blk_write_time FROM pg_stat_database WHERE datname = '${DBNAME}';
\g ${LOG_DIR}/pgstats_io_database.log.${HEROKU_APP}.${TIMESTAMP}

-- io time per sql
SELECT calls, total_time::numeric(20, 2), substring(query, 1, 200), blk_read_time::numeric(20, 2), blk_write_time::numeric(20, 2) FROM pg_stat_statements ORDER BY total_time DESC LIMIT 3;
\g ${LOG_DIR}/pgstats_io_per_sql.log.${HEROKU_APP}.${TIMESTAMP}

\q
