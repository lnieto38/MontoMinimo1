#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCPLIQCIE.sh
##                Autor : SSM
##       Codigo Inicial : 06/11/2007
##          Descripcion : Cierre de Liquidacion
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  06/11/2007 SSM   1.00    Codigo Inicial
##  26/05/2008 WC    1.20    Reportes de Remesa y Liquidacion Sodexho
##  25/06/2008 JMG   1.30    Reportes de Remesa y Liquidacion Sodexho
##  05/08/2008 JMG   1.40    Correccion Interfaz para Comercios en Linea
##  15/01/2009 JMG   1.50    Actualizacion Script
##  10/03/2009 JMG   1.60    Proceso Carga de Resumen de Ventas
##  29/04/2009 JMG   1.70    Envio de Archivos Sodexho RM y LQ a SUN4200
##  15/06/2009 JMG   1.80    Carga de Reportes de Facturacion
##  02/07/2009 JMG   1.90    Actualizacion de Script
##  07/08/2009 JMG   2.10    Carga de Reportes RTPLATCO
##  04/11/2009 JMG   2.20    Generacion de Archivos Casa Matriz
##  04/11/2009 JMG   2.30    Actualizacion de Tasas IVA e ISLR
##  04/12/2009 JMG   2.40    Ordenamiento de ejecucion de procesos
##  07/12/2011 EEV   2.41    Cambio de Mensajes de Hora de Cierre
##  16/02/2012 DCB   2.42    Creacion de Archivo de Control
##  24/11/2012 DCB   2.50    Actulizacion de Archivo de Control para manejo de
##                           Procesos
##  06/11/2012 CRF   2.51    Archivos RM para comercios (IPR 1087)
##  24/11/2012 DCB   2.51    Incorporacion de IPR 1087 al Cierre Automatico
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPLIQCIE"            # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=2.50                    # Ultima Version del Programa
dpFec="20120824"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]


## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros de Ejecucion
################################################################################

pFecAbo="$1"                  # Fecha de Abono
pFecSes="$2"                  # Fecha de Sesion
pCodHCierre="$3"              # Codigo de Hora de Cierre
pCodProc="$4"                 # Codigo de Proceso (T=Todos/01->99)
pOpcProc="$5"                 # Opcion de Proceso (N=Normal
                              #                    R=Reproceso
                              #                    RP=Reproceso Parcial
                              #                    RT=Reproceso Total)
pFlgBG="$6"                   # Flag de Proceso en Background


## Variables de Trabajo
################################################################################



################################################################################
## DECLARACION DE FUNCIONES
################################################################################

# f_msg | muestra mensaje en pantalla
# Parametros
#   pMsg    : mensaje a mostrar
#   pRegLOG : registra mensaje en el LOG del Proceso [S=Si(default)/N=No]
################################################################################
f_msg ()
{
pMsg="$1"
pRegLOG="$2"
if [ "${pMsg}" = "" ]; then
   echo
   if [ "${vpFileLOG}" != "" ]; then
      echo >> ${vpFileLOG}
   fi
else
   echo "${pMsg}"
   if [ "${vpFileLOG}" != "" ]; then
      if [ "${pRegLOG}" = "S" ] || [ "${pRegLOG}" = "" ]; then
         echo "${pMsg}" >> ${vpFileLOG}
      fi
   fi
fi
}


# f_fhmsg | muestra mensaje con la fecha y hora del sistema
# Parametros
#   pMsg    : mensaje a mostrar
#   pFlgFH  : muestra fecha y hora [S=Si(default)/N=No]
#   pRegLOG : registra mensaje en el LOG del Proceso [S=Si(default)/N=No]
################################################################################
f_fhmsg ()
{
pMsg="$1"
pFlgFH="$2"
pRegLOG="$3"
if [ "$pMsg" = "" ]; then
   f_msg
else
   if [ "$pFlgFH" = "S" ] || [ "$pFlgFH" = "" ]; then
      pMsg="`date '+%H:%M:%S'` > ${pMsg}"
   else
      pMsg="         > ${pMsg}"
   fi
   f_msg "${pMsg}" ${pRegLOG}
fi
}


# f_msgtit | muestra mensaje de titulo
# Parametros
#   pTipo : tipo de mensaje de titulo [I=Inicio/F=Fin OK/E=Fin Error]
################################################################################
f_msgtit ()
{
pTipo="$1"
if [ "${dpDesc}" = "" ]; then
   vMsg="${dpNom}"
else
   vMsg="${dpDesc}"
fi
if [ "${pTipo}" = "I" ]; then
   vMsg="INICIO | ${vMsg}"
elif [ "${pTipo}" = "F" ]; then
     vMsg="FIN OK | ${vMsg}"
else
   vMsg="FIN ERROR | ${vMsg}"
fi
vMsg="\n\
********************************************************** [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]
 ${vMsg}\n\
********************************************************************************
\n\
"
f_msg "${vMsg}" S

if [ "${pTipo}" = "E" ]; then
   if [ "$pFlgBG" = "S" ]; then
################################################################################
# Proyecto Automatizacion: Creacion de Archivo de Control si la salida NO es   #
#  exitosa                                                                     #
# DCB                                                                          #
################################################################################
      vEstProc="E"
      f_admCTL W
################################################################################
# Fin Proyecto Automatizacion: Creacion de Archivo de Control si la salida NO  #
# es exitosa                                                                   #
# DCB                                                                          #
################################################################################
      echo " --> PRESIONE [CTRL+C] PARA REGRESAR"
      echo
   fi
   exit 1;
elif [ "${pTipo}" = "F" ]; then
   if [ "$pFlgBG" = "S" ]; then
################################################################################
# IPR 1039: Creacion de Archivo de Control si la salida es exitosa             #
# DCB                                                                          #
################################################################################
      vEstProc="F"
      f_admCTL W
################################################################################
# Fin IPR 1039: Creacion de Archivo de Control si la salida es exitosa         #
# DCB                                                                          #
################################################################################
      echo " --> PRESIONE [CTRL+C] PARA REGRESAR"
      echo
   fi
   exit 0;
fi
}


