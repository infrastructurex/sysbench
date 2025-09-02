#!/bin/sh
set -e

if [ $# -eq 0 ]; then
    readonly server=false
elif [ "$1" = "server" ]; then
    readonly server=true
else
    echo "Error: invalid argument '$1'" >&2
    exit 1
fi

function cpu_score() {
  sysbench cpu run | grep "events per second" | cut -d ':' -f 2 | sed 's/^[[:space:]]*//'
}

function memory_score() {
  sysbench memory run | grep "per second" | cut -d '(' -f 2 | cut -d ' ' -f 1
}

function fileio_read_score() {
  sysbench fileio --file-test-mode=rndrd run | grep "reads/s" | cut -d ':' -f 2 | sed 's/^[[:space:]]*//'
}

function fileio_write_score() {
  sysbench fileio --file-test-mode=rndwr run | grep "writes/s" | cut -d ':' -f 2 | sed 's/^[[:space:]]*//'
}

echo "Preparing benchmarks ..." >&2
sysbench fileio prepare > /dev/null
echo "Benchmarking CPU ..." >&2
readonly cpu_score=$(cpu_score)
echo "Benchmarking memory ..." >&2
readonly memory_score=$(memory_score)
echo "Benchmarking file reads ..." >&2
readonly fileio_read_score=$(fileio_read_score)
echo "Benchmarking file writes ..." >&2
readonly fileio_write_score=$(fileio_write_score)
echo "Results:" >&2

readonly HTTP_DIR=/http
mkdir $HTTP_DIR
readonly JSON_FILE=$HTTP_DIR/results.json
cat <<-_EOF_ >$JSON_FILE
{
  "cpu" : $cpu_score,
  "memory" : $memory_score,
  "fileio-read" : $fileio_read_score,
  "fileio-write" : $fileio_write_score
}
_EOF_
cat $JSON_FILE

if [ "$server" != true ]; then
  exit 0
fi

readonly CONFIG_FILE=/lighttp.conf
cat <<-_EOF_ >$CONFIG_FILE
server.document-root = "$HTTP_DIR"
server.port = $PORT
_EOF_

function cleanup() {
  echo "Done." >&2
  exit 0
}

trap cleanup INT
lighttpd -f $CONFIG_FILE -i 60 -D >&2

cleanup
