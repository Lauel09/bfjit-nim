# Brainfuck Interpreter Makefile
# Compilation targets for different optimization levels

# Compiler and flags
NIM = nim
RELEASE_FLAGS = -d:release
DEBUG_FLAGS = -d:debug
SIZE_OPT_FLAGS = -d:release --opt:size
SPEED_OPT_FLAGS = -d:release --opt:speed
NO_GC_FLAGS = -d:release --gc:none

# Source files
SRC_DIR = src
ORIGINAL = $(SRC_DIR)/bfjit_nim.nim
OPTIMIZED = $(SRC_DIR)/jitcompiler_optimized.nim
ADVANCED = $(SRC_DIR)/jitcompiler_advanced.nim
MAIN = $(SRC_DIR)/bfjit_nim.nim

# Binary names
BIN_DIR = bin
ORIGINAL_BIN = $(BIN_DIR)/bfjit_original
OPTIMIZED_BIN = $(BIN_DIR)/bfjit_optimized
ADVANCED_BIN = $(BIN_DIR)/bfjit_advanced
BENCHMARK_BIN = $(BIN_DIR)/benchmark

# Test files
TEST_DIR = test
TEST_FILES = $(wildcard $(TEST_DIR)/*.bf)

# Default target
all: $(BIN_DIR) original optimized advanced benchmark

# Create binary directory
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Compile original version
original: $(BIN_DIR)
	$(NIM) c $(RELEASE_FLAGS) -o:$(ORIGINAL_BIN) $(MAIN)

# Compile optimized version
optimized: $(BIN_DIR)
	$(NIM) c $(RELEASE_FLAGS) -o:$(OPTIMIZED_BIN) $(MAIN)

# Compile advanced version
advanced: $(BIN_DIR)
	$(NIM) c $(RELEASE_FLAGS) -o:$(ADVANCED_BIN) $(MAIN)

# Compile with size optimization
size-opt: $(BIN_DIR)
	$(NIM) c $(SIZE_OPT_FLAGS) -o:$(BIN_DIR)/bfjit_size_opt $(MAIN)

# Compile with speed optimization
speed-opt: $(BIN_DIR)
	$(NIM) c $(SPEED_OPT_FLAGS) -o:$(BIN_DIR)/bfjit_speed_opt $(MAIN)

# Compile without garbage collector
no-gc: $(BIN_DIR)
	$(NIM) c $(NO_GC_FLAGS) -o:$(BIN_DIR)/bfjit_no_gc $(MAIN)

# Compile debug version
debug: $(BIN_DIR)
	$(NIM) c $(DEBUG_FLAGS) -o:$(BIN_DIR)/bfjit_debug $(MAIN)

# Compile benchmark
benchmark: $(BIN_DIR)
	$(NIM) c $(RELEASE_FLAGS) -o:$(BENCHMARK_BIN) benchmark.nim

# Run tests
test: all
	@echo "Testing original version..."
	@for file in $(TEST_FILES); do \
		echo "Running $$file with original version..."; \
		$(ORIGINAL_BIN) $$file; \
	done
	@echo "Testing optimized version..."
	@for file in $(TEST_FILES); do \
		echo "Running $$file with optimized version..."; \
		$(OPTIMIZED_BIN) $$file; \
	done
	@echo "Testing advanced version..."
	@for file in $(TEST_FILES); do \
		echo "Running $$file with advanced version..."; \
		$(ADVANCED_BIN) $$file; \
	done

# Run benchmark
bench: benchmark
	@echo "Running performance benchmark..."
	$(BENCHMARK_BIN)

# Show binary sizes
sizes: all
	@echo "Binary sizes:"
	@echo "============="
	@ls -lh $(BIN_DIR)/bfjit_* | awk '{print $$5, $$9}'

# Performance comparison
perf: all
	@echo "Performance comparison:"
	@echo "======================"
	@echo "Original version:"
	@time $(ORIGINAL_BIN) $(TEST_DIR)/test.bf > /dev/null 2>&1
	@echo "Optimized version:"
	@time $(OPTIMIZED_BIN) $(TEST_DIR)/test.bf > /dev/null 2>&1
	@echo "Advanced version:"
	@time $(ADVANCED_BIN) $(TEST_DIR)/test.bf > /dev/null 2>&1

# Clean build artifacts
clean:
	rm -rf $(BIN_DIR)
	rm -rf nimcache
	find . -name "*.exe" -delete
	find . -name "*.o" -delete

# Install dependencies (if any)
deps:
	@echo "No external dependencies required for this project"

# Help
help:
	@echo "Available targets:"
	@echo "  all        - Build all versions (default)"
	@echo "  original   - Build original version"
	@echo "  optimized  - Build optimized version"
	@echo "  advanced   - Build advanced version"
	@echo "  size-opt   - Build with size optimization"
	@echo "  speed-opt  - Build with speed optimization"
	@echo "  no-gc      - Build without garbage collector"
	@echo "  debug      - Build debug version"
	@echo "  benchmark  - Build benchmark tool"
	@echo "  test       - Run tests on all versions"
	@echo "  bench      - Run performance benchmark"
	@echo "  sizes      - Show binary sizes"
	@echo "  perf       - Quick performance comparison"
	@echo "  clean      - Clean build artifacts"
	@echo "  deps       - Install dependencies"
	@echo "  help       - Show this help"

.PHONY: all original optimized advanced benchmark test bench sizes perf clean deps help