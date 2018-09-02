COL created FOR A19;
COL name FOR A30;
COL category FOR A30;
COL last_modified FOR A19;
COL description FOR A150;
COL outline_hints FOR A500;
--
PRO
PRO SQL PROFILES ON STAGING TABLE (&&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_sqlprof)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(created, '&&cs_datetime_full_format.') created, 
       obj_name name,
       category,
       status,
       TO_CHAR(last_modified, '&&cs_datetime_full_format.') last_modified, 
       description
  FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_sqlprof
 WHERE signature = :cs_signature
 ORDER BY
       created, obj_name
/
--
PRO
PRO SQL PROFILES - LIST (dba_sql_profiles)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(created, '&&cs_datetime_full_format.') created, 
       name,
       category,
       status,
       TO_CHAR(last_modified, '&&cs_datetime_full_format.') last_modified, 
       description
  FROM dba_sql_profiles
 WHERE signature = :cs_signature
 ORDER BY
       created, name
/
--
PRO
PRO CBO_HINTS
PRO ~~~~~~~~~
SET HEA OFF;
SELECT CAST(EXTRACTVALUE(VALUE(x), '/hint') AS VARCHAR2(500)) outline_hints
  FROM XMLTABLE('/outline_data/hint' 
PASSING (SELECT XMLTYPE(d.comp_data) xml 
           FROM sys.sqlobj$data d
          WHERE d.obj_type = 1 /* 1:profile, 2:baseline, 3:patch */ 
            AND d.signature = :cs_signature)) x
/
SET HEA ON;
--
PRO
PRO SQL PROFILES - LIST (dba_sql_profiles)
PRO ~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(created, '&&cs_datetime_full_format.') created, 
       name,
       category,
       status,
       TO_CHAR(last_modified, '&&cs_datetime_full_format.') last_modified, 
       description
  FROM dba_sql_profiles
 WHERE signature = :cs_signature
 ORDER BY
       created, name
/
--
