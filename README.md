# Language Benchmarks

Performance benchmarks comparing language implementations across classic algorithms. Results published as a static site via GitHub Pages.

## Languages

- **C** (gcc)
- **Go** (latest stable)
- **Java** (OpenJDK 21)

More languages (Common Lisp/SBCL, Clojure, Rust) planned.

## Benchmarks

| Benchmark | Description | Workload |
|-----------|-------------|----------|
| **n-body** | Gravitational N-body simulation | Floating-point math, loops |
| **binary-trees** | Allocate/deallocate binary trees | GC pressure, allocation |
| **fannkuch-redux** | Pancake flipping permutations | Integer compute, combinatorics |

## Structure

```
benchmarks/
├── n-body/
│   ├── c/
│   ├── go/
│   └── java/
├── binary-trees/
│   ├── c/
│   ├── go/
│   └── java/
└── fannkuch-redux/
    ├── c/
    ├── go/
    └── java/
scripts/
├── run-benchmarks.sh     # Orchestrator
└── generate-site.sh      # Static site generator
site/                     # Generated GitHub Pages output
.github/
└── workflows/
    └── benchmark.yml     # CI: run benchmarks + publish
```

## How It Works

1. GitHub Actions runs all benchmarks on a consistent runner
2. Results are captured as JSON (time, memory, CPU)
3. A static site is generated from the results
4. Site is published to GitHub Pages

## Inspiration

- [Debian Benchmarks Game](https://benchmarksgame-team.pages.debian.net/benchmarksgame/index.html) ([source](https://salsa.debian.org/benchmarksgame-team/benchmarksgame))
- [Programming Language Benchmarks](https://programming-language-benchmarks.vercel.app/) ([source](https://github.com/hanabi1224/Programming-Language-Benchmarks))

## Contributing

PRs welcome for new language implementations or benchmark optimizations. Each implementation should be idiomatic for its language — no "write C in Java" style code.

## License

MIT
