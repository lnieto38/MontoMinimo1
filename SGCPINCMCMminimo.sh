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
##  11/01/2008 LDN   1.00    Codigo Inicial
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPINCMCMminimo"      # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=1.00                    # Ultima Version del Programa
dpFec="20200905"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]

## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


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
        vSubProc="00"
        echo "${pEntAdq}|${pFecProc}|${vEstProc}|${vSubProc}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
     else
        vEstProc=`awk '{print substr($0,16,1)}' $vFileCTL`
     fi
  else
     echo "${pEntAdq}|${pFecProc}|${vEstProc}|${vSubProc}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
  fi

}

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

vFileLOG="${DIRLOG}/SGCPINCMCMinimo$vpFH.log"
#vFileLOGERR="${DIRLOG}/repcompBM$FechaREP.err"
pEntAdq="BM"
#pFecProc=$FechaREP
vFileCTL="${DIRDAT}/SGCPINCMCMinimo${pEntAdq}.${pFecProc}.CTL"
f_admCTL R
vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
  if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" != "S" ]
  then
     tput setf 8
     echo "El valor de Monto Minimo para la fecha ${pFecProc} ya ha sido procesado"
     tput setf 7
     exit 0
  else
    tput setf 8
     echo "el valor de EstProc es {$vEstProc} distinto de F"
     tput setf 7
      echo "vamos a ver si esto funciona ;)"
      #ValFecha.sh ${pFecProc}               
      ERRSTATUS=$?
      vSubProc="00"
      if [ "$ERRSTATUS" = "0" ]
      then
         vEstProc="E"
      else
         vEstProc="F"
      fi
      f_admCTL W
      echo "FIN"
  fi
echo "Aqui continua en el caso que el valor es distinto de P"

