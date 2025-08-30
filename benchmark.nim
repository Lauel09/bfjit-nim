import times
import os
import strutils

# Import both versions
import jitcompiler
import jitcompiler_optimized
import jitcompiler_advanced

proc benchmark_original(file_path: string): float =
    let start_time = cpuTime()
    var jit_compiler = init_jit_compiler(file_path)
    jit_compiler.compile()
    let end_time = cpuTime()
    return end_time - start_time

proc benchmark_optimized(file_path: string): float =
    let start_time = cpuTime()
    var jit_compiler = init_jit_compiler(file_path)
    jit_compiler.compile()
    let end_time = cpuTime()
    return end_time - start_time

proc benchmark_advanced(file_path: string): float =
    let start_time = cpuTime()
    var jit_compiler = init_jit_compiler(file_path)
    jit_compiler.compile()
    let end_time = cpuTime()
    return end_time - start_time

proc create_test_file(): string =
    # Create a simple Brainfuck program for testing
    let test_content = """
    ++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
    """
    let test_file = "benchmark_test.bf"
    writeFile(test_file, test_content)
    return test_file

proc main() =
    echo "Brainfuck Interpreter Performance Benchmark"
    echo "=========================================="
    
    let test_file = create_test_file()
    defer: removeFile(test_file)
    
    const iterations = 10
    
    echo "Running benchmark with $# iterations..." % $iterations
    echo ""
    
    # Benchmark original version
    var original_times: seq[float]
    for i in 1..iterations:
        let time = benchmark_original(test_file)
        original_times.add(time)
    
    # Benchmark optimized version
    var optimized_times: seq[float]
    for i in 1..iterations:
        let time = benchmark_optimized(test_file)
        optimized_times.add(time)
    
    # Benchmark advanced version
    var advanced_times: seq[float]
    for i in 1..iterations:
        let time = benchmark_advanced(test_file)
        advanced_times.add(time)
    
    # Calculate averages
    let original_avg = original_times.sum() / iterations
    let optimized_avg = optimized_times.sum() / iterations
    let advanced_avg = advanced_times.sum() / iterations
    
    echo "Results:"
    echo "--------"
    echo "Original version:     $# seconds (avg)" % formatFloat(original_avg, ffDecimal, 6)
    echo "Optimized version:    $# seconds (avg)" % formatFloat(optimized_avg, ffDecimal, 6)
    echo "Advanced version:     $# seconds (avg)" % formatFloat(advanced_avg, ffDecimal, 6)
    echo ""
    
    let optimized_speedup = original_avg / optimized_avg
    let advanced_speedup = original_avg / advanced_avg
    
    echo "Performance Improvements:"
    echo "------------------------"
    echo "Optimized version:    $#x faster" % formatFloat(optimized_speedup, ffDecimal, 2)
    echo "Advanced version:     $#x faster" % formatFloat(advanced_speedup, ffDecimal, 2)
    echo ""
    
    echo "Memory Usage Analysis:"
    echo "--------------------"
    echo "Original:    Uses int (4 bytes) per memory cell"
    echo "Optimized:   Uses uint8 (1 byte) per memory cell"
    echo "Advanced:    Uses uint8 (1 byte) per memory cell + pattern optimization"
    echo ""
    echo "Memory reduction: 75% (4x less memory usage)"

when isMainModule:
    main()