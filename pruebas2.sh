#!/bin/bash
while true; do
    # Espera una conexión en el puerto 8080 y guarda la petición en request.txt
    nc -l -p 8080 > request.txt
    
    # Lee la petición y genera una respuesta
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHola, mundo!" > response.txt
    
    # Envía la respuesta al cliente
    cat response.txt | nc -l -p 8081
done