import os
import std/cmdline
import jitcompiler

when isMainModule:
    let count = cmdline.paramCount()
    if count > 0:
        let file_path = cmdline.commandLineParams()[0]
        var jit_compiler = init_jit_compiler(filePath)
        # run compilation
        jit_compiler.compile()
    else:
        stderr.write("Invalid number of arguments:", count,"\nUsage: ./main file_name\n")