# f_parametros | muestra los parametros de ejecucion
################################################################################
f_parametros ()
{
f_fechora ${dpFec}
echo "
--------------------------------------------------------------------------------
${dpNom} - Parametros de Ejecucion

Parametro 1 (obligatorio) : Fecha de Abono [Formato=YYYYMMDD]
Parametro 2 (obligatorio) : Fecha de Sesion [Formato=YYYYMMDD]
Parametro 3 (obligatorio) : Codigo de Hora de Cierre [1=21:00/2=02:00]
Parametro 4 (obligatorio) : Codigo de Proceso [T=Todos/01->99]
Parametro 5 (obligatorio) : Opcion de Proceso [N=Normal
                                               R=Reproceso
                                               RP=Reproceso Parcial
                                               RT=Reproceso Total]
Parametro 6 (opcional)    : Flag de Proceso en Background [S=Si/N=No(default)]

--------------------------------------------------------------------------------
Programa: ${dpNom} | Version: ${dpVer} | Modificacion: ${vpValRet}
" | more
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
f_msgtit E
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


# f_fechora | cambia el formato de la fecha y hora
#             YYYYMMDD > DD/MM/YYYY
#             HHMMSS > HH:MM:SS
#             YYYYMMDDHHMMSS > DD/MM/YYYY HH:MM:SS
# Parametros
#   pFH : fecha/hora
################################################################################
f_fechora ()
{
pFH="$1"
vLong=`echo ${pFH} | awk '{print length($0)}'`
case ${vLong} in
     8)  # Fecha
         vDia=`echo $pFH | awk '{print substr($0,7,2)}'`
         vMes=`echo $pFH | awk '{print substr($0,5,2)}'`
         vAno=`echo $pFH | awk '{print substr($0,1,4)}'`
         vpValRet="${vDia}/${vMes}/${vAno}";;
     6)  # Hora
         vHra=`echo $pFH | awk '{print substr($0,1,2)}'`
         vMin=`echo $pFH | awk '{print substr($0,3,2)}'`
         vSeg=`echo $pFH | awk '{print substr($0,5,2)}'`
         vpValRet="${vHra}:${vMin}:${vSeg}";;
     14) # Fecha y Hora
         vDia=`echo $pFH | awk '{print substr($0,7,2)}'`
         vMes=`echo $pFH | awk '{print substr($0,5,2)}'`
         vAno=`echo $pFH | awk '{print substr($0,1,4)}'`
         vHra=`echo $pFH | awk '{print substr($0,9,2)}'`
         vMin=`echo $pFH | awk '{print substr($0,11,2)}'`
         vSeg=`echo $pFH | awk '{print substr($0,13,2)}'`
         vpValRet="${vDia}/${vMes}/${vAno} ${vHra}:${vMin}:${vSeg}";;
esac
}


# f_admCTL () | administra el Archivo de Control (lee/escribe)
# Parametros
#   pOpcion   : R=lee/W=escribe
################################################################################
f_admCTL ()
{

  # Estructura del Archivo de Control
  # [01-08] Fecha de Abono (AAAAMMDD)
  # [10-10] Codigo de Hora de Cierre (1=21:00 hrs/2=02:00 hrs)
  # [12-12] Estado del Cierre (0=Pendiente/P=En Proceso/F=Fin OK/E=Error)
  # [14-19] Codigo de Sub-Proceso (01 -> 99, Todos)
  # [20-21] Sub-Proceso que se esta ejecutando (01 -> 99)
  # [23-23] Estado del Sub-Proceso 01 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [25-25] Estado del Sub-Proceso 02 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [27-27] Estado del Sub-Proceso 03 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [29-29] Estado del Sub-Proceso 04 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [31-31] Estado del Sub-Proceso 05 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [33-33] Estado del Sub-Proceso 06 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [35-35] Estado del Sub-Proceso 07 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [37-37] Estado del Sub-Proceso 08 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [39-39] Estado del Sub-Proceso 09 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [41-41] Estado del Sub-Proceso 10 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [43-43] Estado del Sub-Proceso 11 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [45-45] Estado del Sub-Proceso 12 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [47-47] Estado del Sub-Proceso 13 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [49-49] Estado del Sub-Proceso 14 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [51-51] Estado del Sub-Proceso 15 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [53-53] Estado del Sub-Proceso 16 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [55-55] Estado del Sub-Proceso 17 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [57-57] Estado del Sub-Proceso 18 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [59-59] Estado del Sub-Proceso 19 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [61-61] Estado del Sub-Proceso 20 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [63-63] Estado del Sub-Proceso 21 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [65-65] Estado del Sub-Proceso 22 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [67-67] Estado del Sub-Proceso 23 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [69-69] Estado del Sub-Proceso 24 (P=En Proceso/F=Fin OK/E=Error/N=No Ejecutable)
  # [71-85] Fecha y Hora de Actualizacion de los Estados [AAAAMMDDHHMMSS]

  pOpcion="$1"  # R=Lee/W=Graba

  if [ "$pOpcion" = "R" ]; then
     if ! [ -f "$vFileCTL" ]; then
        echo "Creando Archivo CTL"
        # Crea el Archivo CTL
        vEstProc="0"
        vCodProc="  "
        vCodSubProc="  "
        vEstSubProc01="0"
        vEstSubProc02="0"
        vEstSubProc03="0"
        vEstSubProc04="0"
        vEstSubProc05="0"
        vEstSubProc06="0"
        vEstSubProc07="0"
        vEstSubProc08="0"
        vEstSubProc09="0"
        vEstSubProc10="0"
        vEstSubProc11="0"
        vEstSubProc12="0"
        vEstSubProc13="0"
        vEstSubProc14="0"
        vEstSubProc15="0"
        vEstSubProc16="0"
        vEstSubProc17="0"
        vEstSubProc18="0"
        vEstSubProc19="0"
        vEstSubProc20="0"
        vEstSubProc21="0"
        vEstSubProc22="0"
        vEstSubProc23="0"
        vEstSubProc24="0"
        echo "${pFecAbo}|${pCodHCierre}|${vEstProc}|${vCodProc}|${vCodSubProc}|${vEstSubProc01}|${vEstSubProc02}|${vEstSubProc03}|${vEstSubProc04}|${vEstSubProc05}|${vEstSubProc06}|${vEstSubProc07}|${vEstSubProc08}|${vEstSubProc09}|${vEstSubProc10}|${vEstSubProc11}|${vEstSubProc12}|${vEstSubProc13}|${vEstSubProc14}|${vEstSubProc15}|${vEstSubProc16}|${vEstSubProc17}|${vEstSubProc18}|${vEstSubProc19}|${vEstSubProc20}|${vEstSubProc21}|${vEstSubProc22}|${vEstSubProc23}|${vEstSubProc24}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
     else
        vEstProc=`awk '{print substr($0,12,1)}' $vFileCTL`
        vCodSubProc=`awk '{print substr($0,20,2)}' $vFileCTL`
        vEstSubProc01=`awk '{print substr($0,23,1)}' $vFileCTL`
        vEstSubProc02=`awk '{print substr($0,25,1)}' $vFileCTL`
        vEstSubProc03=`awk '{print substr($0,27,1)}' $vFileCTL`
        vEstSubProc04=`awk '{print substr($0,29,1)}' $vFileCTL`
        vEstSubProc05=`awk '{print substr($0,31,1)}' $vFileCTL`
        vEstSubProc06=`awk '{print substr($0,33,1)}' $vFileCTL`
        vEstSubProc07=`awk '{print substr($0,35,1)}' $vFileCTL`
        vEstSubProc08=`awk '{print substr($0,37,1)}' $vFileCTL`
        vEstSubProc09=`awk '{print substr($0,39,1)}' $vFileCTL`
        vEstSubProc10=`awk '{print substr($0,41,1)}' $vFileCTL`
        vEstSubProc11=`awk '{print substr($0,43,1)}' $vFileCTL`
        vEstSubProc12=`awk '{print substr($0,45,1)}' $vFileCTL`
        vEstSubProc13=`awk '{print substr($0,47,1)}' $vFileCTL`
        vEstSubProc14=`awk '{print substr($0,49,1)}' $vFileCTL`
        vEstSubProc15=`awk '{print substr($0,51,1)}' $vFileCTL`
        vEstSubProc16=`awk '{print substr($0,53,1)}' $vFileCTL`
        vEstSubProc17=`awk '{print substr($0,55,1)}' $vFileCTL`
        vEstSubProc18=`awk '{print substr($0,57,1)}' $vFileCTL`
        vEstSubProc19=`awk '{print substr($0,59,1)}' $vFileCTL`
        vEstSubProc20=`awk '{print substr($0,61,1)}' $vFileCTL`
        vEstSubProc21=`awk '{print substr($0,63,1)}' $vFileCTL`
        vEstSubProc22=`awk '{print substr($0,65,1)}' $vFileCTL`
        vEstSubProc23=`awk '{print substr($0,67,1)}' $vFileCTL`
        vEstSubProc24=`awk '{print substr($0,69,1)}' $vFileCTL`
     fi
  else
        echo "${pFecAbo}|${pCodHCierre}|${vEstProc}|${vCodProc}|${vCodSubProc}|${vEstSubProc01}|${vEstSubProc02}|${vEstSubProc03}|${vEstSubProc04}|${vEstSubProc05}|${vEstSubProc06}|${vEstSubProc07}|${vEstSubProc08}|${vEstSubProc09}|${vEstSubProc10}|${vEstSubProc11}|${vEstSubProc12}|${vEstSubProc13}|${vEstSubProc14}|${vEstSubProc15}|${vEstSubProc16}|${vEstSubProc17}|${vEstSubProc18}|${vEstSubProc19}|${vEstSubProc20}|${vEstSubProc21}|${vEstSubProc22}|${vEstSubProc23}|${vEstSubProc24}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
  fi

}

