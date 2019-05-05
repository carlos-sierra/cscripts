META360 v1602 (2016-09-17) by Carlos Sierra

META360 is a "free to use" tool to extract DDL metadata out of an Oracle database.
META360 installs nothing. For better results execute connected as DBA or application user.

Steps
~~~~~
1. Unzip meta360-master.zip, navigate to the root meta360-master directory, 
   and connect as DBA, or any user with access to metadata for target schema(s).

   $ unzip meta360-master.zip
   $ cd meta360-master
   $ sqlplus dba_user/dba_pwd

2. Execute desired scope: 
   set of application schemas, or one schema, or one table, or one object:

   SQL> @sql/get_top_N_schemas.sql
   
   or
   
   SQL> @sql/get_schema.sql <SCHEMA>

   or
   
   SQL> @sql/get_table.sql <SCHEMA> <TABLE_NAME>

   or
   
   SQL> @sql/get_object.sql <SCHEMA> <OBJECT_NAME> <OBJECT_TYPE>


****************************************************************************************

Notes
~~~~~
1. All object names, including schema, are case sensitive. Use UPPER case in most cases.

2. OBJECT_TYPE: TABLE, INDEX, VIEW, SYNONYM, TYPE, PACKAGE, TRIGGER, SEQUENCE, PROCEDURE, 
                LIBRARY, FUNCTION, MATERIALIZED_VIEW

3. Always execute connecting into SQL*Plus while on the meta360-master directory. In
   other words: on the same directory where this readme.txt is located.
   
4. Use set_tool_configuration.sql for some configuration options of this tool.

****************************************************************************************
   
    META360 - DDL metadata extraction for one or multiple application schemas
    Copyright (C) 2016  Carlos Sierra

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

****************************************************************************************
