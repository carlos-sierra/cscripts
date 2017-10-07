@list_plans.sql

ACC plan_name PROMPT 'Enter optional Plan Name: ';
ACC attribute_name PROMPT 'Enter Attribute Name (ENABLED, FIXED, AUTOPURGE, PLAN_NAME or DESCRIPTION): ';
ACC attribute_value PROMPT 'Enter Attribute Value (for flags enter YES or NO): ';

VAR plans NUMBER;

BEGIN
  :plans := DBMS_SPM.alter_sql_plan_baseline (
    sql_handle      => '&&sql_handle.',
    plan_name       => '&&plan_name.',
    attribute_name  => '&&attribute_name.',
    attribute_value => '&&attribute_value.' );
END;
/

PRINT plans;

@list_plans.sql
