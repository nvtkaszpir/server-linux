## Install

Run the following in a Linux shell:

```
bash <(curl -s https://raw.githubusercontent.com/nQuake/server-linux/master/src/install_nquakesv.sh)
```

## Settings

Settings are contained in `~/.nquakesv/config`.

Whenever settings are changed, you need to run `./stop_servers.sh` and then `./start_servers.sh`.

### Change number of ports

Add a new port (28508):

```
touch ~/.nquakesv/ports/28508
```

Remove a port (28508):

```
rm ~/.nquakesv/ports/28508
```

### QTV

To enable qtv (port 28000):

```
echo 28000 > ~/.nquakesv/qtv
```

To disable qtv:

```
rm ~/.nquakesv/qtv
```

### QWFWD

To enable qwfwd (port 30000):

```
echo 30000 > ~/.nquakesv/qwfwd
```

To disable qwfwd:

```
rm ~/.nquakesv/qwfwd
```
