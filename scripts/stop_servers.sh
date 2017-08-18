#!/bin/sh

stop_port() {
  port=$1
  pid=$(ps ax | grep -v grep | grep "mvdsv -port ${port}" | awk '{print $1}')
  kill -9 ${pid} >/dev/null
}

[ $(ps ax | grep -v grep | grep -c "start_servers.sh") -gt 0 ] && killall -9 start_servers.sh

for f in ~/.nquakesv/ports/*; do
  port=$(basename ${f})
  count=$(ps ax | grep -v grep | grep -c "mvdsv -port ${port}")
  printf "* Stopping mvdsv (port ${port})..."
  [ ${count} -gt 0 ] && {
    stop_port ${port}
    echo "[OK]"
  } || echo "[NOT RUNNING]"
done

[ -f ~/.nquakesv/qtv ] && {
  qtvport=$(cat ~/.nquakesv/qtv)
  printf "* Stopping qtv (port ${qtvport})..."
  count=$(ps ax | grep -v grep | grep -c "qtv.bin +exec qtv.cfg")
  [ ${count} -gt 0 ] && {
    pid=$(ps ax | grep -v grep | grep "qtv.bin +exec qtv.cfg" | awk '{print $1}')
    kill -9 ${pid} >/dev/null
    echo "[OK]"
  } || echo "[NOT RUNNING]"
}

[ -f ~/.nquakesv/qwfwd ] && {
  qwfwdport=$(cat ~/.nquakesv/qwfwd)
  printf "* Stopping qwfwd (port ${qwfwdport})..."
  count=$(ps ax | grep -v grep | grep -c "qwfwd.bin" )
  [ ${count} -gt 0 ] && {
    pid=$(ps ax | grep -v grep | grep "qwfwd.bin" | awk '{print $1}')
    kill -9 ${pid} >/dev/null
    echo "[OK]"
  } || echo "[NOT RUNNING]"
}
