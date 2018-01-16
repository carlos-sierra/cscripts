CL BR;
BREAK ON child_number SKIP 1;
COL value FOR A30;
SELECT child_number, value_type, value FROM ((
SELECT /*+ opt_param('parallel_execution_enabled', 'false') */ 
       DISTINCT
       child_number,
       extractvalue(xmlval, '/*/info[@type = "sql_profile"]') sql_profile, 
       extractvalue(xmlval, '/*/info[@type = "sql_patch"]') sql_patch, 
       extractvalue(xmlval, '/*/info[@type = "baseline"]') baseline, 
       extractvalue(xmlval, '/*/info[@type = "outline"]') outline, 
       extractvalue(xmlval, '/*/info[@type = "dynamic_sampling"]') dynamic_sampling, 
       extractvalue(xmlval, '/*/info[@type = "dop"]') dop, 
       extractvalue(xmlval, '/*/info[@type = "dop_reason"]') dop_reason, 
       extractvalue(xmlval, '/*/info[@type = "pdml_reason"]') pdml_reason, 
       extractvalue(xmlval, '/*/info[@type = "idl_reason"]') idl_reason, 
       extractvalue(xmlval, '/*/info[@type = "queuing_reason"]') queuing_reason, 
       extractvalue(xmlval, '/*/info[@type = "px_in_memory"]') px_in_memory, 
       extractvalue(xmlval, '/*/info[@type = "px_in_memory_imc"]') px_in_memory_imc, 
       extractvalue(xmlval, '/*/info[@type = "row_shipping"]') row_shipping, 
       extractvalue(xmlval, '/*/info[@type = "index_size"]') index_size, 
       extractvalue(xmlval, '/*/info[@type = "result_checksum"]') result_checksum, 
       extractvalue(xmlval, '/*/info[@type = "cardinality_feedback"]') cardinality_feedback, 
       extractvalue(xmlval, '/*/info[@type = "performance_feedback"]') performance_feedback, 
       extractvalue(xmlval, '/*/info[@type = "xml_suboptimal"]') xml_suboptimal, 
       extractvalue(xmlval, '/*/info[@type = "adaptive_plan"]') adaptive_plan, 
       extractvalue(xmlval, '/*/spd/cu') spd_cu, 
       extractvalue(xmlval, '/*/info[@type = "gtt_session_st"]') gtt_session_st, 
       extractvalue(xmlval,'/*/info[@type = "plan_hash"]') plan_hash
 FROM (SELECT child_number, xmltype(other_xml) xmlval FROM v$sql_plan_statistics_all WHERE sql_id = '&&sql_id.' AND other_xml IS NOT NULL)
)
UNPIVOT (value FOR value_type IN (sql_profile, sql_patch, baseline, outline, dynamic_sampling, dop, dop_reason, pdml_reason, idl_reason, 
                                  queuing_reason, px_in_memory, px_in_memory_imc, row_shipping, index_size, result_checksum, cardinality_feedback, 
                                  performance_feedback, xml_suboptimal, adaptive_plan, spd_cu, gtt_session_st, plan_hash))
)
ORDER BY 1,2,3
/
