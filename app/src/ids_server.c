#include "ids_server.h" // Incluye el archivo de encabezado que acabamos de crear

void log_message(const char *message) {
    FILE *log_file = fopen(LOG_FILE, "a");
    if (log_file) {
        time_t now = time(NULL);
        fprintf(log_file, "%s - %s\n", strtok(ctime(&now), "\n"), message);
        fclose(log_file);
    }
}

int is_valid_ip(const char *ip, char *role) {
    // printf("Validando IP: %s\n", ip);
    FILE *file = fopen(VALID_IPS_FILE, "r");
    if (!file) {
        printf("No se pudo abrir el archivo de IPs válidas\n");
        return 0;
    }

    char line[INET_ADDRSTRLEN];
    char master_ips[MAX_IPS][INET_ADDRSTRLEN];
    char worker_ips[MAX_IPS][INET_ADDRSTRLEN];
    int master_count = 0, worker_count = 0;
    int is_master_section = 0, is_worker_section = 0;

    // printf("Contenido del archivo %s:\n", VALID_IPS_FILE);
    while (fgets(line, sizeof(line), file)) {
        // printf("%s", line);
        line[strcspn(line, "\n")] = 0; // Eliminar salto de línea

        // Eliminar espacios en blanco al inicio y al final de la línea
        char *start = line;
        while (isspace((unsigned char)*start)) start++;
        char *end = line + strlen(line) - 1;
        while (end > start && isspace((unsigned char)*end)) end--;
        *(end + 1) = '\0';

        // Ignorar líneas en blanco
        if (strlen(start) == 0) {
            continue;
        }

        if (strcmp(start, "[master]") == 0) {
            is_master_section = 1;
            is_worker_section = 0;
            continue;
        } else if (strcmp(start, "[worker]") == 0) {
            is_master_section = 0;
            is_worker_section = 1;
            continue;
        }

        if (is_master_section && master_count < MAX_IPS) {
            strcpy(master_ips[master_count++], start);
        } else if (is_worker_section && worker_count < MAX_IPS) {
            strcpy(worker_ips[worker_count++], start);
        }
    }
    fclose(file);

    // printf("\nIPs master:\n");
    // for (int i = 0; i < master_count; i++) {
    //     printf("%s\n", master_ips[i]);
    // }
    
    // printf("IPs worker:\n");
    // for (int i = 0; i < worker_count; i++) {
    //     printf("%s\n", worker_ips[i]);
    // }
    
    for (int i = 0; i < master_count; i++) {
        if (strcmp(master_ips[i], ip) == 0) {
            strcpy(role, "master");
            printf("IP %s es master\n", ip);
            return 1;
        }
    }
    
    for (int i = 0; i < worker_count; i++) {
        if (strcmp(worker_ips[i], ip) == 0) {
            printf("IP %s es worker\n", ip);
            strcpy(role, "worker");
            return 1;
        }
    }

    return 0;
}

void execute_script(const char *ip, const char *role) {
    char command[256];
    snprintf(command, sizeof(command), "%s/%s.sh", SCRIPTS_DIR, role);

    // Crear el mensaje de registro
    char log_msg[512];
    snprintf(log_msg, sizeof(log_msg), "Ejecutando script: %s para IP: %s con rol: %s", command, ip, role);

    // Imprimir en la consola el script que se está ejecutando, la IP y el rol
    log_message(log_msg);

    system(command);
    // log_message("Ejecutado script para IP");
}
void handle_request(int client_sock, struct sockaddr_in *client_addr) {
    char buffer[1024];
    recv(client_sock, buffer, sizeof(buffer) - 1, 0);

    char method[8], path[256];
    sscanf(buffer, "%s %s", method, path);

    char *client_ip = inet_ntoa(client_addr->sin_addr);
    char role[10];

    if (strcmp(method, "PUT") == 0 && is_valid_ip(client_ip, role)) {
        send(client_sock, "HTTP/1.1 200 OK\r\n\r\n", 19, 0);
        log_message("Solicitud PUT aceptada");
        execute_script(client_ip, role);
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
    printf("Servidor iniciado en el puerto %d\n", PORT);

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t addr_size = sizeof(client_addr);
        int client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &addr_size);
        if (client_sock >= 0) {
            handle_request(client_sock, &client_addr);
        }
    }
    close(server_sock);
    printf("Servidor finalizado\n");
    return 0;
}