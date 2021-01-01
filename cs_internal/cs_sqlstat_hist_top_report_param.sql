PRO
PRO 3. Top: [{&&def_top.}|1-100]
DEF top_n = '&3.';
UNDEF 3;
COL top_n NEW_V top_n NOPRI;
SELECT CASE WHEN '&&top_n.' IS NULL THEN '&&def_top.' ELSE TRIM(TO_CHAR(TO_NUMBER('&&top_n.'))) END AS top_n FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO *=All, TP=Transaction Processing, RO=Read Only, BG=Background, IG=Ignore, UN=Unknown
PRO
PRO 4. SQL Type: [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG] 
DEF kiev_tx = '&4.';
UNDEF 4;
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT UPPER(NVL(TRIM('&&kiev_tx.'), '*')) AS kiev_tx FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 5. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF sql_text_piece = '&5.';
UNDEF 5;
--
PRO
PRO Filtering SQL to reduce search space.
PRO By entering an optional SQL_ID, scope changes from TOP SQL to TOP Plans
PRO
PRO 6. SQL_ID (optional):
DEF sql_id = '&6.';
UNDEF 6;
--
COL def_parsing_schema_name NEW_V def_parsing_schema_name NOPRI;
SELECT LISTAGG(h.parsing_schema_name, '|') WITHIN GROUP (ORDER BY COUNT(*) DESC) AS def_parsing_schema_name
  FROM dba_hist_sqlstat h
 WHERE &&cs_con_id IN (1, h.con_id)
   AND h.dbid = &&cs_dbid.
   AND h.instance_number = &&cs_instance_number.
   AND h.snap_id BETWEEN &&cs_snap_id_from. AND &&cs_snap_id_to.
   AND h.sql_id = COALESCE('&&sql_id.', h.sql_id)
 GROUP BY
       h.parsing_schema_name
/
PRO
PRO 7. Parsing Schema: [{*}|&&def_parsing_schema_name.]
DEF cs2_parsing_schema_name = '&7.';
UNDEF 7;
COL cs2_parsing_schema_name NEW_V cs2_parsing_schema_name NOPRI;
SELECT UPPER(NVL(TRIM('&&cs2_parsing_schema_name.'), '*')) AS cs2_parsing_schema_name FROM DUAL
/
--