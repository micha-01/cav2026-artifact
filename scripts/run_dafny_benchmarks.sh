#!/bin/bash

BENCHMARKS=$HOME/Dafny_Benchmarks
LOGS=$HOME/logs

mkdir -p $BENCHMARKS
mkdir -p $LOGS

echo "Starting Dafny Benchmarks: $BENCHMARKS."

i=0
N=6
TIMESTAMP=$(date "+%Y%m%d_%H:%M:%S")
FILES="$BENCHMARKS"/*.dfy
NUM_FILES=$(ls $FILES | wc -l)
for FILE in $FILES; do
    ((i++))
    FILENAME="${FILE##*/}"
    echo "Starting Dafny Benchmark $i/$NUM_FILES: $FILENAME."
    {
        echo "# Benchmark $i: $FILENAME."
        time dafny verify "$FILE"
        echo ""
    } >> "$LOGS/run_Dafny_$TIMESTAMP.txt"
    echo "Done with Benchmark $i."
done
