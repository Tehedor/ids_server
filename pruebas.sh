#!/bin/bash

# --- Configuración ---
PUERTO=8080

echo "Servidor PUT básico (sin nc) iniciado."
echo "Escuchando en el puerto ${PUERTO}..."

# Crear socket de escucha
exec 3<>/dev/tcp/0/$PUERTO
socket_escucha=3

if [ -z "$socket_escucha" ]; then # Comprobar si socket_escucha se creó correctamente
    echo "Error al crear socket de escucha (FD 3). Saliendo."
    exit 1
fi
echo "Socket de escucha (FD 3) creado correctamente."

while true; do
    # Aceptar conexión entrante
    exec 4<&3
    socket_cliente=4

    if [ -z "$socket_cliente" ]; then # Comprobar si socket_cliente se creó correctamente
        echo "Error al aceptar conexión (FD 4). Continuando al siguiente ciclo."
        continue # Volver al inicio del bucle para intentar aceptar otra conexión
    fi
    echo "Socket de cliente (FD 4) aceptado correctamente."


    # Leer la petición HTTP del cliente (solo la primera línea para simplificar)
    read -r -u "$socket_cliente" peticion_http

    if [ -z "$REPLY" ]; then # Comprobar si `read` tuvo éxito (REPLY se usa con -u para código de retorno de read)
        echo "Error al leer petición HTTP del cliente (FD 4). Conexión cerrada posiblemente."
        echo "Conexión cerrada por el cliente sin enviar petición."
    else
        # Extraer método HTTP (primera palabra de la petición)
        metodo_http=$(echo "$peticion_http" | awk '{print $1}')

        echo "-------------------------------"
        echo "Petición recibida."
        echo "Método HTTP recibido: \"${metodo_http}\""

        if [[ "$metodo_http" == "PUT" ]]; then
            echo "Petición PUT detectada."
            respuesta_http="HTTP/1.1 200 OK\r\n\r\nPetición PUT recibida.\r\n"
            echo -e "$respuesta_http" >&"$socket_cliente"
            echo "Respuesta 200 OK enviada."
        else
            echo "Método HTTP no es PUT. Se esperaba PUT."
            respuesta_http="HTTP/1.1 405 Method Not Allowed\r\n\r\nSe espera método PUT.\r\n"
            echo -e "$respuesta_http" >&"$socket_cliente"
            echo "Respuesta 405 Method Not Allowed enviada."
        fi
    fi

    # Cerrar socket del cliente
    exec {socket_cliente}<&-
    echo "Socket de cliente (FD 4) cerrado."
done

echo "Servidor finalizado (esto no debería verse en funcionamiento normal)."

exit 0