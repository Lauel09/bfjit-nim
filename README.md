# Idea
Implementation of bfjit from tsoding's stream.

# Roadmap
1. Interpreter: Currently the default is interpreter. [DONE]
2. JIT Compiler: Converts to Higher level representation, and then compiles to to binary [NOT DONE]

# Intention
To learn Nim lang, and see what else I can do with it.

# Final views
- Beautiful language, lost philosophy
- tries to be so much, fails to understand what it is
- Incredibly fast compiler, and stable
- Extremely small size binary in both statically and dynamically linked.
- Fails to find a problem statement and fit into it.
- Weird naming syntax. Majority of Python, C, and C++ programmer prefer snake_case
- Case insensitivity not needed.
- Standard Library should be available to non-gc people too. So if I opt for disabling GC, it *should* be available.
- Extremely well integration with the C, C++, also with windows in General.
- Very fast compile time
- Structs and their methods could have been handled in a better manner.
  It should have ideally been: 
  ```nim
  
    type JitCompiler:
        a: a_type
        b: b_type
        c: c_type

        proc new(var self, file_path: string): JitCompiler = 
            # function declaration here  

   ```
  This allows for a better understanding of where does the one methods live. Maybe this suggestion could be bad.

# License
MIT
