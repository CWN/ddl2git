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

SELECT 'spool '''|| dbo.owner || '/' || translate(dbo.object_type,' ','_') || '/' || replace(replace(translate(dbo.object_name, ' ', '_'),'/','_SLASHSIGN_'), '$', '_DOLLARSIGN_') || '.sql'';
SELECT DBMS_METADATA.GET_DDL('''|| translate(dbo.object_type,' ','_')  ||''', ''' || dbo.object_name || ''', ''' || dbo.owner || ''') FROM DUAL;
spool off;'
    FROM sys.dba_users usr, sys.dba_objects dbo
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
         AND dbo.object_type NOT IN ('INDEX PARTITION',
                                     'TABLE PARTITION',
                                     'DATABASE LINK',
                                     'TABLE SUBPARTITION',
                                     'INDEX SUBPARTITION',
                                     'LOB PARTITION',
                                     'LOB',
                                     'PACKAGE BODY',
                                     'JOB',
                                     'JAVA DATA')
         -- Ignore system-generated types that support collection processing.
         AND NOT (dbo.object_type = 'TYPE' AND dbo.object_name LIKE 'SYS_PLSQL_%')
         --Exclude nested tables, their DDL is part of their parent table.
         AND (dbo.owner, dbo.object_name) NOT IN (SELECT owner, table_name FROM sys.dba_nested_tables)
         --Exlclude overflow segments, their DDL is part of their parent table.
         AND (dbo.owner, dbo.object_name) NOT IN (SELECT owner, table_name
                                                    FROM dba_tables
                                                   WHERE iot_type = 'IOT_OVERFLOW')
ORDER BY usr.username, dbo.object_type, dbo.object_name
/
spool off
exit
/