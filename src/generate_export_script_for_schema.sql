set echo off heading off feedback off
SET VERIFY OFF
set linesize 350
set pages 0

spool '&&1'
set sqlterminator off

-- Replace /,$ and _space_ symbols.
-- / - used for FS directory separator
-- $ - special usage in BASH
-- _space_ - bug in some version of sqlplus when spool not working for filename with space

SELECT 'spool '''|| dbo.owner || '/' || dbo.object_type || '/' || replace(replace(translate(dbo.object_name,' ','-'),'/','_SLASHSIGN_'), '$', '_DOLLARSIGN_') || '.sql'';
SELECT DBMS_METADATA.GET_DDL('''|| dbo.object_type  ||''', ''' || dbo.object_name || ''', ''' || dbo.owner || ''') FROM DUAL;
spool off;'
  FROM sys.dba_users usr,
       (SELECT owner,
                CASE
                   WHEN object_type = 'QUEUE' THEN 'AQ_QUEUE'
                   ELSE TRANSLATE (object_type, ' ', '_')
                 END
                   object_type,
               object_name
          FROM (SELECT dbo.owner, dbo.object_type, dbo.object_name
                  FROM sys.dba_objects dbo
                 WHERE     dbo.object_type NOT IN ('INDEX PARTITION',
                                                   'TABLE PARTITION',
                                                   'DATABASE LINK',
                                                   'TABLE SUBPARTITION',
                                                   'INDEX SUBPARTITION',
                                                   'LOB PARTITION',
                                                   'LOB',
                                                   'PACKAGE BODY',
                                                   'JOB',
                                                   'JAVA DATA',
                                                   'CONSUMER GROUP',
                                                   'CONTEXT',
                                                   'DESTINATION',
                                                   'DIRECTORY',
                                                   'EDITION',
                                                   'EVALUATION CONTEXT',
                                                   'JAVA CLASS',
                                                   'JAVA RESOURCE',
                                                   'JOB CLASS',
                                                   'PROGRAM',
                                                   'RESOURCE PLAN',
                                                   'RULE',
                                                   'RULE SET',
                                                   'SCHEDULE',
                                                   'SCHEDULER GROUP',
                                                   'UNDEFINED',
                                                   'UNIFIED AUDIT POLICY',
                                                   'WINDOW')
                       -- Ignore system-generated types that support collection processing.
                       AND NOT (dbo.object_type = 'TYPE' AND dbo.object_name LIKE 'SYS_PLSQL_%')
                       --Exclude nested tables, their DDL is part of their parent table.
                       AND (dbo.owner, dbo.object_name) NOT IN (SELECT owner, table_name FROM sys.dba_nested_tables)
                       --Exlclude overflow segments, their DDL is part of their parent table.
                       AND (dbo.owner, dbo.object_name) NOT IN (SELECT owner, table_name
                                                                  FROM dba_tables
                                                                 WHERE iot_type = 'IOT_OVERFLOW')
                UNION
                SELECT owner, 'AQ_QUEUE_TABLE' object_type, queue_table object_name FROM SYS.DBA_QUEUE_TABLES)) dbo
 WHERE     usr.username = UPPER('&&2')
       AND usr.username = dbo.owner
ORDER BY usr.username, dbo.object_type, dbo.object_name
/
spool off
exit
/