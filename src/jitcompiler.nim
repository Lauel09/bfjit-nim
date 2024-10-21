import os, strutils
import std/syncio
import options, sequtils

type 
    OpKind = enum 
        OpInc, OpDec, OpLeft, OpRight, OpInput, OpOutput, OpJmpIfZero, OpJmpIfNonZero

proc from_char(character: char): Option[OpKind] = 
    case character  
        of '+': some(OpInc)
        of '-': some(OpDec)
        of '<': some(OpLeft)
        of '>': some(OpRight)
        of ',': some(OpInput)
        of '.': some(OpOutput)
        of '[': some(OpJmpIfZero)
        of ']': some(OpJmpIfNonZero)
        else: 
            none(OpKind)

proc to_char(op: OpKind): char = 
    case op
        of OpInc: '+'
        of OpDec: '-'
        of OpLeft: '<'
        of OpRight: '>'
        of OpInput: ','
        of OpOutput: '.'
        of OpJmpIfZero: '['
        of OpJmpIfNonZero: ']'

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

        memory: seq[int] 
        addr_stack: seq[int]
        content: string
        abs_fpath: string
        current: int
        has_error: Option[Error] 
        ops: seq[Op]

proc peek(jc: var JitCompiler): char = 

    if jc.current + 1 < jc.content.len() and jc.has_error.isNone():
        return jc.content[jc.current + 1]
    else:
        return '\0'

proc is_cmd(jc: JitCompiler, token: char): bool =
    ## Check if the token is a BF command
    if from_char(token).isSome():
        return true
    else:
        return false
    
func at_end(jc: JitCompiler): bool =
    return jc.current >= jc.content.len()

proc advance(l: var JitCompiler): char =

    while not l.at_end() and not l.is_cmd(l.peek()):
        l.current += 1
    
    if not l.at_end():
        l.current += 1
        result = l.content[l.current]
    else:
        result = '\0'

proc scan_token(jc: var JitCompiler) =  

    while jc.current < jc.content.len() and jc.has_error.isNone():
        var cur_char = jc.content[jc.current]
        case cur_char 
            of '+', '-', '.', ',', '>', '<':
                var count = 1
                let convert = from_char(cur_char)
                var op_kind: OpKind

                if convert.isNone():
                    jc.has_error = some(
                        Error(
                            what: "Invalid character:" & cur_char,
                            pos: jc.current
                        )
                    )
                else:
                    op_kind = convert.get()

                while jc.peek() == cur_char:
                    count += 1
                    cur_char = jc.advance()

                jc.ops.add(Op(kind: opKind, operand: count))
                cur_char = jc.advance()

            of '[':
                const op_obj = Op(
                    kind: OpJmpIfZero,
                    operand: 0
                )

                let address = jc.ops.len()
                #  0 1 2 3 4 5
                #  [ + + + + ]                
                jc.addr_stack.add(address)
                jc.ops.add(op_obj)
 
                cur_char = jc.advance()

            of ']':

                if jc.addr_stack.len() == 0:
                    # You can't have a closing bracket without an opening bracket
                    # before it
                    jc.has_error = some(
                        Error(
                            what: "']' encountered without an '[' before it \n Unbalanced loop!",
                            pos: jc.current
                        )
                    )
                else:

                    let open_brck_add = jc.addr_stack.pop()
                
                    let close_brck_obj = Op(
                        kind: OpJmpIfNonZero,
                        operand: open_brck_add,
                    )
                    jc.ops.add(close_brck_obj)

                    jc.ops[open_brck_add].operand = jc.ops.len() 
                    
                cur_char = jc.advance()

            else:
                cur_char = jc.advance()



proc load_file(c: var JitCompiler, file_name: string) =
    try:
        if file_exists(fileName):
            let abs_fpath = absolutePath(fileName)
            let content = syncio.readFile(abs_fpath).strip()
            
            c.content = content
            c.abs_fpath =abs_fpath 
            c.current = 0
            c.has_error = none(Error)
            echo c.content
        else:
            stdout.write("File does not exist! Exiting!\n")
            
    except Exception as e:
        debugEcho(e.astToStr())

proc to_string*(jc: JitCompiler): string =
    result  = "JitCompiler: {\n"
    result.add("    abs_fpath: " & jc.abs_fpath & "\n")
    result.add("    addr_stack: " & $jc.addr_stack & "\n")
    result.add("    content: " & $jc.current & "\n")
    result.add("    has_error: " & $jc.has_error & "\n")
    result.add("    ops: " & $jc.ops & "\n")
    result.add("}\n")


proc scan_tokens*(jc: var JitCompiler) = 
    jc.scan_token()
    if jc.has_error.isSome():
        let value = jc.has_error.get()
        stderr.write("[ERROR] - ", value.what, " at: ", value.pos, "\n")

proc compile*(jc: var JitCompiler) =  
    echo "Compiling..."
    jc.scan_tokens()

    # Executing through the memory
    var 
        head = 0
        ip = 0
    # (ip, value)
    while ip < jc.ops.len():
        let op = jc.ops[ip] 
        # check current Op
        case op.kind
        of OpInc:
            # the value at the current head is incremented
            # by one
            jc.memory[head] += op.operand
            ip += 1
        of OpDec:
            # the value at the current head is decremented
            # by one
            jc.memory[head] -= op.operand
            
            ip += 1
        of OpLeft:
            # this moves the memory cell number to the left
            if head < op.operand:
                # you are asking to move left more than there
                # is space to move left for each '<' moves the
                # cell to the left
                stderr.write("RUNTIME ERROR: Unable to shift to cells on left!\n")
                echo "op.operand:" & $op.operand, " head:" & $head
                let current = jc.current
                #let error_string = jc.content[(jc.current - 5) .. (jc.current+5 )]
                echo "Error string:", jc.content.len()
                return 
            
            head -= op.operand
        
            ip += 1

        of OpRight:
            # this operation moves the cells to the right
            head += op.operand
            ip += 1

        of OpInput:

            let input_char = stdin.readChar()
            jc.memory[head] = cast[int](input_char)
            ip += 1

        of OpOutput: # '.'
            # get the value at the HEAD and print it
            #stdout.write(jc.ops[head])
            # Value has to be printed from the memory rather than
            # the ops!
            let output_char = cast[char](jc.memory[head])
            
            # this code without a loop wouldn't print the ".." as according to 
            # the IR we capture it as Op(kind: OpOutput, operand: 2)

            # how to resolve the issue of double "."
            # or ".."?

            # ps: countup is inclusive
            for n_op_output in countup(0, op.operand - 1):
                stdout.write(output_char)
            ip += 1

        of OpJmpIfZero:
            # the value at the current head
            let cur_head_value = jc.memory[head]

            if cur_head_value == 0:
                # the position of the operation we have
                # to make a jump on
                ip = op.operand

            else:
                ip += 1
        
        of OpJmpIfNonZero:
            let cur_head_value = jc.memory[head]

            if  cur_head_value != 0:
                # operand is the number of jumps it to has
                # to make back
                ip = op.operand
            else:
                ip += 1
        
    
proc init_jit_compiler*(fileName: string): JitCompiler =
    var compiler: JitCompiler
    compiler.addr_stack = @[]
    compiler.ops = @[]

    # Bf memory layout of linear 1024 cells
    compiler.memory = newSeq[int](4028)

    compiler.load_file(fileName)
    return compiler

func is_done(jc: JitCompiler): bool = 
    ## No error and we have reached the end
    return jc.has_error.isNone() and jc.at_end()
