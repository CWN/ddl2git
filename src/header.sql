set echo off heading off feedback off
SET VERIFY off
set pages 0
set trimspool ON
set long 9999999
set linesize 450
SET LONGCHUNKSIZE 9999999
exec dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM,'SQLTERMINATOR',TRUE);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',TRUE);
