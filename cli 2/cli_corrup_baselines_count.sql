 select count(*) as sp_count
, NVL(sum(DECODE(p.signature, null,1)),0) as corrupt_count
from sys.sqlobj$ o
, ( select distinct signature, category, obj_type, plan_id
from sys.sqlobj$plan
) p
where o.signature = p.signature(+)
and o.category = p.category(+)
and o.obj_type = p.obj_type(+)
and o.plan_id = p.plan_id(+)
and o.obj_type = 2
and bitand(o.flags,128) = 128;