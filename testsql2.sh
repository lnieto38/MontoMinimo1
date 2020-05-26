#!/bin/ksh

`sqlplus -s $DB << !
SET SERVEROUTPUT ON
SET FEED OFF
spool ${DIRTMP}/aaa.txt
BEGIN
DBMS_OUTPUT.PUT_LINE('xyz');
END;
spool off
exit;`