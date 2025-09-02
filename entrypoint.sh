#!/bin/sh

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

sysbench fileio prepare > /dev/null
readonly cpu_score=$(cpu_score)
readonly memory_score=$(memory_score)
readonly fileio_read_score=$(fileio_read_score)
readonly fileio_write_score=$(fileio_write_score)

echo -e "{\n  \"cpu\":\"$cpu_score\",\n  \"memory\":\"$memory_score\",\n  \"fileio-read\":\"$fileio_read_score\",\n  \"fileio-write\":\"$fileio_write_score\"\n}"

#sysbench memory run