# f_ftp () | transferencia FTP
################################################################################
f_ftp ()
{

pDirOri="$1"
pDirDest="$2"
pFile="$3"
pTipoTransf="$4"

vFileParFTP="${DIRTMP}/${dpNom}_${vFHsys}.PAR.FTP"

if [ "$pTipoTransf" = "" ]; then
   pTipoTransf="ascii"
else
   if [ "$pTipoTransf" = "B" ]; then
      pTipoTransf="bin"
   else
      pTipoTransf="ascii"
   fi
fi

cd $pDirOri

touch ${pFile}.FLG

vCmdFTP="\
        verbose                              \n\
        open ${FTP_HOSTXCOM}                 \n\
        user ${FTP_USERXCOM}                 \n\
        prompt                               \n\
        ${pTipoTransf}                       \n\
        cd ${pDirDest}                       \n\
        put ${pFile} ${pFile}.ftp            \n\
        rename ${pFile}.ftp ${pFile}         \n\
        put ${pFile}.FLG ${pFile}.FLG.ftp    \n\
        rename ${pFile}.FLG.ftp ${pFile}.FLG \n\
        bye                                  \n\
       "

# echo "$vCmdFTP"
f_fhmsg "Transfiriendo ${pFile} al Servidor SUN 4200..."
echo "$vCmdFTP" | ftp -n > $vFileParFTP

# Verificacion del FTP
grep "550 ${pFile}:" $vFileParFTP >/dev/null
vpValRetpfilet="$?"
grep "550 ${pFile}.FLG:" $vFileParFTP >/dev/null
vpValRetpfilef="$?"
grep "226 Transfer complete." $vFileParFTP >/dev/null
vpValRet="$?"

if [ "$vpValRet" = "0" ] && [ "$vpValRetpfilet" = "1" ] && [ "$vpValRetpfilef" = "1" ]; then
   rm -f $vFileParFTP
   f_fhmsg "Archivo ${pFile} Transferido."
else
   echo
   cat $vFileParFTP
   echo
   echo >> $vpFileLOG
   cat $vFileParFTP >> $vpFileLOG
   echo >> $vpFileLOG
   vpValRet="1"
   echo
   echo >> $vpFileLOG
   rm -f ${pFile}.FLG
   f_fhmsg "Archivo: ${pDirOri}/${pFile}"
   f_fhmsg "Archivo NO Transferido. Revisar e Informar."
fi

}

################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

## Validacion de Parametros
################################################################################

# Menu de parametros
if [ $# -eq 0 ]; then
   f_parametros;
   exit 0;
fi

# Parametros obligatorios (4)
if [ $# -lt 4 ]; then
   f_parametros;
   exit 1;
fi

# Codigo de Hora de Cierre
case "$pCodHCierre" in
  1) vHCierre="21:00";;
  2) vHCierre="02:00";;
  *) echo
     f_fhmsg "ERROR | Codigo de Hora de Cierre Incorrecto" S N
     f_parametros;
     exit 1;
esac

# Codigo de Proceso
if [ "${pCodProc}" = "T" ]; then
   vCodProc="TODOS"
elif [ "${pCodProc}" = "01" ]; then
   vCodProc="Resumen de Movimientos (Terminales)"
elif [ "${pCodProc}" = "02" ]; then
   vCodProc="Resumen de Liquidacion"
elif [ "${pCodProc}" = "03" ]; then
   vCodProc="Interfaz para Comercios en Linea"
elif [ "${pCodProc}" = "04" ]; then
   vCodProc="Carga de Conformidad de Visita"
