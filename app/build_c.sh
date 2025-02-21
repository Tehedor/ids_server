gcc -o ./bin/ids_server ./src/ids_server.c -lsystemd
cp ./bin/ids_server ../dpkg-ids-server/usr/local/ids_server/bin/ids_server