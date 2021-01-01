COL created FOR A19;
COL name FOR A30;
COL category FOR A30;
COL status FOR 99999999;
COL last_modified FOR A19;
COL description FOR A125;
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