elif [ "${pCodProc}" = "05" ]; then
   vCodProc="Carga de Estadisticas"
elif [ "${pCodProc}" = "06" ]; then
   vCodProc="Generacion de Lote Adquirente"
elif [ "${pCodProc}" = "07" ]; then
   vCodProc="Cambio de Adquirencia (CEL)"
elif [ "${pCodProc}" = "08" ]; then
   vCodProc="Reportes de Remesa y Liquidacion Sodexho"
elif [ "${pCodProc}" = "09" ]; then
   vCodProc="Carga de Resumen de Ventas"
elif [ "${pCodProc}" = "10" ]; then
   vCodProc="Carga de Reportes de Facturacion"
elif [ "${pCodProc}" = "11" ]; then
   vCodProc="Carga de Reportes de Facturacion Platco"
elif [ "${pCodProc}" = "12" ]; then
   vCodProc="Generacion de Archivos Casa Matriz"
elif [ "${pCodProc}" = "13" ]; then
   vCodProc="Actualizacion de Tasas IVA e ISLR"
elif [ "${pCodProc}" = "14" ]; then
   vCodProc="Generacion de Reportes de ISLR"
elif [ "${pCodProc}" = "15" ]; then
   vCodProc="Actualizar Transacciones Premiadas con Reverso"
else
   f_fhmsg "ERROR | Codigo de Proceso (${pCodProc}) No Definido" S N
   f_parametros;
   exit 1;
fi

# Opcion de Reproceso
if [ "${pOpcProc}" = "N" ]; then
   vOpcProcNR="N"
   vOpcProcNS="N"
else
   vOpcProcNR="R"
   vOpcProcNS="S"
fi


## Descripcion del Programa
################################################################################
dpDesc="Cierre de Liquidacion"


## Archivo LOG
################################################################################

vpFileLOG="${DIRLOG}/SGCPLIQCIE${pFecAbo}.${pCodHCierre}.LOG"
echo > $vpFileLOG

################################################################################
# IPR 1039: Definicion de Archivo de Control                                   #
# DCB                                                                          #
################################################################################

## Archivo de Control
################################################################################

vFileCTL="${DIRDAT}/SGCPCIE${pFecAbo}.${pCodHCierre}.CTL"

if [ "${pOpcProc}" != "N" ]
then
	rm -f $vFileCTL > /dev/null 2>&1
fi


################################################################################
# FIN IPR 1039: Definicion de Archivo de Control                               #
# DCB                                                                          #
################################################################################

################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

f_admCTL R
f_msgtit I

f_fechora ${pFecAbo}
f_msg "            Fecha de Abono : ${vpValRet}"
f_fechora ${pFecSes}
f_msg "           Fecha de Sesion : ${vpValRet}"
f_msg "            Hora de Cierre : ${vHCierre} hrs."
f_msg "                   Proceso : ${pCodProc} - ${vCodProc}"
if [ "${pOpcProc}" = "N" ]; then
   f_msg "                 Reproceso : NO"
else
   f_msg "                 Reproceso : SI"
fi


## Proceso 13 : Actualizacion de Tasas IVA e ISLR
################################################################################
if [ "${pCodProc}" = "T" ]; then
################################################################################
# Proyecto Automatizacion: Creacion de Archivo de Control indicando que se     #
# esta procesando el Cierre, indicando el Numero de Sub-Proceso                #
# DCB                                                                          #
################################################################################
      vCodProc="TODOS"
      vEstProc="P"
      vCodSubProc="01"
      vEstSubProc01="P"
      f_admCTL W
#exit
################################################################################
# Fin Proyecto Automatizacion: Creacion de Archivo de Control indicando que se #
# esta procesando el Cierre indicando el Numero de Sub-Proceso                 #
################################################################################



      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: ACTUALIZACIONES PENDIENTES DE LA LIQUIDACION"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

     f_fhmsg "Ejecutando Proceso en Base de Datos..."
     vRet=`ORAExec.sh "exec :rC:=PQPLIQ.ActPendienteLiq(TO_DATE('$pFecSes','YYYYMMDD'),TO_DATE('$pFecAbo','YYYYMMDD'),'$pCodHCierre');" $DB`
     f_vrfvalret "$?" "Error al Ejecutar PQPLIQ.ActPendienteLiq (ErrSQL=$?)"
     vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
     if [ "$vEst" != "0" ]; then
        vRet=`echo "$vRet" | awk '{print substr($0,1)}'`
        f_fhmsg "$vRet"
################################################################################
# Proyecto Automatizacion: Actualizacion de Archivo de Control                 #
# Indicando que el Subproceso Termino en Error                                 #
# DCB                                                                          #
################################################################################
      vEstProc="P"
      vCodSubProc="01"
      vEstSubProc01="E"
      f_admCTL W
################################################################################
# Fin Proyecto Automatizacion: Actualizacion de Archivo de Control             #
# Indicando que el Subproceso Termino en Error                                 #
################################################################################
     else
        f_fhmsg "Fin OK."
################################################################################
# Proyecto Automatizacion: Actualizacion de Archivo de Control                 #
# Indicando que el Subproceso Termino Correctamente                            #
# DCB                                                                          #
################################################################################
      vEstProc="P"
      vCodSubProc="01"
      vEstSubProc01="F"
      f_admCTL W
################################################################################
# Fin Proyecto Automatizacion: Actualizacion de Archivo de Control             #
# Indicando que el Subproceso Termino Correctamente                            #
################################################################################
     fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: ACTUALIZACIONES PENDIENTES DE LA LIQUIDACION"
      f_msg "--------------------------------------------------------------------------------" S


fi # Proceso 13

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "13" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre

      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: ACTUALIZACION DE TASAS IVA E ISLR"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="02"
      vEstSubProc02="P"
      f_admCTL W

      SGCPTASAS.sh BM ${pFecAbo}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="02"
         vEstSubProc02="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="02"
         vEstSubProc02="E"
         f_admCTL W
      fi
      vEstProc="P"
      vCodSubProc="03"
      vEstSubProc03="P"
      f_admCTL W

      SGCPTASAS.sh BP ${pFecAbo}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="03"
         vEstSubProc03="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="03"
         vEstSubProc03="E"
         f_admCTL W
      fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: ACTUALIZACION DE TASAS IVA E ISLR"
      f_msg "--------------------------------------------------------------------------------" S
   else
      vEstProc="P"
      vEstSubProc02="N"
      vEstSubProc03="N"
      f_admCTL W
   fi

fi # Proceso 13


