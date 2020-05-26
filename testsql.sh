#!/bin/ksh

DiaSemana=`sqlplus -s $DB << !
#set head off
#set pagesize 0000
set pagesize 0 feedback off heading off verify off
DECLARE
pTasaCambioDate VARCHAR2(50) := '20200517';
p_MontoMinimo NUMBER;
begin
spool ${DIRTMP}/20200517-1.txt
PKG_MONTOMINIMO_TRANS.p_CalcMontoMinimoTC(pTasaCambioDate, p_MontoMinimo);
spool off
end;
exit;`

 echo $DiaSemana