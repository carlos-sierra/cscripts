PRO
PRO &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline;
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) AS "ROWS" FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline;
--
PRO
PRO DELETE &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline WHERE signature = COALESCE(TO_NUMBER('&&cs_signature.'), signature) AND plan_id = COALESCE(TO_NUMBER('&&cs_plan_id.'), plan_id);
PRO ~~~~~~
DELETE &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline WHERE signature = COALESCE(TO_NUMBER('&&cs_signature.'), signature) AND plan_id = COALESCE(TO_NUMBER('&&cs_plan_id.'), plan_id);
PRO
PRO &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline;
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) AS "ROWS" FROM &&cs_stgtab_owner..&&cs_stgtab_prefix._stgtab_baseline;
--