## Proceso 14 : Generacion de Reportes de ISLR
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "14" ]; then
   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre
      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: GENERACION DE Reportes de ISLR"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="04"
      vEstSubProc04="P"
      f_admCTL W

#      f_msg "Estado SubProceso02= $vEstSubProc02"
      if [ "$vEstSubProc02" = "F" ]
      then
         SGCPISLR.sh BM ${pFecAbo}
         vSubProcStatus=$?
      else
         tput setf 8
         f_msg "--------------------------------------------------------------------------------" S
         f_msg "Error: El Proceso de Generacion de Tasas para el Adquiriente Banco Mercantil Fallo" S
         f_msg "No se Generara el Reporte de ISLR para el Adquiriente Banco Mercantil" S
         f_msg "--------------------------------------------------------------------------------" S
         tput setf 7
         vSubprocStatus=1
      fi

      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="04"
         vEstSubProc04="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="04"
         vEstSubProc04="E"
         f_admCTL W
      fi

      vEstProc="P"
      vCodSubProc="05"
      vEstSubProc05="P"
      f_admCTL W

#      f_msg "Estado SubProceso03= $vEstSubProc03"
      if [ "$vEstSubProc03" = "F" ]
      then
         SGCPISLR.sh BP ${pFecAbo}
         vSubProcStatus=$?
      else
         tput setf 8
         f_msg "--------------------------------------------------------------------------------" S
         f_msg "Error: El Proceso de Generacion de Tasas para el Adquiriente Banco Provincial Fallo" S
         f_msg "No se Generara el Reporte de ISLR para el Adquiriente Banco Provincial" S
         f_msg "--------------------------------------------------------------------------------" S
         tput setf 7
         vSubprocStatus=1
      fi


      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="05"
         vEstSubProc05="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="05"
         vEstSubProc05="E"
         f_admCTL W
      fi
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: GENERACION DE Reportes ISLR"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc04="N"
      vEstSubProc05="N"
      f_admCTL W
   fi

fi # Proceso 14

## Proceso 06 : Generacion de Lote Adquirente
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "06" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre

      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: GENERACION DE LOTE ADQUIRENTE"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="06"
      vEstSubProc06="P"
      f_admCTL W

      SGCGenLoteAdq.sh ${pFecSes}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="06"
         vEstSubProc06="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="06"
         vEstSubProc06="E"
         f_admCTL W
      fi
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: GENERACION DE LOTE ADQUIRENTE"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc06="N"
      f_admCTL W
   fi

fi # Proceso 06

## Proceso 08 : Reportes de Remesa y Liquidacion Sodexho
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "08" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre

      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: REPORTES DE REMESA Y LIQUIDACION SODEXHO"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      # Archivos de Salida - Banco Provincial
      vFileSDX_LQ="${DIROUT}/SDXLQ0108${pFecAbo}.DAT"
      vFileSDX_RM="${DIROUT}/SDXRM0108${pFecAbo}.DAT"
      vFileSDX_RMCOM="${DIROUT}/SDXRM0108J0000202001${pFecAbo}.DAT"
      vDirXCOM="bp_filein"

      vEstProc="P"
      vCodSubProc="07"
      vEstSubProc07="P"
      f_admCTL W

      # Generando Reporte de Liquidacion de Sodexho
      f_fhmsg "Generando Reporte de Liquidacion de Sodexho..."
      vRet=`ORAExec.sh "exec :rC:=PQINTERFACESODEXHO.f_mainReporteLiquidacion(TO_DATE('$pFecAbo','YYYYMMDD'));" $DB`
      f_vrfvalret "$?" "Error al Ejecutar PQINTERFACESODEXHO.f_mainReporteLiquidacion"
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         # Transferencia de Archivo de Liquidacion de Sodexho
         f_ftp `dirname ${vFileSDX_LQ}` ${vDirXCOM} `basename ${vFileSDX_LQ}`
         # Fin OK
	 if [ "$vpValRet" != "0" ]
         then
            vEstProc="P"
            vCodSubProc="07"
            vEstSubProc07="E"
            f_admCTL W
         else
            vEstProc="P"
            vCodSubProc="07"
            vEstSubProc07="F"
            f_admCTL W
         fi
         f_fhmsg "Resultado del Reporte de Liquidacion: FINALIZADO CORRECTAMENTE"
      else
         vEstProc="P"
         vCodSubProc="07"
         vEstSubProc07="E"
         f_admCTL W
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         f_fhmsg "${vRet}"
      fi

      # Generando Reporte de Remesa de Sodexho
      vEstProc="P"
      vCodSubProc="08"
      vEstSubProc08="P"
      f_admCTL W
      f_fhmsg "Generando Reporte de Remesa de Sodexho..."
      vRet=`ORAExec.sh "exec :rC:=PQINTERFACESODEXHO.f_mainReporteRemesa(TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
      f_vrfvalret "$?" "Error al Ejecutar PQINTERFACESODEXHO.f_mainReporteRemesa"
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         # Transferencia de Archivo de Remesa de Sodexho
         f_ftp `dirname ${vFileSDX_RM}` ${vDirXCOM} `basename ${vFileSDX_RM}`
         # Fin OK
         if [ "$vpValRet" != "0" ]
         then
            vEstProc="P"
            vCodSubProc="08"
            vEstSubProc08="E"
            f_admCTL W
         else
            vEstProc="P"
            vCodSubProc="08"
            vEstSubProc08="F"
            f_admCTL W
         fi
         f_fhmsg "Resultado del Reporte de Remesa: FINALIZADO CORRECTAMENTE"
      else
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         vEstProc="P"
         vCodSubProc="08"
         vEstSubProc08="E"
         f_admCTL W
         f_fhmsg "${vRet}"
      fi

      # crosadof
      # Generando Reporte de remesas para comercios que lo soliciten...
      # IPR 1087 - > Reporte de remesas para FarmaTodo (06/11/2012)
      vEstProc="P"
      vCodSubProc="09"
      vEstSubProc09="P"
      f_admCTL W

      f_fhmsg "Generando Reporte de Remesa de Sodexo para comercios..."
      vRet=`ORAExec.sh "exec :rC:=PQINTERFACESODEXHO.sp_gen_rpt_rem_x_com(TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
      f_vrfvalret "$?" "Error al Ejecutar PQINTERFACESODEXHO.sp_gen_rpt_rem_x_com"
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         # Transferencia de Archivo de Remesa de Sodexo
         f_ftp `dirname ${vFileSDX_RMCOM}` ${vDirXCOM} `basename ${vFileSDX_RMCOM}`
         # Fin OK
         if [ "$vpValRet" != "0" ]
         then
            vEstProc="P"
            vCodSubProc="09"
            vEstSubProc09="E"
            f_admCTL W
         else
            vEstProc="P"
            vCodSubProc="09"
            vEstSubProc09="F"
            f_admCTL W
         fi
         f_fhmsg "Resultado del Reporte de Remesas para comercios: FINALIZADO CORRECTAMENTE"
      else
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         vEstProc="P"
         vCodSubProc="09"
         vEstSubProc09="E"
         f_admCTL W
         f_fhmsg "${vRet}"
      fi
      # fin crosadof


      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: REPORTES DE REMESA Y LIQUIDACION SODEXHO"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc07="N"
      vEstSubProc08="N"
      vEstSubProc09="N"
      f_admCTL W
   fi

