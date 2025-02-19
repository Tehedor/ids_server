#!/bin/bash
# Este es el script 2 que se ejecutará al recibir una petición PUT válida.
uptime >> /tmp/script2_ejecutado.log
echo "Script 2 ejecutado" >> /tmp/script2_ejecutado.log
