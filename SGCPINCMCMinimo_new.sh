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
dFecProc=`getdate`            # Fecha Actual [Formato:AAAAMMDD]

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
--------------------------------------------------------------------------------
${dpNom} - Parametros de Ejecucion

Parametro 1 (obligatorio) : Fecha de Proceso [Formato=YYYYMMDD]
Parametro 2 (opcional) : Confirmación de Reproceso [S=Si]

--------------------------------------------------------------------------------
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

if [ "${pFecProc}" -ne "${dFecProc}" ]; then
 echo "La Fecha de Proceso no puede ser menor ni mayor a la fecha actual ${pFecProc}"   
else
 vFileLOG="${DIRLOG}/SGCPINCMCMinimo$dFecProc.log"
 #vFileLOGERR="${DIRLOG}/repcompBM$FechaREP.err"
 pEntAdq="BM"
 #pFecProc=$FechaREP
 vFileCTL="${DIRDAT}/SGCPINCMCMinimo${pEntAdq}.${pFecProc}.CTL"
 f_admCTL R
 vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
   if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" = "" ]; then
     tput setf 8
     echo "El valor de Monto Minimo para la fecha ${pFecProc} ya ha sido procesado"
     tput setf 7
     echo "Desea Reprocesar? (S=Si/N=No/<Enter>=No) => \c"
     read valRepro
     vOpcRepro = $valRepro
       if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" = "S" ] || [ "$vEstProc" != "F" ] ; then
         tput setf 8
         echo "Aqui termina de procesar la vaina "
         tput setf 7
         exit 0   
       else
          echo "aqui esta el final" 
       fi
   fi     
fi