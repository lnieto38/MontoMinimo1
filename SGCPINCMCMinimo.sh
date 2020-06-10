#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCPINCMCMminimo.sh
##                Autor : LDN
##       Codigo Inicial : 09/05/2020
##          Descripcion : SC que toma el Monto Minimo y envia a transaccional
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  11/05/2020 LDN   1.00    Codigo Inicial
##  01/06/2020 LDN   1.50    Cambios Significativos 
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPINCMCMinimo"       # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=1.50                    # Ultima Version del Programa
dpFec="20200602"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]

## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa
dFecProc=`getdate`            # Fecha Actual [Formato:AAAAMMDD]
vFileDat=$DIRTMP/MontoMinimo.tmp

## Parametros
################################################################################

pFecProc="$1"                 # Fecha de Proceso [Formato:AAAAMMDD]
vOpcRepro="$2"                  # Opcion de Reproceso

## Variables de Trabajo
################################################################################

vFileCTL=""                   # Archivo de Control del Proceso
vNumSec=""                    # Numero de Secuencia
vCTAMC=""                     # Codigo de Tipo de Archivo de MasterCard


################################################################################
## DECLARACION DE FUNCIONES
################################################################################

# f_admCTL () | administra el Archivo de Control (lee/escribe)
# Parametros
#   pOpcion   : R=lee/W=escribe
################################################################################
f_admCTL ()
{

  # Estructura del Archivo de Control
  # [01-02] Codigo de Entidad Adquirente
  # [04-11] Fecha de Proceso
  # [16-16] Estado del Proceso (P=Pendiente/X=En Ejecucion/E=Fin ERROR/F=Fin OK)
  # [18-19] Codigo del Sub-Proceso
  # [21-33] Fecha y Hora de Actualizacion de los Estados [AAAAMMDDHHMMSS]

  pOpcion="$1"

  if [ "$pOpcion" = "R" ]; then
     if ! [ -f "$vFileCTL" ]; then
        # Crea el Archivo CTL
        vEstProc="P"
        #vSubProc="00"
        echo "${pEntAdq}|${pFecProc}|${vEstProc}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
     else
        vEstProc=`awk '{print substr($0,16,1)}' $vFileCTL`
     fi
  else
     echo "${pEntAdq}|${pFecProc}|${vEstProc}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
  fi

}


# f_finerr | error en el programa, elimina archivos de trabajo
# Parametros
#   pMsg : mensaje a mostrar
################################################################################
f_finerr ()
{
# <Inicio RollBack>
# <Fin RollBack>
pMsg="$1"
if [ "${pMsg}" != "" ]; then
   f_fhmsg "${pMsg}"
fi
#f_msgtit E
}


# f_vrfvalret | verifica valor de retorno, fin error si el valor es 1
# Parametros
#   pValRet : valor de retorno
#   pMsgErr : mensaje de error
################################################################################
f_vrfvalret ()
{
pValRet="$1"
pMsgErr="$2"
if [ "${pValRet}" != "0" ]; then
   f_finerr "${pMsgErr}"
fi
}


# f_parametros | muestra los parametros de ejecucion
################################################################################
f_parametros ()
{
#f_fechora ${dFecProc}
echo "
********************************************************************************
${dpNom} - Parametros de Ejecucion

Parametro 1 (obligatorio) : Fecha de Proceso [Formato=YYYYMMDD]
Parametro 2 (opcional) : Opcion de Reproceso [s/S]

********************************************************************************
Programa: ${dpNom} | Version: ${dpVer} | Modificacion: 
" | more
}


################################################################################

## Validacion de Parametros
################################################################################

