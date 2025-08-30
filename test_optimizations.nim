import os
import strutils

# Test program that outputs "Hello, World!"
const HELLO_WORLD_BF = """
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
"""

# Test program that outputs "A"
const SIMPLE_A_BF = """
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
"""

proc create_test_file(content: string, filename: string): string =
    writeFile(filename, content)
    return filename

proc run_test(compiler_name: string, bf_code: string, expected_output: string): bool =
    let test_file = create_test_file(bf_code, "temp_test.bf")
    defer: removeFile(test_file)
    
    let cmd = "$# $#" % [compiler_name, test_file]
    let (output, exit_code) = execCmdEx(cmd)
    
    if exit_code != 0:
        echo "ERROR: $# failed with exit code $#" % [compiler_name, $exit_code]
        return false
    
    if output.strip() != expected_output:
        echo "ERROR: $# produced '$#' but expected '$#'" % [compiler_name, output.strip(), expected_output]
        return false
    
    echo "✓ $# passed" % compiler_name
    return true

proc main() =
    echo "Testing Brainfuck Interpreter Optimizations"
    echo "=========================================="
    echo ""
    
    # Check if binaries exist
    let binaries = @["bin/bfjit_original", "bin/bfjit_optimized", "bin/bfjit_advanced"]
    
    for binary in binaries:
        if not fileExists(binary):
            echo "ERROR: Binary $# not found. Run 'make all' first." % binary
            quit(1)
    
    echo "Running correctness tests..."
    echo ""
    
    var all_passed = true
    
    # Test 1: Hello World
    echo "Test 1: Hello World program"
    let hello_expected = "Hello World!"
    all_passed = all_passed and run_test("bin/bfjit_original", HELLO_WORLD_BF, hello_expected)
    all_passed = all_passed and run_test("bin/bfjit_optimized", HELLO_WORLD_BF, hello_expected)
    all_passed = all_passed and run_test("bin/bfjit_advanced", HELLO_WORLD_BF, hello_expected)
    echo ""
    
    # Test 2: Simple A output
    echo "Test 2: Simple A output"
    let a_expected = "A"
    all_passed = all_passed and run_test("bin/bfjit_original", SIMPLE_A_BF, a_expected)
    all_passed = all_passed and run_test("bin/bfjit_optimized", SIMPLE_A_BF, a_expected)
    all_passed = all_passed and run_test("bin/bfjit_advanced", SIMPLE_A_BF, a_expected)
    echo ""
    
    # Test 3: Test files from test directory
    echo "Test 3: Test files from test directory"
    for test_file in walkFiles("test/*.bf"):
        echo "Testing file: $#" % test_file
        let content = readFile(test_file)
        
        # Run all versions and compare outputs
        let (orig_output, orig_exit) = execCmdEx("bin/bfjit_original $#" % test_file)
        let (opt_output, opt_exit) = execCmdEx("bin/bfjit_optimized $#" % test_file)
        let (adv_output, adv_exit) = execCmdEx("bin/bfjit_advanced $#" % test_file)
        
        if orig_exit != 0 or opt_exit != 0 or adv_exit != 0:
            echo "  ERROR: One or more versions failed to execute"
            all_passed = false
            continue
        
        if orig_output != opt_output or orig_output != adv_output:
            echo "  ERROR: Outputs don't match between versions"
            echo "    Original: '$#'" % orig_output.strip()
            echo "    Optimized: '$#'" % opt_output.strip()
            echo "    Advanced: '$#'" % adv_output.strip()
            all_passed = false
        else:
            echo "  ✓ All versions produced identical output"
    
    echo ""
    echo "Test Results:"
    echo "============="
    if all_passed:
        echo "✓ All tests passed! Optimizations are working correctly."
    else:
        echo "✗ Some tests failed. Please check the output above."
        quit(1)

when isMainModule:
    main()