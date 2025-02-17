#!/bin/bash

# --- Configuración ---
PUERTO=12345

echo "Servidor de sockets básico (sin nc) iniciado."
echo "Escuchando en el puerto ${PUERTO}..."

# Crear socket de escucha
exec 3<>/dev/tcp/localhost/$PUERTO
socket_escucha=3

while true; do
    # Aceptar conexión entrante
    exec 4<&3  # Duplicar el socket de escucha al FD 4
    socket_cliente=4

    echo "-------------------------------"
    echo "Conexión entrante recibida."

    # Leer datos del cliente (una línea)
    read -r -u "$socket_cliente" mensaje_cliente

    if [[ -n "$mensaje_cliente" ]]; then
        echo "Mensaje del cliente: \"${mensaje_cliente}\""

        # Respuesta del servidor
        respuesta_servidor="Servidor dice: Mensaje recibido: \"${mensaje_cliente}\""
        echo "Enviando respuesta al cliente: \"${respuesta_servidor}\""
        echo -e "$respuesta_servidor" >&"$socket_cliente" # Enviar respuesta por el socket

    else
        echo "Cliente cerró la conexión o no envió datos."
    fi

    # Cerrar socket del cliente
    exec {socket_cliente}<&-
done

echo "Servidor finalizado (esto no debería verse en funcionamiento normal)."

exit 0