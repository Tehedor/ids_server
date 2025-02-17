
# IDS server

## Scripit 


## App Config

/usr/local/share/ids_server

```bash 
sudo cp -r ids_server /usr/local/share/
```

``` bash
sudo chmod -R +x /usr/local/share/ids_server/*
```
``` bash 
sudo ln -s /usr/local/share/ids_server/ids_server.sh /usr/local/bin/ids_server
```

## Daemon config
/etc/systemd/system/ids_serverdd.service

[Daemon config](./z_readme/10-Daemon_Config.md)

## Test
```bash 
curl -X PUT http://localhost:8085/path/to/resource -d "data=example"
```