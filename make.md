# Make出现的问题

## 编译环境

#### Ubuntu版本

`Ubuntu 20.04.2 LTS`

#### GCC版本

`gcc version 7.5.0 (Ubuntu 7.5.0-6ubuntu2)`



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

![image-20210913231709658](.md/image-20210913231709658.png)

#### 修改所有Makefile文件

* 将**`AS  =as`**添加**`--32`**变成**`AS =as --32`**;
* 将**`CC`**的**`-mcpu`**修改为**`-march`**;
* 在**`CFLAGS`**后添加**`-m32`**;

![image-20210913224531952](.md/image-20210913224123741.png)

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

![image-20210913225243596](.md/image-20210913225243596.png)

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

![image-20210913232908096](.md/image-20210913232908096.png)

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

![image-20210913234435301](.md/image-20210913234435301.png)

修改为：

~~~makefile
CC  =gcc -march=i386
CFLAGS  =-Wall -fno-builtin -m32 -O -fstrength-reduce -fomit-frame-pointer \
    -finline-functions -nostdinc -I../include
CPP =gcc -E -nostdinc -I../include
~~~



## vsprintf.c:(.text+0x413): multiple definition of `memchr'; traps.o:traps.c:(.text+0x368): first defined here make: *** [Makefile:32: kernel.o] Error 1
~~~shell
ld -m elf_i386 -r -o kernel.o sched.o system_call.o traps.o asm.o fork.o panic.o printk.o vsprintf.o sys.o exit.o signal.o mktime.o
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
make: *** [Makefile:32: kernel.o] Error 1
~~~

### 解决方法

把`./include/string.h`中的**extern**关键字全部改成**static**：

![image-20210920165651875](.md/image-20210920165651875.png)



## ld: relocatable linking with relocations from format elf32-i386 (memory.o) to format elf64-x86-64 (mm.o) is not supported
~~~shell
ld: relocatable linking with relocations from format elf32-i386 (memory.o) to format elf64-x86-64 (mm.o) is not supported
make[1]: *** [Makefile:23: mm.o] Error 1
~~~

### 解决方法

在`./mm/Makefile`第**23**行**ld**命令添加**-m elf_i386**选项；

![image-20210920170258652](.md/image-20210920170258652.png)

在`./fs/Makefile`第**23**行**ld**命令添加**-m elf_i386**选项；

![image-20210920171823512](.md/image-20210920171823512.png)





## exec.c:139:44: error: lvalue required as left operand of assignment

