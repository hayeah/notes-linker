Notes are using linkers and inspecting binary object files.

# Interacting with Compiled Object File

Given a simple hello world:

```c
static char *name = "howard";
int main() {
  printf("hello %s!",name);
  return 0;
}
```

Compile it:

```
cc main.c
```

And examine its linked libraries:

```
> otool -L main
main:
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1197.1.1)
```

Can also list the libraries that `libSystem` links against:

```
> otool -L /usr/lib/libSystem.B.dylib
/usr/lib/libSystem.B.dylib:
        /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1197.1.1)
        /usr/lib/system/libcache.dylib (compatibility version 1.0.0, current version 62.0.0)
        /usr/lib/system/libcommonCrypto.dylib (compatibility version 1.0.0, current version 60049.0.0)
        /usr/lib/system/libcompiler_rt.dylib (compatibility version 1.0.0, current version 35.0.0)
        /usr/lib/system/libcopyfile.dylib (compatibility version 1.0.0, current version 103.92.1)
        /usr/lib/system/libcorecrypto.dylib (compatibility version 1.0.0, current version 1.0.0)
        /usr/lib/system/libdispatch.dylib (compatibility version 1.0.0, current version 339.92.1)
        /usr/lib/system/libdyld.dylib (compatibility version 1.0.0, current version 239.4.0)
        /usr/lib/system/libkeymgr.dylib (compatibility version 1.0.0, current version 28.0.0)
        /usr/lib/system/liblaunch.dylib (compatibility version 1.0.0, current version 842.92.1)
        /usr/lib/system/libmacho.dylib (compatibility version 1.0.0, current version 845.0.0)
        /usr/lib/system/libquarantine.dylib (compatibility version 1.0.0, current version 71.0.0)
        /usr/lib/system/libremovefile.dylib (compatibility version 1.0.0, current version 33.0.0)
        /usr/lib/system/libsystem_asl.dylib (compatibility version 1.0.0, current version 217.1.4)
        /usr/lib/system/libsystem_blocks.dylib (compatibility version 1.0.0, current version 63.0.0)
        /usr/lib/system/libsystem_c.dylib (compatibility version 1.0.0, current version 997.90.3)
        /usr/lib/system/libsystem_configuration.dylib (compatibility version 1.0.0, current version 596.15.0)
        /usr/lib/system/libsystem_dnssd.dylib (compatibility version 1.0.0, current version 522.92.1)
        /usr/lib/system/libsystem_info.dylib (compatibility version 1.0.0, current version 449.1.3)
        /usr/lib/system/libsystem_kernel.dylib (compatibility version 1.0.0, current version 2422.115.4)
        /usr/lib/system/libsystem_m.dylib (compatibility version 1.0.0, current version 3047.16.0)
        /usr/lib/system/libsystem_malloc.dylib (compatibility version 1.0.0, current version 23.10.1)
        /usr/lib/system/libsystem_network.dylib (compatibility version 1.0.0, current version 241.3.0)
        /usr/lib/system/libsystem_notify.dylib (compatibility version 1.0.0, current version 121.20.1)
        /usr/lib/system/libsystem_platform.dylib (compatibility version 1.0.0, current version 24.90.1)
        /usr/lib/system/libsystem_pthread.dylib (compatibility version 1.0.0, current version 53.1.4)
        /usr/lib/system/libsystem_sandbox.dylib (compatibility version 1.0.0, current version 278.11.1)
        /usr/lib/system/libsystem_stats.dylib (compatibility version 1.0.0, current version 93.90.3)
        /usr/lib/system/libunc.dylib (compatibility version 1.0.0, current version 28.0.0)
        /usr/lib/system/libunwind.dylib (compatibility version 1.0.0, current version 35.3.0)
        /usr/lib/system/libxpc.dylib (compatibility version 1.0.0, current version 300.90.2)
```

Use `nm` to view the object's symbols:

```
> nm main
0000000100000000 T __mh_execute_header
0000000100000f30 T _main
0000000100001018 d _name
                 U _printf
                 U dyld_stub_binder
```

+ `T` is a symbol in the text section (i.e. code)
  + `t` if the symbol is only visible within this file.
+ `D` is a symbol in the data section (i.e. constants)
+ `U` is an undefined symbol to be resolved at runtime.
+ The number in the first column is the addresses of the symbols.

By convention, C symbols are prefixed with `_`.

Invoke nm with `-g` flag to see only extern symbols:

