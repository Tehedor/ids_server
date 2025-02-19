#include "ids_server.h" // Incluye el archivo de encabezado que acabamos de crear

void log_message(const char *message) {
    FILE *log_file = fopen(LOG_FILE, "a");
    if (log_file) {
        time_t now = time(NULL);
        fprintf(log_file, "%s - %s\n", strtok(ctime(&now), "\n"), message);
        fclose(log_file);
    }
}

int is_valid_ip(const char *ip) {
    FILE *file = fopen(VALID_IPS_FILE, "r");
    if (!file) return 0;

    char line[INET_ADDRSTRLEN];
    while (fgets(line, sizeof(line), file)) {
        line[strcspn(line, "\n")] = 0; // Eliminar salto de línea
        if (strcmp(line, ip) == 0) {
            fclose(file);
            return 1;
        }
    }
    fclose(file);
    return 0;
}

void execute_script(const char *ip) {
    char command[256];
    snprintf(command, sizeof(command), "%s%s.sh", SCRIPTS_DIR, ip);
    system(command);
    log_message("Ejecutado script para IP");
}

void handle_request(int client_sock, struct sockaddr_in *client_addr) {
    char buffer[1024];
    recv(client_sock, buffer, sizeof(buffer) - 1, 0);

    char method[8], path[256];
    sscanf(buffer, "%s %s", method, path);

    char *client_ip = inet_ntoa(client_addr->sin_addr);

    if (strcmp(method, "PUT") == 0 && is_valid_ip(client_ip)) {
        send(client_sock, "HTTP/1.1 200 OK\r\n\r\n", 19, 0);
        log_message("Solicitud PUT aceptada");
        execute_script(client_ip);
    } else {
        send(client_sock, "HTTP/1.1 403 Forbidden\r\n\r\n", 26, 0);
        log_message("Solicitud rechazada");
    }
    close(client_sock);
}

int main() {
    int server_sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server_addr = {AF_INET, htons(PORT), INADDR_ANY};

    bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
    listen(server_sock, 5);

    log_message("Servidor iniciado");

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t addr_size = sizeof(client_addr);
        int client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &addr_size);
        if (client_sock >= 0) {
            handle_request(client_sock, &client_addr);
        }
    }
    close(server_sock);
    return 0;
}