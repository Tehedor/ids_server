#!/bin/bash

# Puerto de escucha
PUERTO=8085

# Función para manejar las peticiones
manejador_peticion() {
  local socket_cliente=$1

  # Leer la petición del cliente
  read -r peticion <&"$socket_cliente"

  # Extraer el método HTTP
  metodo=$(echo "$peticion" | awk '{print $1}')

  # Verificar si es una petición PUT
  if [[ "$metodo" == "PUT" ]]; then
    # Petición PUT recibida

    # Leer el cuerpo de la petición (si existe)
    cuerpo=""
    while read -r linea; do
      cuerpo+="$linea"$'\n'
    done <&"$socket_cliente"

    # Mostrar la petición y el cuerpo (opcional)
    echo "Petición PUT recibida:"
    echo "$peticion"
    echo "Cuerpo:"
    echo "$cuerpo"

    # Responder al cliente con un mensaje de éxito
    echo -e "HTTP/1.1 200 OK\r\n\r\nPetición PUT recibida y procesada." >&"$socket_cliente"
  else
    # Método no permitido
    echo -e "HTTP/1.1 405 Method Not Allowed\r\n\r\nSe espera método PUT." >&"$socket_cliente"
  fi

  # Cerrar el socket del cliente
  exec {socket_cliente}<&-
}

# Bucle principal del servidor
while true; do
  # Escuchar en el puerto especificado
  nc -l -p "$PUERTO" -k | (
    # Obtener el socket del cliente
    socket_cliente=$(cat <&3)
    exec 3<&-

    # Manejar la petición en segundo plano
    manejador_peticion "$socket_cliente" &
  ) 3<&0
done