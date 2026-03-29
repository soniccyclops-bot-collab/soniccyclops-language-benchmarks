#!/bin/bash
# run-benchmarks.sh — Run all benchmarks and collect results as JSON
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$ROOT_DIR/results"
BENCH_DIR="$ROOT_DIR/benchmarks"
RUNS="${BENCHMARK_RUNS:-1}"  # Number of runs per benchmark (increase for local use)
TIMEOUT="${BENCHMARK_TIMEOUT:-300}"  # Per-run timeout in seconds (default 5 min)

mkdir -p "$RESULTS_DIR"

# Benchmark configurations: name|input_arg
declare -A BENCH_ARGS=(
    ["n-body"]="5000000"
    ["binary-trees"]="21"
    ["fannkuch-redux"]="10"
)

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

run_single() {
    local bench="$1" lang="$2" cmd="$3" arg="$4"
    local times=()

    for ((i=1; i<=RUNS; i++)); do
        # Use /usr/bin/time for wall clock + max RSS, with timeout
        result=$( { timeout "$TIMEOUT" /usr/bin/time -v $cmd $arg > /dev/null; } 2>&1 )
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "  Run $i: TIMEOUT (>${TIMEOUT}s) — skipping"
            return 1
        fi
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
        cl)
            src=$(find "$dir" -name "*.lisp" | head -1)
            bin="$dir/benchmark"
            sbcl --disable-debugger --no-sysinit --no-userinit --load "$src" --eval '(sb-ext:save-lisp-and-die "'"$bin"'" :toplevel #'"'"'main :executable t)' 2>/dev/null
            run_single "$bench" "$lang" "$bin" "$arg"
            ;;
        python)
            src=$(find "$dir" -name "*.py" | head -1)
            for runtime in python3 pypy3 graalpy; do
                if command -v $runtime &>/dev/null; then
                    echo "=== $bench / $runtime ==="
                    result=$(run_single "$bench" "$runtime" "$runtime $src" "$arg")
                    json_line=$(echo "$result" | tail -1)
                    echo "$json_line" >> "$RESULTS_DIR/results.jsonl"
                fi
            done
            # Clython (Python interpreter in Common Lisp)
            if [ -x "$ROOT_DIR/.clython/bin/clython" ]; then
                echo "=== $bench / clython ==="
                result=$(run_single "$bench" "clython" "$ROOT_DIR/.clython/bin/clython $src" "$arg" 2>/dev/null) || true
                if [ -n "$result" ]; then
                    json_line=$(echo "$result" | tail -1)
                    echo "$json_line" >> "$RESULTS_DIR/results.jsonl"
                else
                    echo "  SKIPPED (clython failed)"
                fi
            fi
            return 0
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
        if ! find "$lang_dir" -name "*.c" -o -name "*.go" -o -name "*.java" -o -name "*.lisp" -o -name "*.py" 2>/dev/null | grep -q .; then
            echo "=== $bench / $lang === SKIPPED (no source)"
            continue
        fi

        # Python handles its own result output (multiple runtimes)
        if [ "$lang" = "python" ]; then
            compile_and_run "$bench" "$lang" "$lang_dir" "$arg"
            continue
        fi

        result=$(compile_and_run "$bench" "$lang" "$lang_dir" "$arg")
        json_line=$(echo "$result" | tail -1)
        echo "$json_line" >> "$RESULTS_DIR/results.jsonl"
    done
done

echo ""
echo "Results written to $RESULTS_DIR/results.jsonl"