~~~shell
exec.c: In function ‘copy_strings’:
exec.c:139:44: error: lvalue required as left operand of assignment
         !(pag = (char *) page[p/PAGE_SIZE] =
                                            ^
make[1]: *** [Makefile:13: exec.o] Error 1
~~~

### 解决方法

在`.fs/exec.c`文件的第**139行**添加**括号**

![image-20210920171433534](.md/image-20210920171433534.png)



## tty_io.c:160:6: note: in expansion of macro ‘tolower’

~~~shell
tty_io.c: In function ‘copy_to_cooked’:
../../include/ctype.h:25:31: warning: array subscript has type ‘char’ [-Wchar-subscripts]
 #define isupper(c) ((_ctype+1)[c]&(_U))
                               ^
../../include/ctype.h:31:29: note: in expansion of macro ‘isupper’
 #define tolower(c) (_ctmp=c,isupper(_ctmp)?_ctmp-('A'-'a'):_ctmp)
                             ^~~~~~~
tty_io.c:160:6: note: in expansion of macro ‘tolower’
    c=tolower(c);
      ^~~~~~~
tty_io.c: In function ‘tty_write’:
../../include/ctype.h:21:31: warning: array subscript has type ‘char’ [-Wchar-subscripts]
 #define islower(c) ((_ctype+1)[c]&(_L))
                               ^
../../include/ctype.h:32:29: note: in expansion of macro ‘islower’
 #define toupper(c) (_ctmp=c,islower(_ctmp)?_ctmp-('a'-'A'):_ctmp)
                             ^~~~~~~
tty_io.c:316:8: note: in expansion of macro ‘toupper’
      c=toupper(c);
        ^~~~~~~
~~~

### 解决方法

将`./include/ctype.h`第**16-26**行从：

![image-20210920180100421](.md/image-20210920180100421.png)

修改为：

~~~c
#define isalnum(c) (*(_ctype+1+c)&(_U|_L|_D))
#define isalpha(c) (*(_ctype+1+c)&(_U|_L))
#define iscntrl(c) (*(_ctype+1+c)&(_C))
#define isdigit(c) (*(_ctype+1+c)&(_D))
#define isgraph(c) (*(_ctype+1+c)&(_P|_U|_L|_D))
#define islower(c) (*(_ctype+1+c)&(_L))
#define isprint(c) (*(_ctype+1+c)&(_P|_U|_L|_D|_SP))
#define ispunct(c) (*(_ctype+1+c)&(_P))
#define isspace(c) (*(_ctype+1+c)&(_S))
#define isupper(c) (*(_ctype+1+c)&(_U))
#define isxdigit(c) (*(_ctype+1+c)&(_D|_X))
~~~



## malloc.c:156:46: error: lvalue required as left operand of assignment

~~~shell
malloc.c: In function ‘malloc’:
malloc.c:156:46: error: lvalue required as left operand of assignment
   bdesc->page = bdesc->freeptr = (void *) cp = get_free_page();
                                              ^
make[1]: *** [Makefile:24: malloc.o] Error 1
make[1]: Leaving directory '/home/baowj/linux/lib'
make: *** [Makefile:87: lib/lib.a] Error 2
~~~

### 解决方法

将`./lib/malloc.c`文件第**156**行由：

![image-20210920185441067](.md/image-20210920185441067.png)

修改为：

~~~c
150         if (!free_bucket_desc)
151             init_bucket_desc();
152         bdesc = free_bucket_desc;
153         free_bucket_desc = bdesc->next;
154         bdesc->refcnt = 0;
155         bdesc->bucket_size = bdir->size;
156         bdesc->page = bdesc->freeptr = (void *) (cp = get_free_page());
157         if (!cp)
158             panic("Out of memory in kernel malloc()");
~~~



## system_call.s:94: Warning: indirect call without `*'

~~~shell
make[1]: Entering directory '/home/baowj/linux/kernel'
gcc -march=i386 -Wall -fno-builtin -m32 -O -fstrength-reduce -fomit-frame-pointer -finline-functions -nostdinc -I../include \
-c -o sched.o sched.c
as --32 -o system_call.o system_call.s
system_call.s: Assembler messages:
system_call.s:94: Warning: indirect call without `*'
~~~

### 解决方法

将`./kernel/system_class.s`第**94**行，从

~~~c
call sys_call_table(,%eax,4)
~~~

修改为

~~~c
call *sys_call_table(,%eax,4)
~~~



## exec.c:139:45: warning: assignment makes integer from pointer without a cast [-Wint-conversion]
~~~shell
exec.c: In function ‘copy_strings’:
exec.c:139:45: warning: assignment makes integer from pointer without a cast [-Wint-conversion]
         !(pag = (char *) (page[p/PAGE_SIZE] =
                                             ^
~~~

### 解决方法

将`./fs/exec.c`文件的第**139**行，从：

~~~c
!(pag = (char *) (page[p/PAGE_SIZE] = (unsigned long *) get_free_page())))
~~~

修改为：

~~~c
!(pag = (char *) (page[p/PAGE_SIZE] = get_free_page())))
~~~



## ld: -f may not be used without -shared

~~~shell
ld -m elf_i386 -Ttext 0 -e startup_32 -fno-stack-protector -f boot/head.o init/main.o \
kernel/kernel.o mm/mm.o fs/fs.o \
kernel/blk_drv/blk_drv.a kernel/chr_drv/chr_drv.a \
kernel/math/math.a \
lib/lib.a \
-o tools/system
ld: -f may not be used without -shared
make: *** [Makefile:60: tools/system] Error 1
~~~

### 解决方法

将`./Makefile`第**60**行，从：

![image-20210930193709612](.md/image-20210930193709612.png)

修改为：

~~~makefile
 58 tools/system:   boot/head.o init/main.o \
 59         $(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS)
 60     $(LD) $(LDFLAGS) -shared boot/head.o init/main.o \
 61     $(ARCHIVES) \
 62     $(DRIVERS) \
 63     $(MATH) \
 64     $(LIBS) \
 65     -o tools/system
 66     nm tools/system | grep -v '\(compiled\)\|\(\.o$$\)\|\( [aU] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)'| sort > System.map
~~~



## warning: variable ‘qualifier’ set but not used [-Wunused-but-set-variable]

~~~shell
vsprintf.c: In function ‘vsprintf’:
vsprintf.c:107:6: warning: variable ‘qualifier’ set but not used [-Wunused-but-set-variable]
  int qualifier = 'h';  /* 'h', 'l', or 'L' for integer fields */
      ^~~~~~~~~
~~~

### 解决方法

删除`./kernel/vsprintf.c`中的**qualifier**变量。

