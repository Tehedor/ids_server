[atrás](../Readme.md)

## Config Daemon
# Config Systemd

## 1. Create a systemd service file

``` bash
sudo vim /etc/systemd/system/ids_serverd.service
```

### ids_serverd.service

#### general_latest

``` ini
[Unit]
Description=Server for IDS system
After=multi-user.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/ids_server --daemonizado

[Install]
WantedBy=multi-user.target
```

## 2. Reload systemd and enable the service

``` bash
sudo systemctl daemon-reload
```

``` bash
sudo systemctl enable ids_serverd.service
```

## 3. Start the service

```bash
sudo systemctl start ids_serverd.service
```

## 3.2 Start the service

```bash
sudo systemctl restart ids_serverd.service
```

## 4. Check the service status

``` bash
sudo systemctl status ids_serverd.service
```

## **Nota importante:**

```bash
sudo systemctl disable ids_serverd.service
sudo systemctl stop ids_serverd.service
```



