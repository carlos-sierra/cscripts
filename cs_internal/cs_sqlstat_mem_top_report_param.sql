PRO
PRO 1. Top: [{&&def_top.}|1-100]
DEF top_n = '&1.';
UNDEF 1;
COL top_n NEW_V top_n NOPRI;
SELECT CASE WHEN '&&top_n.' IS NULL THEN '&&def_top.' ELSE TRIM(TO_CHAR(TO_NUMBER('&&top_n.'))) END AS top_n FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Ignore this parameter when executed on a non-KIEV database.
PRO *=All, TP=Transaction Processing, RO=Read Only, BG=Background, IG=Ignore, UN=Unknown
PRO
PRO 2. SQL Type: [{*}|TP|RO|BG|IG|UN|TP,RO|TP,RO,BG] 
DEF kiev_tx = '&2.';
UNDEF 2;
COL kiev_tx NEW_V kiev_tx NOPRI;
SELECT UPPER(NVL(TRIM('&&kiev_tx.'), '*')) AS kiev_tx FROM DUAL
/
--
PRO
PRO Filtering SQL to reduce search space.
PRO Enter additional SQL Text filtering, such as Table name or SQL Text piece
PRO
PRO 3. SQL Text piece (e.g.: ScanQuery, getValues, TableName, IndexName):
DEF sql_text_piece = '&3.';
UNDEF 3;
--
PRO
PRO Filtering SQL to reduce search space.
PRO By entering an optional SQL_ID, scope changes from TOP SQL to TOP Plans
PRO
PRO 4. SQL_ID (optional):
DEF sql_id = '&4.';
UNDEF 4;
--