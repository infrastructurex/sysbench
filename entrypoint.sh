#!/bin/sh
# shellcheck disable=SC2155
# shellcheck disable=SC3043
# shellcheck disable=SC2046
set -e

if [ $# -eq 0 ]; then
    readonly server=false
elif [ "$1" = "server" ]; then
    readonly server=true
else
    echo "Error: invalid argument '$1'" >&2
    exit 1
fi

cpu_score() {
  sysbench cpu run | grep "events per second" | cut -d ':' -f 2 | sed 's/^[[:space:]]*//'
}

memory_score() {
  sysbench memory run | grep "per second" | cut -d '(' -f 2 | cut -d ' ' -f 1
}

fileio_scores() {
  local results=$(sysbench fileio --file-test-mode=rndrw --file-total-size=$SIZE --time=$TIME --threads=8 --file-io-mode=sync --file-extra-flags=direct run)
  local read_score=$(echo "$results" | grep "read, MiB/s" | cut -d ':' -f 2 | sed 's/^[[:space:]]*//')
  local write_score=$(echo "$results" | grep "written, MiB/s" | cut -d ':' -f 2 | sed 's/^[[:space:]]*//')
  echo "$read_score $write_score"
}

echo "Preparing benchmarks ..." >&2
sysbench fileio --file-total-size=$SIZE prepare >&2
echo "Benchmarking CPU ..." >&2
readonly cpu_score=$(cpu_score)
echo "Benchmarking memory ..." >&2
readonly memory_score=$(memory_score)
echo "Benchmarking file i/o ..." >&2
readonly fileio_scores=$(fileio_scores)
readonly fileio_read_score=$(echo $fileio_scores | cut -d ' ' -f 1)
readonly fileio_write_score=$(echo $fileio_scores | cut -d ' ' -f 2)
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

cleanup() {
  echo "Done." >&2
  exit 0
}

trap cleanup INT
lighttpd -f $CONFIG_FILE -i 60 -D >&2

cleanup