```
nm -g main
0000000100000000 T __mh_execute_header
0000000100000f30 T _main
                 U _printf
                 U dyld_stub_binder
```

To dump the text section and dissassemble:

```
> otool -Vt main
main:
(__TEXT,__text) section
_main:
0000000100000f30        pushq   %rbp
0000000100000f31        movq    %rsp, %rbp
0000000100000f34        subq    $0x10, %rsp
0000000100000f38        leaq    0x47(%rip), %rdi        ## literal pool for: "hello %s!"
0000000100000f3f        movl    $0x0, -0x4(%rbp)
0000000100000f46        movq    _name(%rip), %rsi
0000000100000f4d        movb    $0x0, %al
0000000100000f4f        callq   0x100000f64             ## symbol stub for: _printf
0000000100000f54        movl    $0x0, %ecx
0000000100000f59        movl    %eax, -0x8(%rbp)
0000000100000f5c        movl    %ecx, %eax
0000000100000f5e        addq    $0x10, %rsp
0000000100000f62        popq    %rbp
0000000100000f63        retq
```

+ `t` - print the text section.
+ `V` - verbose dissassembly.

### Objective C Specifics.

Compiled ObjC has enough information to reconstruct the interfaces. You can see private APIs:

```
class-dump /System/Library/Frameworks/AppKit.framework/AppKit
```

+ otx. better annotation of disassembled code with objc message names.
+ browser interface for otx: https://github.com/smorr/Mach-O-Scope

# Combining Object Files

```c
// hasmath.c
int main() {
  printf("I has math. 2 + 2 is = %d\n", plus(4));
}
```

We can produce an object file for `hasmath.c`:

```
cc -c hasmath.c
```

It'd produce warnings about printf and plus not defined. We can ignore that. Looking at its symbols to confirm their absence:

```
nm hasmath.o
0000000000000080 s EH_frame0
000000000000003e s L_.str
0000000000000000 T _main
0000000000000098 S _main.eh
                 U _plus
                 U _printf
```

We need to provide these two functions by linking `hasmath.o` with other object files. First, let's try to produce the executable with missing symbols:

```
// ld produces executable by default
> ld hasmath.o -o hasmath
ld: warning: -macosx_version_min not specified, assuming 10.10
Undefined symbols for architecture x86_64:
  "_plus", referenced from:
      _main in hasmath.o
  "_printf", referenced from:
      _main in hasmath.o
  "start", referenced from:
     implicit entry/start for main executable
ld: symbol(s) not found for inferred architecture x86_64
```

+ `start` is from `crt1`, the program constructor that does some setup and tear down stuff before entering and exiting main.
+ `_printf` can be found in libSystem.
+ `_plus` by compiling `plus.c`

  ```
  // plus.c
  int plus(int a, int b) {
    return a + b;
  }
  ```

```
> ld -lcrt1.o -lSystem hasmath.o plus.o -o hasmath
```

Which should produce an executable that works:

```
./hasmath
I has math. 2 + 2 is = 4
```

More about crt1.o:

+ [crt0.o and crt1.o — What's the difference?](http://stackoverflow.com/questions/2709998/crt0-o-and-crt1-o-whats-the-difference)

## More Details About Hasmath

Looking at its symbols:

```
> nm hasmath
0000000000002058 S _NXArgc
0000000000002060 S _NXArgv
                 U ___keymgr_dwarf2_register_sections
0000000000002070 S ___progname
                 U __cthread_init_routine
0000000000001e20 t __dyld_func_lookup
0000000000001000 A __mh_execute_header
0000000000001d22 t __start
                 U _atexit
0000000000002068 S _environ
                 U _errno
                 U _exit
                 U _mach_init_routine
0000000000001e30 T _main
0000000000001e70 T _plus
                 U _printf
                 U dyld_stub_binder
0000000000001e0c t dyld_stub_binding_helper
0000000000001d00 T start
```

We see that some symbols remain unresolved, and some  are resolved:

+ `_exit`, `_errno`, etc are U
+ `start`, `_plus` are T

Looking back at the linker invokation:

```
> ld -lcrt1.o -lSystem hasmath.o plus.o -o hasmath
```

+ `crt1.o` and `plus.o` are static libraries. They get embedded into the binary.
+ `libSystem.dylib` is a dynamic library. Linker creates a load command in the binary.

  ```
  > otool -L hasmath
  hasmath:
          /usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1197.1.1)
  ```