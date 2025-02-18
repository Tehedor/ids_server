#!/bin/bash

# --- Configuración ---
PUERTO=8085
ARCHIVO_IPS_PERMITIDAS="ips_permitidas.conf" # Descomentar si usas archivo externo
# IPS_PERMITIDAS=(
#     "127.0.0.1"    # localhost
#     "192.168.1.10" # Ejemplo IP local, ajusta a tus IPs permitidas aquí o usa archivo
# )
DIRECTORIO_SCRIPTS="./scripts"
SCRIPTS_A_EJECUTAR=(
    "script1.sh"
    "script2.sh"
)
ARCHIVO_LOG="/usr/local/share/ids_server/app/log_daemon.log" # Archivo de log opcional, comentar para desactivar logging
# ARCHIVO_LOG="log_daemon.log" # Archivo de log opcional, comentar para desactivar logging
DAEMON_PIDFILE="/var/run/ids_serverd.pid" # Archivo para guardar el PID del daemon

# --- Funciones ---

log_mensaje() {
    local mensaje="$(date '+%Y-%m-%d %H:%M:%S') - $*"
    if [ -n "$ARCHIVO_LOG" ]; then
        echo "$mensaje" >> "$ARCHIVO_LOG"
    fi
    echo "$mensaje" # También muestra en salida estándar
}

es_ip_permitida() {
    local ip_cliente=$1
    # --- Usar archivo de IPs permitidas (opcional) ---
    if [ -r "$ARCHIVO_IPS_PERMITIDAS" ]; then
        while IFS= read -r ip_permitida; do
            if [[ "$ip_cliente" == "$ip_permitida" ]] && [[ -n "$ip_permitida" ]] && [[ ! $ip_permitida =~ ^# ]]; then
                return 0 # IP permitida
            fi
        done < "$ARCHIVO_IPS_PERMITIDAS"
    fi
    # --- Usar array de IPs permitidas (configuración interna) ---
    # for ip_permitida in "${IPS_PERMITIDAS[@]}"; do
    #     if [[ "$ip_cliente" == "$ip_permitida" ]]; then
    #         return 0 # IP permitida
    #     fi
    # done
    return 1 # IP no permitida
}

ejecutar_scripts() {
    log_mensaje "Ejecutando scripts..."
    for script in "${SCRIPTS_A_EJECUTAR[@]}"; do
        script_completo="$DIRECTORIO_SCRIPTS/$script"
        if [ -x "$script_completo" ]; then
            log_mensaje "Ejecutando script: $script_completo"
            "$script_completo"
            if [ $? -ne 0 ]; then
                log_mensaje "Error al ejecutar script: $script_completo"
            else
                log_mensaje "Script $script_completo ejecutado correctamente"
            fi
        else
            log_mensaje "Error: Script no ejecutable o no encontrado: $script_completo"
        fi
    done
}

manejar_conexion() {
    local socket_cliente=$1
    local ip_cliente

    # Obtener IP del cliente usando nc
    ip_cliente=$(echo "$socket_cliente" | cut -d ' ' -f 5 | cut -d ':' -f 1)

    log_mensaje "Conexión entrante desde IP: $ip_cliente"

    if ! es_ip_permitida "$ip_cliente"; then
        log_mensaje "IP no permitida: $ip_cliente. Conexión rechazada."
        echo "HTTP/1.1 403 Forbidden\r\n\r\nAcceso denegado.\r\n" >&"$socket_cliente"
        close_socket "$socket_cliente"
        return 1
    fi

    read -r -u "$socket_cliente" peticion || { log_mensaje "Error al leer petición"; close_socket "$socket_cliente"; return 1; }

    # Extraer método HTTP (primer palabra de la petición)
    metodo_http=$(echo "$peticion" | awk '{print $1}')

    if [[ "$metodo_http" != "PUT" ]]; then
        log_mensaje "Método HTTP no permitido: $metodo_http. Se esperaba PUT."
        echo "HTTP/1.1 405 Method Not Allowed\r\n\r\nSe espera método PUT.\r\n" >&"$socket_cliente"
        close_socket "$socket_cliente"
        return 1
    fi

    log_mensaje "Petición PUT válida recibida desde IP permitida: $ip_cliente"
    ejecutar_scripts

    echo "HTTP/1.1 200 OK\r\n\r\nPetición PUT recibida y procesada.\r\n" >&"$socket_cliente"
    close_socket "$socket_cliente"
    return 0
}

close_socket() {
    local socket=$1
    exec {socket}<&-
}

daemonizar() {
    if [ -f "$DAEMON_PIDFILE" ]; then
        PID=$(cat "$DAEMON_PIDFILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            log_mensaje "Daemon ya está en ejecución con PID $PID. Saliendo."
            exit 1
        fi
        rm -f "$DAEMON_PIDFILE"
    fi

    # Daemonizar
    nohup "$0" --daemonizado "$@" > /dev/null 2>&1 &
    echo $! > "$DAEMON_PIDFILE"
    log_mensaje "Daemon iniciado en segundo plano, PID: $! (Guardado en $DAEMON_PIDFILE)"
    exit 0
}

# --- Main script ---

if [ "$1" == "--daemonizado" ]; then
    # Modo daemonizado (ejecución real del daemon)
    shift # Eliminar "--daemonizado" de los argumentos

    if [ -n "$ARCHIVO_LOG" ]; then
        exec >>"$ARCHIVO_LOG" 2>>"$ARCHIVO_LOG" # Redirigir stdout y stderr al archivo log
    fi

    log_mensaje "Daemon iniciado en puerto $PUERTO"

    # Crear socket de escucha con nc
    while true; do
        nc -l -p "$PUERTO" -k | (
            socket_cliente=$(cat <&3) # Leer el socket del cliente desde el descriptor 3
            exec 3<&- # Cerrar el descriptor 3 en el proceso hijo
            manejar_conexion "$socket_cliente"
        ) 3<&0 & # Redirigir la entrada estándar al descriptor 3 para nc y ejecutar en segundo plano
    done

else
    # Modo normal (se ejecuta la primera vez para daemonizar)
    daemonizar
fi

exit 0