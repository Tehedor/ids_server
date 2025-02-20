#ifndef IDS_SERVER_H // Previene la inclusión múltiple
#define IDS_SERVER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <time.h>

#define PORT 8085 // Puerto configurable
#define LOG_FILE "../logs/ids_server.log"
#define VALID_IPS_FILE "../config/ips_validas.txt"
#define SCRIPTS_DIR "../scripts/"

// Declaraciones de funciones
void log_message(const char *message);
int is_valid_ip(const char *ip, char *role);
void execute_script(const char *ip, const char *role);
void handle_request(int client_sock, struct sockaddr_in *client_addr);

#endif