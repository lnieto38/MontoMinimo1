#!/bin/ksh

`sqlplus -s $DB << !
DECLARE
pTasaCambioDate VARCHAR2(50) := '20200517';
p_MontoMinimo NUMBER;
SET SERVEROUTPUT ON
SET FEED OFF
spool ${DIRTMP}/bbb.txt
BEGIN
PKG_MONTOMINIMO_TRANS.p_CalcMontoMinimoTC(pTasaCambioDate, p_MontoMinimo);
DBMS_OUTPUT.PUT_LINE(p_MontoMinimo);
END;
spool off
exit;`