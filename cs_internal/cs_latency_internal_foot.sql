PRO
PRO 1. Top &&cs_top_latency. active SQL per SQL Type as per DB Latency (iff DB AAS > &&cs_aas_threshold_latency.) UNION Top &&cs_top_load. active SQL per SQL Type as per DB Load (iff DB AAS > &&cs_aas_threshold_load.) ordered by DB Latency descending.
PRO 2. Includes only SQL with DB Latency > &&cs_ms_threshold_latency. milliseconds per execution, and which has been active recently.
PRO 3. For an extended output use le.sql (cs_latency_extended.sql). For a reduced output use l.sql (cs_latency.sql). For a reduced output without a report heading use la.sql.
PRO 4. For a time range use lr.sql (cs_latency_range.sql) OR lre.sql (cs_latency_range_extended.sql), both from AWR (15m granularity); or cs_latency_range_iod.sql and cs_latency_range_iod_extended.sql, both from IOD table (1m granularity).
PRO 5. For the last 1 minute use cs_latency_1m.sql OR cs_latency_1m_extended.sql.
PRO 6. For an interval of N seconds use cs_latency_snapshot.sql or cs_latency_snapshot_extended.sql.
PRO 