# Menu de parametros
if [ $# -eq 0 ]; then
   f_parametros;
   exit 0;
fi

# Parametros obligatorios (4)
if [ $# -lt 1 ]; then
   f_parametros;
   exit 1;
fi


##############################################################################################

## Fecha de Proceso
################################################################################

if [ "${pFecProc}" = "" ]; then
   vFecProc=`getdate`
else
   ValFecha.sh ${pFecProc}
   vRet="$?"
   if [ "$vRet" != "0" ]; then
      echo "Fecha de Proceso Incorrecta (FecProc=${pFecProc})"  
       echo
       exit 1;
   fi
   vFecProc=${pFecProc}
fi

################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

if [ "${pFecProc}" -ne "${dFecProc}" ]; then
 echo "********************************************************************************"
 echo `date '+%H:%M:%S'` "> La Fecha de Proceso no puede ser menor ni mayor a la fecha actual ${pFecProc}" 
 echo "********************************************************************************"
else
 vFileLOG="${DIRLOG}/SGCPINCMCMinimo$dFecProc.log"
 #vFileLOGERR="${DIRLOG}/repcompBM$FechaREP.err"
 pEntAdq="BM"
 #pFecProc=$FechaREP
 vFileCTL="${DIRDAT}/SGCPINCMCMinimo${pEntAdq}.${pFecProc}.CTL"
 f_admCTL R
 vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
   if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" = "" ]; then
     echo "********************************************************************************"
     echo "OPCION REPROCESO"
     echo "********************************************************************************"
     echo
     tput setf 8
     echo "El valor de Monto Minimo para la fecha ${pFecProc} ya ha sido procesado"
     tput setf 7
     echo "Desea Reprocesar? (S=Si/N=No/<Enter>=No) => \c"
     echo
     read vOpcRepro 
     continue
   fi
   if [ -f "$vFileLOG" ]; then
     rm -f $vFileLOG
   fi 
    touch $vFileLOG
    if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" = "S" ] || [ "$vOpcRepro" = "s" ] || [ "$vEstProc" != "F" ] ; then
      echo "********************************************************************************"         
               echo 
               echo 
               echo "         Archivo de Control : `basename ${vFileCTL}`"
               echo "                 Directorio : `dirname ${vFileCTL}`"
               echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
               echo "                 Directorio : `dirname ${vFileLOG}`"
               echo                 

      echo "********************************************************************************"
      echo 
      echo "**********************************************************"  [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`] | tee -a $vFileLOG
      echo "INICIO | ${dpNom} EJECUCION DE MONTO MINIMO" | tee -a $vFileLOG
      echo "********************************************************************************" | tee -a $vFileLOG
      tput setf 8
      echo `date '+%H:%M:%S'` "> Seteando el valor del Monto Minimo fecha de Proceso: $pFecProc" | tee -a $vFileLOG
      tput setf 7
      ora= `sqlplus -s $DB << !
      SET SERVEROUTPUT ON
      SET FEED OFF
      spool ${DIRTMP}/mm${pFecProc}.txt
      DECLARE
      p_TasaCambioDate VARCHAR2(50) := ${pFecProc};
      p_MontoMinimo VARCHAR2(50);
      BEGIN
      PQMONTOMINIMO.p_CalcMontoMinimoTC(p_TasaCambioDate, p_MontoMinimo);
      END;
      /
      spool off
      exit;`  2> /dev/null 
      tput setf 8
      echo `date '+%H:%M:%S'` "> Procediendo a descargar de DB Monto Minimo de fecha $pFecProc" | tee -a $vFileLOG
      tput setf 7
      sed 's/ //g' $DIRTMP/mm$pFecProc.txt > $DIRTMP/mm$pFecProc-1.txt
      cat $DIRTMP/mm$pFecProc-1.txt > $DIRTMP/mm$pFecProc.txt
      rm -f  $DIRTMP/mm$pFecProc-1.txt
      pMontoMin=$(<${DIRTMP}/mm${pFecProc}.txt)
      pCont=`expr length $pMontoMin 2> /dev/null`  
      oraCont=`grep -i 'ORA' $DIRTMP/mm$pFecProc.txt | wc -l`
        if [ "$oraCont" -gt 0 ]; then
         echo "********************************************************************************" | tee -a $vFileLOG
         echo `date '+%H:%M:%S'` "> ERROR | Errores ORA en la ejecucion del Paquete favor informar DBA" | tee -a $vFileLOG
         cat $DIRTMP/mm$pFecProc.txt >> $vFileLOG 
         echo "********************************************************************************" | tee -a $vFileLOG
         sqlplus -s $DB @$DIRBIN/alertacie INC MMINIMO "Error_Ejecucion_de_Package_Fecha_$pFecProc"
         rm -f $DIRTMP/mm$pFecProc.txt 
         exit 0
        else             
           if  [ ! -f $DIRTMP/mm$pFecProc.txt ] || [ -s DIRTMP/mm$pFecProc.txt ] || [ "$pCont" -ne 12 ] || [ -n "$(printf '%s\n' $pMontoMin | sed 's/[0-9]//g')" ];then
             echo
             echo "********************************************************************************" | tee -a $vFileLOG
             tput setf 8
             echo `date '+%H:%M:%S'` "> El archivo no existe o no cumple con las especificaciones" | tee -a $vFileLOG
             echo "********************************************************************************" | tee -a $vFileLOG
             sqlplus -s $DB @$DIRBIN/alertacie INC MMINIMO "Error_Especificaciones_de_Archivo_MontoMinimo_Fecha_$pFecProc"
             tput setf 7
             exit 0          
           else 
             echo
             echo "********************************************************************************" | tee -a $vFileLOG
             tput setf 8
             echo `date '+%H:%M:%S'` "> El archivo cumple con todas las especificaciones" | tee -a $vFileLOG
             tput setf 7
             echo "********************************************************************************" | tee -a $vFileLOG
             chmod 755 ${DIRTMP}/mm${pFecProc}.txt
             mv ${DIRTMP}/mm${pFecProc}.txt ${DIROUT}/DMINIMO.DAT 
             #Aqui se incluye las lineas para pasar por sftp el archivo 
             #cd ${DIROUT}
             #echo "cd /#d11/ccal/datos" > $DIRTMP/MontoMinimo$pFecProc.PAR.SFTP 
             #echo "put ${DIROUT}/DMINIMO_prueba.DAT" >> $DIRTMP/MontoMinimo$pFecProc.PAR.SFTP
             #sftp -b $DIRTMP/MontoMinimo$pFecProc.PAR.SFTP $FTP_USERSTR@10.161.80.169 >> $vFileLOG 2>&1
             echo `date '+%H:%M:%S'` "> Envio via FTP el DMINIMO.DAT al STRATUS" | tee -a $vFileLOG
             echo "$DIRSTRDAT>DMINIMO.DAT" > $vFileDat
             echo "$DIROUT/DMINIMO.DAT" >> $vFileDat
             if [ -f $vFileDat ]; then
                sh FTPSun2Str1.sh < $vFileDat ;
                echo "********************************************************************************" | tee -a $vFileLOG
                echo  `date '+%H:%M:%S'` "> Revisar que el archivo DMINIMO.DAT ya se encuentra en el STRATUS" | tee -a $vFileLOG
                echo "********************************************************************************" | tee -a $vFileLOG
                ENDSTATUS=0
             else
               echo "********************************************************************************" | tee -a $vFileLOG
                echo `date '+%H:%M:%S'` "> No se ha creado el archivo $vFileDat" | tee -a $vFileLOG
                echo "********************************************************************************" | tee -a $vFileLOG
                ENDSTATUS=1
                exit 1;
             fi 
                rm -f $vFileDat            
              if [ "$ENDSTATUS" = "0" ]
                then
                 vEstProc="F"
                 echo "**********************************************************"  [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`] | tee -a $vFileLOG
                 echo "FIN OK| PROCESO MONTO MINIMO FINALIZADO SATISFACTORIAMENTE" | tee -a $vFileLOG
                 echo "********************************************************************************" | tee -a $vFileLOG
                else
                 vEstProc="E"
                 echo "**********************************************************"  [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`] | tee -a $vFileLOG
                 echo "FIN ERROR| NO PUDO COMPLETARSE EL PROCESO DE MONTO MINIMO, FAVOR REVISAR" | tee -a $vFileLOG
                 echo "********************************************************************************" | tee -a $vFileLOG
                fi
                f_admCTL W
           fi
         exit 0 
        fi 
   fi
    echo "Fin de Programa"     
fi

################################################################################
## FIN | PROCEDIMIENTO PRINCIPAL
################################################################################
