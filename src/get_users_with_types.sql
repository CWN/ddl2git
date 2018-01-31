SET echo OFF heading OFF feedback OFF
SET VERIFY OFF
SET linesize 150
SET pages 0

-- exclude predefined accounts
-- https://docs.oracle.com/database/121/TDPSG/GUID-3EC7A894-D620-4497-AFB1-64EB8C33D854.htm#TDPSG20030

SELECT username || '|' || object_type user_types
  FROM (  SELECT DISTINCT usr.username, dbo.object_type
            FROM sys.dba_users usr,
                 (SELECT owner,
                         CASE WHEN object_type = 'QUEUE' THEN 'AQ_QUEUE' ELSE TRANSLATE (object_type, ' ', '_') END
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
                                 AND (dbo.owner, dbo.object_name) NOT IN (SELECT owner, table_name
                                                                            FROM sys.dba_nested_tables)
                                 --Exlclude overflow segments, their DDL is part of their parent table.
                                 AND (dbo.owner, dbo.object_name) NOT IN (SELECT owner, table_name
                                                                            FROM dba_tables
                                                                           WHERE iot_type = 'IOT_OVERFLOW')
                          UNION
                          SELECT owner, 'AQ_QUEUE_TABLE' object_type, queue_table object_name FROM SYS.DBA_QUEUE_TABLES))
                 dbo
           WHERE     usr.default_tablespace NOT IN ('SYSTEM', 'SYSAUX')
                 AND usr.username NOT IN ('ANONYMOUS',
                                          'AUDSYS',
                                          'CTXSYS',
                                          'DBSNMP',
                                          'LBACSYS',
                                          'MDSYS',
                                          'OLAPSYS',
                                          'ORDDATA',
                                          'ORDPLUGINS',
                                          'ORDSYS',
                                          'SI_INFORMTN_SCHEMA',
                                          'SYS',
                                          'SYSBACKUP',
                                          'SYSDG',
                                          'SYSKM',
                                          'SYSTEM',
                                          'WMSYS',
                                          'XDB',
                                          'DIP',
                                          'MDDATA',
                                          'ORACLE_OCM',
                                          'SPATIAL_CSW_ADMIN_USR',
                                          'SPATIAL_WFS_ADMIN_USR',
                                          'XS$NULL',
                                          'HR',
                                          'OE',
                                          'PM',
                                          'IX',
                                          'SH')
                 AND usr.username = dbo.owner
        ORDER BY usr.username, dbo.object_type);

EXIT
/