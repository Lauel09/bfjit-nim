import os, strutils
import std/syncio

type 
    OpKind = enum 
        OpInc, OpDec, OpLeft, OpRight, OpInput, OpOutput, OpJmpIfZero, OpJmpIfNonZero

# Optimized: Use direct mapping instead of Option for better performance
const CHAR_TO_OP: array[256, int8] = block:
    var result: array[256, int8]
    for i in 0..255:
        result[i] = -1
    result[ord('+')] = 0  # OpInc
    result[ord('-')] = 1  # OpDec
    result[ord('<')] = 2  # OpLeft
    result[ord('>')] = 3  # OpRight
    result[ord(',')] = 4  # OpInput
    result[ord('.')] = 5  # OpOutput
    result[ord('[')] = 6  # OpJmpIfZero
    result[ord(']')] = 7  # OpJmpIfNonZero
    result

# Optimized: Direct conversion without function call overhead
proc from_char(character: char): int8 = 
    CHAR_TO_OP[ord(character)]

type 
    Op = object 
        kind: OpKind
        operand: int

type
    Error = object
        what: string
        pos: int

type 
    JitCompiler* = object
        memory: seq[uint8]  # Optimized: Use uint8 instead of int for memory
        addr_stack: seq[int]
        content: string
        abs_fpath: string
        current: int
        has_error: bool  # Optimized: Simple boolean instead of Option
        error_msg: string
        error_pos: int
        ops: seq[Op]

# Optimized: Inline functions for better performance
template is_cmd(token: char): bool = 
    CHAR_TO_OP[ord(token)] >= 0

template at_end(jc: JitCompiler): bool = 
    jc.current >= jc.content.len()

# Optimized: More efficient advance function
proc advance(l: var JitCompiler): char =
    while not l.at_end() and not is_cmd(l.content[l.current]):
        l.current += 1
    
    if not l.at_end():
        result = l.content[l.current]
        l.current += 1
    else:
        result = '\0'

# Optimized: More efficient token scanning with better error handling
proc scan_token(jc: var JitCompiler) =  
    while jc.current < jc.content.len() and not jc.has_error:
        let cur_char = jc.content[jc.current]
        let op_code = from_char(cur_char)
        
        if op_code >= 0:
            case op_code
            of 0, 1, 2, 3, 4, 5:  # +, -, <, >, ,, .
                var count = 1
                let op_kind = OpKind(op_code)
                
                # Optimized: Count consecutive operations
                while jc.current + 1 < jc.content.len() and jc.content[jc.current + 1] == cur_char:
                    count += 1
                    jc.current += 1
                
                jc.ops.add(Op(kind: op_kind, operand: count))
                jc.current += 1

            of 6:  # '['
                let address = jc.ops.len()
                jc.addr_stack.add(address)
                jc.ops.add(Op(kind: OpJmpIfZero, operand: 0))
                jc.current += 1

            of 7:  # ']'
                if jc.addr_stack.len() == 0:
                    jc.has_error = true
                    jc.error_msg = "']' encountered without an '[' before it - Unbalanced loop!"
                    jc.error_pos = jc.current
                else:
                    let open_brck_add = jc.addr_stack.pop()
                    let close_brck_obj = Op(kind: OpJmpIfNonZero, operand: open_brck_add)
                    jc.ops.add(close_brck_obj)
                    jc.ops[open_brck_add].operand = jc.ops.len() 
                jc.current += 1
        else:
            jc.current += 1

# Optimized: More efficient file loading
proc load_file(c: var JitCompiler, file_name: string) =
    try:
        if fileExists(fileName):
            let abs_fpath = absolutePath(fileName)
            let content = readFile(abs_fpath).strip()
            
            c.content = content
            c.abs_fpath = abs_fpath
            c.current = 0
            c.has_error = false
            echo c.content
        else:
            stdout.write("File does not exist! Exiting!\n")
            
    except Exception as e:
        debugEcho(e.astToStr())

# Optimized: More efficient string representation
proc to_string*(jc: JitCompiler): string =
    result = "JitCompiler: {\n"
    result.add("    abs_fpath: " & jc.abs_fpath & "\n")
    result.add("    addr_stack: " & $jc.addr_stack & "\n")
    result.add("    current: " & $jc.current & "\n")
    result.add("    has_error: " & $jc.has_error & "\n")
    result.add("    ops: " & $jc.ops & "\n")
    result.add("}\n")

proc scan_tokens*(jc: var JitCompiler) = 
    jc.scan_token()
    if jc.has_error:
        stderr.write("[ERROR] - ", jc.error_msg, " at: ", jc.error_pos, "\n")

# Optimized: More efficient execution with better memory management
proc compile*(jc: var JitCompiler) =  
    echo "Starting optimized interpreter"
    jc.scan_tokens()

    if jc.has_error:
        return

    # Optimized: Use uint8 for memory and better bounds checking
    var 
        head = 0
        ip = 0
        memory_size = jc.memory.len()

    # Optimized: Pre-allocate memory if needed
    if memory_size < 30000:  # Standard Brainfuck memory size
        jc.memory.setLen(30000)

    while ip < jc.ops.len():
        let op = jc.ops[ip] 
        
        case op.kind
        of OpInc:
            jc.memory[head] = jc.memory[head] + uint8(op.operand)
            ip += 1
            
        of OpDec:
            jc.memory[head] = jc.memory[head] - uint8(op.operand)
            ip += 1
            
        of OpLeft:
            if head < op.operand:
                stderr.write("RUNTIME ERROR: Unable to shift to cells on left!\n")
                echo "op.operand:" & $op.operand, " head:" & $head
                return 
            head -= op.operand
            ip += 1

        of OpRight:
            head += op.operand
            ip += 1

        of OpInput:
            let input_char = stdin.readChar()
            jc.memory[head] = uint8(ord(input_char))
            ip += 1

        of OpOutput:
            let output_char = char(jc.memory[head])
            # Optimized: Use repeat for multiple outputs
            stdout.write(repeat(output_char, op.operand))
            ip += 1

        of OpJmpIfZero:
            if jc.memory[head] == 0:
                ip = op.operand
            else:
                ip += 1
        
        of OpJmpIfNonZero:
            if jc.memory[head] != 0:
                ip = op.operand
            else:
                ip += 1

# Optimized: More efficient initialization
proc init_jit_compiler*(fileName: string): JitCompiler =
    var compiler: JitCompiler
    compiler.addr_stack = @[]
    compiler.ops = @[]
    
    # Optimized: Use standard Brainfuck memory size
    compiler.memory = newSeq[uint8](30000)
    
    compiler.load_file(fileName)
    return compiler

# Optimized: Simple completion check
func is_done(jc: JitCompiler): bool = 
    not jc.has_error and jc.at_end()