.PHONY: all clean bench site

# Run all benchmarks and generate site
all: bench site

# Run benchmarks, output results to results/
bench:
	./scripts/run-benchmarks.sh

# Generate static site from results
site:
	./scripts/generate-site.sh

# Clean build artifacts and results
clean:
	rm -rf results/ site/
	find benchmarks -name "*.class" -delete
	find benchmarks -name "*.o" -delete
	find benchmarks -type f -executable -not -name "*.sh" -not -name "*.go" -not -name "*.java" -not -name "*.c" -delete
