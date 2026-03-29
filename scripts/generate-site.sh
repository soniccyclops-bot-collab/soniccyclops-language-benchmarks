#!/bin/bash
# generate-site.sh — Generate static HTML site from benchmark results
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$ROOT_DIR/results"
SITE_DIR="$ROOT_DIR/site"
RESULTS_FILE="$RESULTS_DIR/results.jsonl"

mkdir -p "$RESULTS_DIR"

if [ ! -f "$RESULTS_FILE" ] || [ ! -s "$RESULTS_FILE" ]; then
    echo "No benchmark results yet. Generating placeholder site."
    mkdir -p "$SITE_DIR"
    cat > "$SITE_DIR/index.html" << 'PLACEHOLDER'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Language Benchmarks</title>
    <style>
        body { font-family: -apple-system, sans-serif; background: #0d1117; color: #e6edf3; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .msg { text-align: center; }
        h1 { margin-bottom: 1rem; }
        p { color: #8b949e; }
        a { color: #58a6ff; }
    </style>
</head>
<body>
    <div class="msg">
        <h1>⚡ Language Benchmarks</h1>
        <p>No benchmark results yet. Implementations are in progress.</p>
        <p><a href="https://github.com/soniccyclops-bot-collab/soniccyclops-language-benchmarks/issues">View open issues</a></p>
    </div>
</body>
</html>
PLACEHOLDER
    echo "Placeholder site generated at $SITE_DIR/index.html"
    exit 0
fi

mkdir -p "$SITE_DIR"

# Convert JSONL to JSON array
results_json=$(jq -s '.' "$RESULTS_FILE")

# Group by benchmark
benchmarks=$(echo "$results_json" | jq -r '.[].benchmark' | sort -u)

# Generate HTML
cat > "$SITE_DIR/index.html" << 'HEADER'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Language Benchmarks</title>
    <style>
        :root {
            --bg: #0d1117;
            --surface: #161b22;
            --border: #30363d;
            --text: #e6edf3;
            --text-muted: #8b949e;
            --accent: #58a6ff;
            --green: #3fb950;
            --yellow: #d29922;
            --red: #f85149;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            background: var(--bg);
            color: var(--text);
            line-height: 1.6;
            padding: 2rem;
            max-width: 1200px;
            margin: 0 auto;
        }
        h1 { margin-bottom: 0.5rem; }
        .subtitle { color: var(--text-muted); margin-bottom: 2rem; }
        .benchmark-section {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }
        .benchmark-section h2 {
            color: var(--accent);
            margin-bottom: 1rem;
            font-size: 1.3rem;
        }
        .bar-chart { width: 100%; }
        .bar-row {
            display: flex;
            align-items: center;
            margin-bottom: 0.75rem;
            gap: 1rem;
        }
        .bar-label {
            width: 80px;
            font-weight: 600;
            text-align: right;
            flex-shrink: 0;
        }
        .bar-container {
            flex: 1;
            background: var(--border);
            border-radius: 4px;
            height: 32px;
            position: relative;
            overflow: hidden;
        }
        .bar {
            height: 100%;
            border-radius: 4px;
            display: flex;
            align-items: center;
            padding-left: 0.75rem;
            font-size: 0.85rem;
            font-weight: 600;
            min-width: fit-content;
            transition: width 0.5s ease;
        }
        .bar.fastest { background: var(--green); }
        .bar.mid { background: var(--yellow); }
        .bar.slow { background: var(--red); }
        .meta {
            color: var(--text-muted);
            font-size: 0.8rem;
            margin-top: 0.5rem;
        }
        footer {
            color: var(--text-muted);
            text-align: center;
            margin-top: 3rem;
            font-size: 0.85rem;
        }
        footer a { color: var(--accent); text-decoration: none; }
    </style>
</head>
<body>
    <h1>⚡ Language Benchmarks</h1>
    <p class="subtitle">Performance comparison across languages. Lower is faster.</p>
    <div id="results">
HEADER

# Generate benchmark sections
for bench in $benchmarks; do
    echo "    <div class=\"benchmark-section\">" >> "$SITE_DIR/index.html"
    echo "        <h2>$bench</h2>" >> "$SITE_DIR/index.html"
    echo "        <div class=\"bar-chart\">" >> "$SITE_DIR/index.html"

    # Get results for this benchmark, sorted by time
    bench_results=$(echo "$results_json" | jq -c "[ .[] | select(.benchmark == \"$bench\") ] | sort_by(.median_seconds)")
    fastest=$(echo "$bench_results" | jq '.[0].median_seconds')
    count=$(echo "$bench_results" | jq 'length')

    for ((i=0; i<count; i++)); do
        lang=$(echo "$bench_results" | jq -r ".[$i].language")
        time=$(echo "$bench_results" | jq -r ".[$i].median_seconds")
        rss=$(echo "$bench_results" | jq -r ".[$i].max_rss_kb")

        # Calculate bar width as percentage (fastest = 100%)
        if [ "$fastest" != "0" ]; then
            pct=$(echo "$time $fastest" | awk '{printf "%.0f", ($2/$1)*100}')
        else
            pct=100
        fi

        # Color class
        if [ "$i" -eq 0 ]; then
            cls="fastest"
        elif [ "$i" -lt $((count - 1)) ]; then
            cls="mid"
        else
            cls="slow"
        fi

        rss_mb=$(echo "$rss" | awk '{printf "%.1f", $1/1024}')

        cat >> "$SITE_DIR/index.html" << EOF
            <div class="bar-row">
                <span class="bar-label">$lang</span>
                <div class="bar-container">
                    <div class="bar $cls" style="width: ${pct}%">${time}s · ${rss_mb}MB</div>
                </div>
            </div>
EOF
    done

    input=$(echo "$bench_results" | jq -r '.[0].input')
    echo "        </div>" >> "$SITE_DIR/index.html"
    echo "        <p class=\"meta\">Input: $input · Median of $(echo "$bench_results" | jq '.[0].runs') runs</p>" >> "$SITE_DIR/index.html"
    echo "    </div>" >> "$SITE_DIR/index.html"
done

cat >> "$SITE_DIR/index.html" << 'FOOTER'
    </div>
    <footer>
        <p>Generated by <a href="https://github.com/soniccyclops-bot-collab/soniccyclops-language-benchmarks">soniccyclops-language-benchmarks</a></p>
        <p>Inspired by the <a href="https://benchmarksgame-team.pages.debian.net/benchmarksgame/index.html">Debian Benchmarks Game</a>
        and <a href="https://github.com/hanabi1224/Programming-Language-Benchmarks">Programming Language Benchmarks</a></p>
    </footer>
</body>
</html>
FOOTER

echo "Site generated at $SITE_DIR/index.html"
