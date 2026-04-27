#!/bin/bash

BENCHMARKS=$HOME/Dafny_Benchmarks
LOGS=$HOME/logs
TIMESTAMP=$(date "+%Y%m%d_%H:%M:%S")
OUTPUT_FILE="$LOGS/run_Dafny_$TIMESTAMP.txt"

mkdir -p $BENCHMARKS
mkdir -p $LOGS

echo "Starting Dafny Benchmarks: $BENCHMARKS." | tee -a "$OUTPUT_FILE"
echo "------------------------------------------------------------"

i=0
N=8
TIMESTAMP=$(date "+%Y%m%d_%H:%M:%S")
FILES="$BENCHMARKS"/*_encoded.dfy
NUM_FILES=$(ls $FILES | wc -l)
for FILE in $FILES; do
    ((i++))
    FILENAME="${FILE##*/}"
    echo "Starting Dafny Benchmark $i/$NUM_FILES: $FILENAME."
    echo "# Benchmark $i: $FILENAME ($FILE)." >> "$OUTPUT_FILE"

    for j in {1..8}; do
        {
            time -f "Time [s]: %e" dafny verify "$FILE"
            echo
        } >> "$OUTPUT_FILE"
        echo "Done with Benchmark $i."
    done
done