fi # Proceso 08

## Proceso 12 : Generacion de Archivos Casa Matriz
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "12" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre

      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: GENERACION DE ARCHIVOS CASA MATRIZ"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="10"
      vEstSubProc10="P"
      f_admCTL W

      SGCPMATRIZ.sh ${pFecSes}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         sync
         vEstProc="P"
         vCodSubProc="10"
         vEstSubProc10="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="10"
         vEstSubProc10="E"
         f_admCTL W
      fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: GENERACION DE ARCHIVOS CASA MATRIZ"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc10="N"
      f_admCTL W
   fi

fi # Proceso 12


## Proceso 01 : Generacion de Archivo de Movimientos
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "01" ]; then

      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: RESUMEN DE MOVIMIENTOS (TERMINALES)"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="11"
      vEstSubProc11="P"
      f_admCTL W

   # Banco Mercantil
   f_fhmsg "Ejecutando Resumen de Terminales (Banco Mercantil)..."
   vRet=`ORAExec.sh "exec :rC:=SF_INSRMCTERM('BM',TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre','$vOpcProcNR');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar SF_INSRMCTERM (ErrSQL=$?)"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      # Banco Provincial
      f_fhmsg "Ejecutando Resumen de Terminales (Banco Provincial)..."
      vRet=`ORAExec.sh "exec :rC:=SF_INSRMCTERM('BP',TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre','$vOpcProcNR');" $DB`
      f_vrfvalret "$?" "Error al Ejecutar SF_INSRMCTERM (ErrSQL=$?)"
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         vEstProc="P"
         vCodSubProc="11"
         vEstSubProc11="F"
         f_admCTL W
         f_fhmsg "Fin OK."
      else
         vEstProc="P"
         vCodSubProc="11"
         vEstSubProc11="E"
         f_admCTL W
         vRet=`echo "$vRet" | awk '{print substr($0,1)}'`
         f_fhmsg "$vRet"
      fi
   else
         vEstProc="P"
         vCodSubProc="11"
         vEstSubProc11="E"
         f_admCTL W
      vRet=`echo "$vRet" | awk '{print substr($0,1)}'`
      f_fhmsg "$vRet"
   fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: RESUMEN DE MOVIMIENTOS (TERMINALES)"
      f_msg "--------------------------------------------------------------------------------" S

fi # Proceso 01


## Proceso 04 : Carga de Conformidad de Visita
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "04" ]; then

      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: CARGA DE CONFORMIDAD DE VISITA"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="12"
      vEstSubProc12="P"
      f_admCTL W

   f_fhmsg "Ejecutando Proceso en Base de Datos..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLM.InsMNCCONFV(TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLM.InsMNCCONFV (ErrSQL=$?)"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" != "0" ]; then
      vEstProc="P"
      vCodSubProc="12"
      vEstSubProc12="E"
      f_admCTL W
      vRet=`echo "$vRet" | awk '{print substr($0,1)}'`
      f_fhmsg "$vRet"
   else
      vEstProc="P"
      vCodSubProc="12"
      vEstSubProc12="F"
      f_admCTL W
      f_fhmsg "Fin OK."
   fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: CARGA DE CONFORMIDAD DE VISITA"
      f_msg "--------------------------------------------------------------------------------" S

fi # Proceso 04


## Proceso 05 : Carga de Estadisticas
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "05" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre
      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: CARGA DE ESTADISTICAS"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="13"
      vEstSubProc13="P"
      f_admCTL W

      SGCPESTAD.sh BM ${vOpcProcNR} ${pFecSes}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="13"
         vEstSubProc13="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="13"
         vEstSubProc13="E"
         f_admCTL W
      fi

      vEstProc="P"
      vCodSubProc="14"
      vEstSubProc14="P"
      f_admCTL W

      SGCPESTAD.sh BP ${vOpcProcNR} ${pFecSes}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="14"
         vEstSubProc14="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="14"
         vEstSubProc14="E"
         f_admCTL W
      fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: CARGA DE ESTADISTICAS"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc13="N"
      vEstSubProc14="N"
      f_admCTL W
   fi

fi # Proceso 05


## Proceso 10 : Carga de Reportes de Facturacion
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "10" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre
      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: CARGA DE REPORTES DE FACTURACION"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="15"
      vEstSubProc15="P"
      f_admCTL W

      SGCPRFCA.sh BM ${vOpcProcNR} ${pFecSes}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="15"
         vEstSubProc15="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="15"
         vEstSubProc15="E"
         f_admCTL W
      fi

      vEstProc="P"
      vCodSubProc="16"
      vEstSubProc16="P"
      f_admCTL W

      SGCPRFCA.sh BP ${vOpcProcNR} ${pFecSes}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="16"
         vEstSubProc16="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="16"
         vEstSubProc16="E"
         f_admCTL W
      fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: CARGA DE REPORTES DE FACTURACION"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc15="N"
      vEstSubProc16="N"
      f_admCTL W
   fi

fi # Proceso 10


## Proceso 09 : Carga de Resumen de Ventas
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "09" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre
      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: CARGA DE RESUMEN DE VENTAS"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg


      vEstProc="P"
      vCodSubProc="17"
      vEstSubProc17="P"
      f_admCTL W

      f_fhmsg "Proceso Carga de Resumen de Ventas Banco Mercantil..."
      vRet=`ORAExec.sh "exec :rC:=PQINTERFACECEL.f_main_RMV('BM',TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
      f_vrfvalret "$?" "Error al Ejecutar PQINTERFACECEL.f_main_RMV(BM)"
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         vEstProc="P"
         vCodSubProc="17"
         vEstSubProc17="F"
         f_admCTL W
         f_fhmsg "Resultado de RMV Banco Mercantil: FINALIZADO CORRECTAMENTE"
      else
         vEstProc="P"
         vCodSubProc="17"
         vEstSubProc17="E"
         f_admCTL W
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         f_fhmsg "${vRet}"
      fi

      vEstProc="P"
      vCodSubProc="18"
      vEstSubProc18="P"
      f_admCTL W

      f_fhmsg "Proceso Carga de Resumen de Ventas Banco Provincial..."
      vRet=`ORAExec.sh "exec :rC:=PQINTERFACECEL.f_main_RMV('BP',TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
      f_vrfvalret "$?" "Error al Ejecutar PQINTERFACECEL.f_main_RMV(BP)"
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         vEstProc="P"
         vCodSubProc="18"
         vEstSubProc18="F"
         f_admCTL W
         f_fhmsg "Resultado de RMV Banco Provincial: FINALIZADO CORRECTAMENTE"
      else
         vEstProc="P"
         vCodSubProc="18"
         vEstSubProc18="E"
         f_admCTL W
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         f_fhmsg "${vRet}"
      fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: CARGA DE RESUMEN DE VENTAS"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc17="N"
      vEstSubProc18="N"
      f_admCTL W
   fi

fi # Proceso 09


## Proceso 02 : Resumen de Liquidacion (RESLIQ)
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "02" ]; then

      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: RESUMEN DE LIQUIDACION (RESLIQ)"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

   vEstProc="P"
   vCodSubProc="19"
   vEstSubProc19="P"
   f_admCTL W

   f_fhmsg "Procesando Resumen de Liquidacion (Banco Mercantil)..."
   SGCRESLIQ.sh BM ${pFecAbo} $pCodHCierre $vOpcProcNR T 1>$DIRTMP/SGCRESLIQ.out 2>$DIRTMP/SGCRESLIQ.err
   vRet="$?"
   if [ "$vRet" = "0" ]; then
      f_fhmsg "Procesando Resumen de Liquidacion (Banco Provincial)..."
      SGCRESLIQ.sh BP ${pFecAbo} $pCodHCierre $vOpcProcNR T 1>>$DIRTMP/SGCRESLIQ.out 2>>$DIRTMP/SGCRESLIQ.err
      vRet="$?"
      if [ "$vRet" = "0" ]; then
         f_fhmsg "Procesando Resumen de Liquidacion (Interfaz ICEL)..."
         SGCRESLIQicel.sh ${pFecAbo} 1>>${vpFileLOG} 2>>${vpFileLOG}
         vRet="$?"
         if [ "$vRet" = "0" ]; then
           vEstProc="P"
           vCodSubProc="19"
           vEstSubProc19="F"
           f_admCTL W
            f_fhmsg "Fin OK."
         fi
      else
           vEstProc="P"
           vCodSubProc="19"
           vEstSubProc19="E"
           f_admCTL W
      fi
   else
           vEstProc="P"
           vCodSubProc="19"
           vEstSubProc19="E"
           f_admCTL W
   fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: RESUMEN DE LIQUIDACION (RESLIQ)"
      f_msg "--------------------------------------------------------------------------------" S

fi # Proceso 02


## Proceso 03 : Interfaz para Comercios en Linea
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "03" ]; then

 if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre
      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: INTERFAZ PARA COMERCIOS EN LINEA (ICEL)"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

   vEstProc="P"
   vCodSubProc="20"
   vEstSubProc20="P"
   f_admCTL W
   f_fhmsg "Procesando Interfaz para Comercios en Linea..."
     #SGCICEL.sh $pFecAbo 1>>${vpFileLOG} 2>>${vpFileLOG}
     SGCPLIQcarga_cel.sh  ${pFecSes} ${pFecAbo} ${pOpcProc}
     vRet="$?"
   if [ "$vRet" = "0" ]; then
      vEstProc="P"
      vCodSubProc="20"
      vEstSubProc20="F"
      f_admCTL W
      f_fhmsg "Fin OK."
   else
      vEstProc="P"
      vCodSubProc="20"
      vEstSubProc20="E"
      f_admCTL W
      #f_fhmsg "Error al Generar Archivo de Datos. Avisar a Soporte."
	  f_fhmsg "Error en Proceso de Carga Comercio en Linea."
   fi

   #if [ "${COD_AMBIENTE}" != "DESA" ] && [ "${pCodHCierre}" = "2" ]; then
      #f_fhmsg "Ejecutando Proceso en Comercios en Linea (Background)..."
      #nohup ORAExec.sh "exec PKG_PCD.SGCPCD(TO_DATE('${pFecAbo}','YYYYMMDD'),'${vOpcProcNR}');" $DBCEL 1>>${vpFileLOG} 2>>${vpFileLOG} &
   #fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: INTERFAZ PARA COMERCIOS EN LINEA (ICEL)"
      f_msg "--------------------------------------------------------------------------------" S
   else
      vEstProc="P"
      vEstSubProc20="N"
      f_admCTL W
   fi
fi

# Proceso 03


## Proceso 07 : Cambio de Adquirencia (CEL)
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "07" ]; then

   if [ "${pCodHCierre}" = "1" ]; then  # Solo se ejecuta en el primer cierre
      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: CAMBIO DE ADQUIRENCIA (CEL)"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="21"
      vEstSubProc21="P"
      f_admCTL W

      vFlgProc="S"
      f_fhmsg "Ejecutando Proceso en Base de Datos..."
      vRet=`ORAExec.sh "exec :rC:=PKG_INTERFAZ_TERMINAL.cel_fp_interfaz_terminal (TO_DATE('$pFecAbo','YYYYMMDD'),'$vOpcProcNS');" $DBCEL`
      f_vrfvalret "$?" "Error al Ejecutar PKG_INTERFAZ_TERMINAL.cel_fp_interfaz_terminal (ErrSQL=$?)"
      echo $vRet
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      echo $vEst
      if [ "$vEst" != "0" ]
      then
         vEstProc="P"
         vCodSubProc="21"
         vEstSubProc21="E"
         f_admCTL W
         vFlgProc="N"
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         f_fhmsg "$vRet"
      fi

      if [ "$vFlgProc" = "S" ]; then
         stdGetFilesCOML
         vRet="$?"
         if [ "$vRet" != "0" ]; then
            vEstProc="P"
            vCodSubProc="21"
            vEstSubProc21="E"
            f_admCTL W
            vFlgProc="N"
         fi
      fi

      if [ "$vFlgProc" = "S" ]; then
         ADASEXEproc.sh MANUAL N
         vRet="$?"
         if [ "$vRet" != "0" ]
         then
            vEstProc="P"
            vCodSubProc="21"
            vEstSubProc21="E"
            f_admCTL W
            vFlgProc="N"
         fi
      fi

      # Agenda JOB
      if [ "$vFlgProc" = "S" ]; then
         typeset -i vHra vMin
         vFec=`getdate`
         vHra=`date '+%H'`
         vMin=`date '+%M'`
         vMin=vMin+${PCAMADQ_MINSJOB}
         if [ vMin -gt 59 ]; then
            vMin=vMin-60
            vHra=vHra+1
            if [ vHra -gt 23 ]; then
               vHra=vHra-24
               vFec=`getdate 1`
            fi
         fi
         vHraF=`printf "%02d" $vHra`
         vMinF=`printf "%02d" $vMin`
         f_fechora ${vFec}
         f_fhmsg "Ejecucion de Proceso Agendada: ${vpValRet} a las ${vHraF}:${vMinF} hrs."
         f_fechora ${pFecAbo}
         echo "
--------------------------------------------------------------------------------
# SGCPCAMADQ | Proceso de Cambio de Adquirencia (Parte II)
# Fecha de Abono: ${vpValRet}

SGCPCAMADQ.sh ${vOpcProcNR} ${pFecAbo}
--------------------------------------------------------------------------------
" >> ${DIRJOBS}/SGCJOB_${vFec}${vHraF}${vMinF}.sh

         vRet="$?"
         if [ "$vRet" != "0" ]
         then
            vEstProc="P"
            vCodSubProc="21"
            vEstSubProc21="E"
            f_admCTL W
         else
            vEstProc="P"
            vCodSubProc="21"
            vEstSubProc21="F"
            f_admCTL W
         fi
      fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: CAMBIO DE ADQUIRENCIA (CEL)"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc21="N"
      f_admCTL W
   fi

fi # Proceso 07


## Proceso 11 : Carga de Reportes de Facturacion Platco
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "11" ]; then

   if [ "${pCodHCierre}" = "2" ]; then  # Solo se ejecuta en el segundo cierre
      f_msg
      f_msg
      f_msg
      f_msg
      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "INI: CARGA DE REPORTES DE FACTURACION PLATCO"
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg "--------------------------------------------------------------------------------" S
      f_msg

      vEstProc="P"
      vCodSubProc="22"
      vEstSubProc22="P"
      f_admCTL W

      SGCPRTPLATCO.sh BM ${vOpcProcNR} ${pFecAbo}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="22"
         vEstSubProc22="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="22"
         vEstSubProc22="E"
         f_admCTL W
      fi

      vEstProc="P"
      vCodSubProc="23"
      vEstSubProc23="P"
      f_admCTL W

      SGCPRTPLATCO.sh BP ${vOpcProcNR} ${pFecAbo}

      vSubProcStatus=$?
      if [ "$vSubProcStatus" = "0" ]
      then
         vEstProc="P"
         vCodSubProc="23"
         vEstSubProc23="F"
         f_admCTL W
      else
         vEstProc="P"
         vCodSubProc="23"
         vEstSubProc23="E"
         f_admCTL W
      fi

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: CARGA DE REPORTES DE FACTURACION PLATCO"
      f_msg "--------------------------------------------------------------------------------" S

   else
      vEstProc="P"
      vEstSubProc22="N"
      vEstSubProc23="N"
      f_admCTL W
   fi

fi # Proceso 11


## Proceso 15 :  Actualizacion de Transacciones Premiadas con Reverso
################################################################################

if [ "${pCodProc}" = "T" ] || [ "${pCodProc}" = "15" ]; then

    f_msg
    f_msg
    f_msg
    f_msg
    f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
    f_msg "INI: Actualizacion de Transacciones Premiadas con Reverso"
    f_msg "--------------------------------------------------------------------------------" S
    f_msg "--------------------------------------------------------------------------------" S
    f_msg "--------------------------------------------------------------------------------" S
    f_msg "--------------------------------------------------------------------------------" S

    vEstProc="P"
    vCodSubProc="24"
    vEstSubProc24="P"
    f_admCTL W
    
    #echo "vOpcProcNR = $vOpcProcNR"
    if [ "${vOpcProcNR}" = "N" ]
    then
       SGCPREMIOTXSREVERSO.sh ${pFecSes} ${pCodHCierre} PN
    else
       SGCPREMIOTXSREVERSO.sh ${pFecSes} ${pCodHCierre} RT
    fi
    ARCHCTLTXTREV="${DIRDAT}/SGCPREMIOTXSREVERSO${pFecSes}.${pCodHCierre}.CTL"
    sync
#    cat ${DIRLOG}/SGCPREMIOTXSREVERSO${pFecSes}.${pCodHCierre}.LOG
    vEstPROCTXTREV=`awk '{print substr($0,14,1)}' $ARCHCTLTXTREV`
    #echo "vEstPROCTXTREV = $vEstPROCTXTREV"
    vEstProc="P"
    vCodSubProc="24"
    vEstSubProc24="${vEstPROCTXTREV}"
    f_admCTL W

      f_msg "---------------------------------------------------------- [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]" S
      f_msg "FIN: ACTUALIZACION DE TRANSACCIONES PREMIADAS CON REVERSO"
      f_msg "--------------------------------------------------------------------------------" S
fi # Proceso 15











f_admCTL R
vESTTOTAL=`echo "$vEstSubProc01:$vEstSubProc02:$vEstSubProc03:$vEstSubProc04:$vEstSubProc05:$vEstSubProc06:$vEstSubProc07:$vEstSubProc08:$vEstSubProc09:$vEstSubProc10:$vEstSubProc11:$vEstSubProc12:$vEstSubProc13:$vEstSubProc14:$vEstSubProc15:$vEstSubProc16:$vEstSubProc17:$vEstSubProc18:$vEstSubProc19:$vEstSubProc20:$vEstSubProc21:$vEstSubProc22:$vEstSubProc23:$vEstSubProc24"`

if [ "$vESTTOTAL" = "F:F:F:F:F:F:F:F:F:F:F:F:F:F:F:F:F:F:F:F:N:F:F:F" ] || [ "$vESTTOTAL" = "F:N:N:N:N:N:N:N:N:N:F:F:N:N:N:N:N:N:F:N:F:N:N:F" ]
then
	f_msgtit F
else
	f_msgtit E
fi



################################################################################
## FIN | PROCEDIMIENTO PRINCIPAL
################################################################################
