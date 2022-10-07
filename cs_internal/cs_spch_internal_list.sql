
@@&&stgtab_sqlpatch_script.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL created FOR A19;
COL name FOR A30;
COL category FOR A30;
COL status FOR A8;
COL last_modified FOR A19;
COL description FOR A100 HEA 'Description' WOR;
COL outline_hint FOR A125;
--
PRO
PRO SQL PATCHES - LIST (dba_sql_patches)
PRO ~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(s.created, '&&cs_datetime_full_format.') AS created, 
       s.con_id,
       c.name AS pdb_name,
       s.name,
       s.category,
       s.status,
       TO_CHAR(s.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       s.description
  FROM cdb_sql_patches s,
       v$containers c
 WHERE s.signature = :cs_signature
   AND c.con_id = s.con_id
 ORDER BY
       s.created, s.con_id, s.name
/
--
DEF cs_obj_type = '3';
@@&&cs_list_cbo_hints.