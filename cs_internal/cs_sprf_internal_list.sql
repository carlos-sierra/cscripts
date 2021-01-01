
@@&&stgtab_sqlprofile_script.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL created FOR A19;
COL name FOR A30;
COL category FOR A30;
COL status FOR A8;
COL last_modified FOR A19;
COL description FOR A125;
COL outline_hint FOR A125;
--
PRO
PRO SQL PROFILES - LIST (dba_sql_profiles)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(s.created, '&&cs_datetime_full_format.') AS created, 
       s.con_id,
       c.name AS pdb_name,
       s.name,
       s.category,
       s.status,
       TO_CHAR(s.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       s.description
  FROM cdb_sql_profiles s,
       v$containers c
 WHERE s.signature = :cs_signature
   AND c.con_id = s.con_id
 ORDER BY
       s.created, s.con_id, s.name
/
--
PRO
PRO CBO_HINTS
PRO ~~~~~~~~~
-- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
-- SELECT CAST(EXTRACTVALUE(VALUE(x), '/hint') AS VARCHAR2(500)) outline_hints
--   FROM XMLTABLE('/outline_data/hint' 
-- PASSING (SELECT XMLTYPE(d.comp_data) xml 
--            FROM sys.sqlobj$data d
--           WHERE d.obj_type = 1 /* 1:profile, 2:baseline, 3:patch */ 
--             AND d.signature = :cs_signature)) x
-- /
BREAK ON category SKIP PAGE DUPL; 
SELECT d.category, x.outline_hint
  FROM sys.sqlobj$data d,
       XMLTABLE('/outline_data/hint' PASSING XMLTYPE(d.comp_data) COLUMNS outline_hint VARCHAR2(500) PATH '.') x
 WHERE d.obj_type = 1 /* 1:profile, 2:baseline, 3:patch */ 
   AND d.signature = :cs_signature
/
CLEAR BREAK;