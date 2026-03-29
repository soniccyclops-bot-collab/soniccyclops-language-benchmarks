#!/bin/bash
# run-benchmarks.sh — Run all benchmarks and collect results as JSON
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$ROOT_DIR/results"
BENCH_DIR="$ROOT_DIR/benchmarks"
RUNS="${BENCHMARK_RUNS:-1}"  # Number of runs per benchmark (increase for local use)

mkdir -p "$RESULTS_DIR"

# Benchmark configurations: name|input_arg
declare -A BENCH_ARGS=(
    ["n-body"]="50000000"
    ["binary-trees"]="21"
    ["fannkuch-redux"]="10"
)

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

run_single() {
    local bench="$1" lang="$2" cmd="$3" arg="$4"
    local times=()

    for ((i=1; i<=RUNS; i++)); do
        # Use /usr/bin/time for wall clock + max RSS
        result=$( { /usr/bin/time -v $cmd $arg > /dev/null; } 2>&1 )
        wall=$(echo "$result" | grep "Elapsed (wall clock)" | sed 's/.*: //')
        maxrss=$(echo "$result" | grep "Maximum resident" | awk '{print $NF}')

        # Convert wall clock to seconds
        if [[ "$wall" == *:*:* ]]; then
            secs=$(echo "$wall" | awk -F: '{print ($1*3600)+($2*60)+$3}')
        else
            secs=$(echo "$wall" | awk -F: '{print ($1*60)+$2}')
        fi
        times+=("$secs")
        echo "  Run $i: ${secs}s, ${maxrss}KB"
    done

    # Sort and take median
    sorted=($(printf '%s\n' "${times[@]}" | sort -n))
    median_idx=$(( RUNS / 2 ))
    median="${sorted[$median_idx]}"

    echo "{\"benchmark\":\"$bench\",\"language\":\"$lang\",\"median_seconds\":$median,\"max_rss_kb\":$maxrss,\"runs\":$RUNS,\"input\":\"$arg\",\"timestamp\":\"$timestamp\"}"
}

compile_and_run() {
    local bench="$1" lang="$2" dir="$3" arg="$4"

    echo "=== $bench / $lang ==="

    case "$lang" in
        c)
            src=$(find "$dir" -name "*.c" | head -1)
            bin="$dir/benchmark"
            gcc -O2 -o "$bin" "$src" -lm
            run_single "$bench" "$lang" "$bin" "$arg"
            ;;
        go)
            src=$(find "$dir" -name "*.go" | head -1)
            bin="$dir/benchmark"
            (cd "$dir" && go build -o benchmark .)
            run_single "$bench" "$lang" "$bin" "$arg"
            ;;
        java)
            src=$(find "$dir" -name "*.java" | head -1)
            classname=$(basename "$src" .java)
            javac -d "$dir" "$src"
            run_single "$bench" "$lang" "java -cp $dir $classname" "$arg"
            ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

# Collect all results
all_results="[]"

for bench in "${!BENCH_ARGS[@]}"; do
    arg="${BENCH_ARGS[$bench]}"
    bench_dir="$BENCH_DIR/$bench"

    for lang_dir in "$bench_dir"/*/; do
        lang=$(basename "$lang_dir")
        [ "$lang" = "README.md" ] && continue

        # Check if there are source files
        if ! find "$lang_dir" -name "*.c" -o -name "*.go" -o -name "*.java" 2>/dev/null | grep -q .; then
            echo "=== $bench / $lang === SKIPPED (no source)"
            continue
        fi

        result=$(compile_and_run "$bench" "$lang" "$lang_dir" "$arg")
        json_line=$(echo "$result" | tail -1)
        echo "$json_line" >> "$RESULTS_DIR/results.jsonl"
    done
done

echo ""
echo "Results written to $RESULTS_DIR/results.jsonl"
