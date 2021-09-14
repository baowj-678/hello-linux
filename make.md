# make

## Ubuntu版本

`Ubuntu 20.04.2 LTS`



## as86: Command not found

~~~shell
as86 -0 -a -o boot/bootsect.o boot/bootsect.s
make: as86: Command not found
make: *** [Makefile:94: boot/bootsect] Error 127
~~~

### 解决方法

~~~shell
sudo apt-cache search as86
sudo apt-get install bin86
~~~



## [Makefile:55: boot/head.o] Error 1

~~~shell
as86 -0 -a -o boot/bootsect.o boot/bootsect.s
ld86 -0 -s -o boot/bootsect boot/bootsect.o
as86 -0 -a -o boot/setup.o boot/setup.s
ld86 -0 -s -o boot/setup boot/setup.o
gcc -I./include -traditional -c boot/head.s
boot/head.s: Assembler messages:
boot/head.s:45: Error: unsupported instruction `mov'
boot/head.s:49: Error: unsupported instruction `mov'
boot/head.s:61: Error: unsupported instruction `mov'
boot/head.s:63: Error: unsupported instruction `mov'
boot/head.s:138: Error: invalid instruction suffix for `push'
boot/head.s:139: Error: invalid instruction suffix for `push'
boot/head.s:140: Error: invalid instruction suffix for `push'
boot/head.s:141: Error: invalid instruction suffix for `push'
boot/head.s:142: Error: invalid instruction suffix for `push'
boot/head.s:153: Error: invalid instruction suffix for `push'
boot/head.s:154: Error: invalid instruction suffix for `push'
boot/head.s:155: Error: invalid instruction suffix for `push'
boot/head.s:156: Error: you can't `push %ds'
boot/head.s:157: Error: you can't `push %es'
boot/head.s:163: Error: invalid instruction suffix for `push'
boot/head.s:165: Error: invalid instruction suffix for `pop'
boot/head.s:167: Error: you can't `pop %es'
boot/head.s:168: Error: you can't `pop %ds'
boot/head.s:169: Error: invalid instruction suffix for `pop'
boot/head.s:170: Error: invalid instruction suffix for `pop'
boot/head.s:171: Error: invalid instruction suffix for `pop'
boot/head.s:216: Error: unsupported instruction `mov'
boot/head.s:217: Error: unsupported instruction `mov'
boot/head.s:219: Error: unsupported instruction `mov'
make: *** [Makefile:55: boot/head.o] Error 1
~~~

### 原因

要用**`32`**位编译

### 解决方法

#### 查找所有Makefile文件

`find ./ -name Makefile`

![image-20210913231709658](D:\cpp\linux-0.11\.md\image-20210913231709658.png)

#### 修改所有Makefile文件

* 将**`AS  =as`**添加**`--32`**变成**`AS =as --32`**;
* 将**`CC`**的**`-mcpu`**修改为**`-march`**;
* 在**`CFLAGS`**后添加**`-m32`**;

![image-20210913224531952](D:\cpp\linux-0.11\.md\image-20210913224123741.png)

**修改为**：

~~~makefile
  7 AS86    =as86 -0 -a
  8 LD86    =ld86 -0
  9
 10 AS  =as --32
 11 LD  =ld
 12 LDFLAGS =-m elf_i386 -Ttext 0 -e startup_32
 13 CC  =gcc -march=i386 $(RAMDISK)
 14 CFLAGS  =-Wall -m32 -O2 -fomit-frame-pointer
 15
 16 CPP =cpp -nostdinc -Iinclude
~~~



## static declaration of ‘fork’ follows non-static declaration

~~~shell
gcc -march=i386  -Wall -m32 -O2 -fomit-frame-pointer  \
-nostdinc -Iinclude -c -o init/main.o init/main.c
In file included from init/main.c:8:0:
init/main.c:23:29: error: static declaration of ‘fork’ follows non-static declaration
 static inline _syscall0(int,fork)
                             ^
include/unistd.h:134:6: note: in definition of macro ‘_syscall0’
 type name(void) \
      ^~~~
include/unistd.h:210:5: note: previous declaration of ‘fork’ was here
 int fork(void);
     ^~~~
init/main.c:24:29: error: static declaration of ‘pause’ follows non-static declaration
 static inline _syscall0(int,pause)
                             ^
include/unistd.h:134:6: note: in definition of macro ‘_syscall0’
 type name(void) \
      ^~~~
include/unistd.h:224:5: note: previous declaration of ‘pause’ was here
 int pause(void);
     ^~~~~
init/main.c:26:29: error: static declaration of ‘sync’ follows non-static declaration
 static inline _syscall0(int,sync)
                             ^
include/unistd.h:134:6: note: in definition of macro ‘_syscall0’
 type name(void) \
      ^~~~
include/unistd.h:235:5: note: previous declaration of ‘sync’ was here
 int sync(void);
     ^~~~
init/main.c:104:6: warning: return type of ‘main’ is not ‘int’ [-Wmain]
 void main(void)  /* This really IS void, no error here. */
      ^~~~
