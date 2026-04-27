#!/bin/bash

BENCHMARKS=$HOME/Nagini/benchmarks
LOGS=$HOME/logs
TIMESTAMP=$(date "+%Y%m%d_%H:%M:%S")
OUTPUT_FILE="$LOGS/run_Nagini_$TIMESTAMP.txt"

export BOOGIE_EXE=$HOME/.vscode/extensions/viper-admin.viper-5.3.2-linux-x64/dependencies/ViperTools/boogie/Binaries/Boogie
export MYPYPATH=$HOME/Nagini/src

mkdir -p $BENCHMARKS
mkdir -p $LOGS

echo "Starting Nagini Benchmarks: $BENCHMARKS." | tee -a "$OUTPUT_FILE"
echo "-------------------------------------------------------------"

i=0
N=8
FILES="$BENCHMARKS"/*.py
NUM_FILES=$(ls $FILES | wc -l)
for FILE in $FILES; do
    ((i++))
    FILENAME="${FILE##*/}"
    echo "Starting Benchmark $i/$NUM_FILES: $FILENAME."
    {
        echo "# Benchmark $i: $FILENAME ($FILE)."
        nagini --benchmark $N --verifier=carbon --boogie $BOOGIE_EXE "$FILE"
        echo ""
    } >> "$OUTPUT_FILE"
    echo "Done with Benchmark $i."
done