make: *** [Makefile:36: init/main.o] Error 1
~~~

### 解决方法

**修改`init/main.c`文件**：删除**static**

![image-20210913225243596](D:\cpp\linux-0.11\.md\image-20210913225243596.png)

**修改后**：

~~~c
 23 inline _syscall0(int,fork)
 24 inline _syscall0(int,pause)
 25 inline _syscall1(int,setup,void *,BIOS)
 26 inline _syscall0(int,sync)
 27
 28 #include <linux/tty.h>
 29 #include <linux/sched.h>
~~~



## [Makefile:78: kernel/kernel.o] Error 2

~~~shell
(cd kernel; make)
make[1]: Entering directory '/home/baowj/linux/kernel'
ld -r -o kernel.o sched.o system_call.o traps.o asm.o fork.o panic.o printk.o vsprintf.o sys.o exit.o signal.o mktime.o
ld: vsprintf.o: in function `strcpy':
vsprintf.c:(.text+0x22b): multiple definition of `strcpy'; traps.o:traps.c:(.text+0x180): first defined here
ld: vsprintf.o: in function `strcat':
vsprintf.c:(.text+0x241): multiple definition of `strcat'; traps.o:traps.c:(.text+0x196): first defined here
ld: vsprintf.o: in function `strcmp':
vsprintf.c:(.text+0x264): multiple definition of `strcmp'; traps.o:traps.c:(.text+0x1b9): first defined here
ld: vsprintf.o: in function `strspn':
vsprintf.c:(.text+0x287): multiple definition of `strspn'; traps.o:traps.c:(.text+0x1dc): first defined here
ld: vsprintf.o: in function `strcspn':
vsprintf.c:(.text+0x2ba): multiple definition of `strcspn'; traps.o:traps.c:(.text+0x20f): first defined here
ld: vsprintf.o: in function `strpbrk':
vsprintf.c:(.text+0x2ed): multiple definition of `strpbrk'; traps.o:traps.c:(.text+0x242): first defined here
ld: vsprintf.o: in function `strstr':
vsprintf.c:(.text+0x320): multiple definition of `strstr'; traps.o:traps.c:(.text+0x275): first defined here
ld: vsprintf.o: in function `strlen':
vsprintf.c:(.text+0x353): multiple definition of `strlen'; traps.o:traps.c:(.text+0x2a8): first defined here
ld: vsprintf.o: in function `strtok':
vsprintf.c:(.text+0x36c): multiple definition of `strtok'; traps.o:traps.c:(.text+0x2c1): first defined here
ld: vsprintf.o: in function `memmove':
vsprintf.c:(.text+0x3ed): multiple definition of `memmove'; traps.o:traps.c:(.text+0x342): first defined here
ld: vsprintf.o: in function `memchr':
vsprintf.c:(.text+0x413): multiple definition of `memchr'; traps.o:traps.c:(.text+0x368): first defined here
ld: relocatable linking with relocations from format elf32-i386 (sched.o) to format elf64-x86-64 (kernel.o) is not supported
make[1]: *** [Makefile:32: kernel.o] Error 1
make[1]: Leaving directory '/home/baowj/linux/kernel'
make: *** [Makefile:78: kernel/kernel.o] Error 2
~~~

### 解决方法

将**`./kernel/Makefile`**第**32**行

![image-20210913232908096](D:\cpp\linux-0.11\.md\image-20210913232908096.png)

修改为：

~~~makefile
 31 kernel.o: $(OBJS)
 32     $(LD) -m  elf_i386 -r -o kernel.o $(OBJS)
 33     sync
 34
~~~



##  conflicting types for built-in function ‘strchr’ [-Wbuiltin-declaration-mismatch]

~~~shell
In file included from traps.c:13:0:
../include/string.h:128:22: warning: conflicting types for built-in function ‘strchr’ [-Wbuiltin-declaration-mismatch]
 static inline char * strchr(const char * s,char c)
                      ^~~~~~
../include/string.h:145:22: warning: conflicting types for built-in function ‘strrchr’ [-Wbuiltin-declaration-mismatch]
 static inline char * strrchr(const char * s,char c)
                      ^~~~~~~
../include/string.h:379:22: warning: conflicting types for built-in function ‘memchr’ [-Wbuiltin-declaration-mismatch]
 extern inline void * memchr(const void * cs,char c,int count)
                      ^~~~~~
../include/string.h:395:22: warning: conflicting types for built-in function ‘memset’ [-Wbuiltin-declaration-mismatch]
 static inline void * memset(void * s,char c,int count)
                      ^~~~~~
~~~

### 解决方法

将**`./kernel/Makefile`**的**`CFLAGS`**添加**`-fno-builtin`**：

![image-20210913234435301](D:\cpp\linux-0.11\.md\image-20210913234435301.png)

修改为：

~~~makefile
CC  =gcc -march=i386
CFLAGS  =-Wall -fno-builtin -m32 -O -fstrength-reduce -fomit-frame-pointer \
    -finline-functions -nostdinc -I../include
CPP =gcc -E -nostdinc -I../include
~~~

