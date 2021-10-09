!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux
!
SYSSIZE = 0x3000
!
!	bootsect.s		(C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
! iself out of the way to address 0x90000, and jumps there.
!
! It then loads 'setup' directly after itself (0x90200), and the system
! at 0x10000, using BIOS interrupts. 
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no
! problem, even in the future. I want to keep it simple. This 512 kB
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
!
! The loader has been made as simple as possible, and continuos
! read errors will result in a unbreakable loop. Reboot by hand. It
! loads pretty fast by getting whole sectors at a time whenever possible.

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text ! 文本段
begtext:
.data ! 数据段
begdata:
.bss ! 未初始化的数据段
begbss:
.text

SETUPLEN = 4				! nr of setup-sectors
BOOTSEG  = 0x7c00			! boot-sector的起始地址
INITSEG  = 0x9000			! 将boot移动的目标地址
SETUPSEG = 0x9020			! setup starts here
SYSSEG   = 0x1000		    ! 系统加载地址 0x10000 (65536).
ENDSEG   = SYSSEG + SYSSIZE		! where to stop loading

! ROOT_DEV:	0x000 - same type of floppy as boot.
!		0x301 - first partition on first drive etc
ROOT_DEV = 0x306

entry _start ! 程序入口
_start:
	mov	ax,#BOOTSEG
	mov	ds,ax
	mov	ax,#INITSEG
	mov	es,ax
	mov	cx,#256 ! 控制后面 rep movw 移动的数据量
	sub	si,si
	sub	di,di
	rep 
	movw
	jmpi	go,INITSEG ! 跳转后再从 go 处执行
go:	mov	ax,cs
	mov	ds,ax
	mov	es,ax
! 将堆栈区放在 0x9ff00.
	mov	ss,ax
	mov	sp,#0xFF00		! arbitrary value >>512

! 加载 setup 模块
! es=0x90000

load_setup: ! 将2扇区开始的4个扇区，读取到内存0x90200位置
	mov	dx,#0x0000		! drive 0, head 0
	mov	cx,#0x0002		! sector 2, track 0
	mov	bx,#0x0200		! address = 512, in INITSEG
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors
	int	0x13			! read it
	jnc	ok_load_setup		! ok - continue
	mov	dx,#0x0000
	mov	ax,#0x0000		! reset the diskette
	int	0x13
	j	load_setup

ok_load_setup:

! 获取磁盘驱动的参数, specifically nr of sectors/track

	mov	dl,#0x00
	mov	ax,#0x0800		! AH=08H是获取驱动参数
	int	0x13
	mov	ch,#0x00
	seg cs
	mov	sectors,cx
	mov	ax,#INITSEG
	mov	es,ax

! 打印信息

	mov	ah,#0x03		! 读取光标位置
	xor	bh,bh           ! bh=显示页码
	int	0x10
	
	mov	cx,#24			! 显示字符串长度
	mov	bx,#0x0007		! 第0页, 属性7 (普通属性)
	mov	bp,#msg1        ! 字符串偏移地址
	mov	ax,#0x1301		! 显示字符串，光标位置改变
	int	0x10

! 加载系统 (地址在 0x10000)

	mov	ax,#SYSSEG
	mov	es,ax
	call	read_it
	call	kill_motor

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.

	seg cs
	mov	ax,root_dev
	cmp	ax,#0
	jne	root_defined
	seg cs
	mov	bx,sectors
	mov	ax,#0x0208		! /dev/ps0 - 1.2Mb
	cmp	bx,#15
	je	root_defined
	mov	ax,#0x021c		! /dev/PS0 - 1.44Mb
	cmp	bx,#18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:

	jmpi	0,SETUPSEG

! This routine loads the system at address 0x10000, making sure
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can.
!
! in:	es - starting address segment (normally 0x1000)
!
sread:	.word 1+SETUPLEN	! sectors read of current track
head:	.word 0			! current head
track:	.word 0			! current track

read_it:
	mov ax,es
	test ax,#0x0fff     ! test 以比特位逻辑与两个操作数
die:	jne die			! es 必须在 64kB 边界
	xor bx,bx	 		! bx 是段内的开始地址
rp_read:
	mov ax,es
	cmp ax,#ENDSEG		! 是否以及加载全部数据
	jb ok1_read			! 没有结束，跳转
	ret
ok1_read:
	seg cs
	mov ax,sectors      ! 取每个磁道扇区数
	sub ax,sread		! 减去当前磁道已读扇区数
	mov cx,ax			! 当前未读扇区数
	shl cx,#9			! cx = cx * 512 + 段内偏移
	add cx,bx
	jnc ok2_read        ! 如果未产生进位(即未超过64kB)则跳转
	je ok2_read
	xor ax,ax
	sub ax,bx			! 计算读完此段需要的偏移
	shr ax,#9			! 计算偏移对于的扇区数，保存在al
ok2_read:
	call read_track		! 读扇区
	mov cx,ax			! al该次操作读取的扇区数
	add ax,sread		! 已经读取的总扇区数
	seg cs
	cmp ax,sectors		! 是否还有扇区未读
	jne ok3_read		! 还有扇区未读，则跳转
	mov ax,#1
	sub ax,head			! 当前是否是1磁头
	jne ok4_read		! 是0磁头，则跳转去读1磁头
	inc track			! 读下一磁道(ax = 0)
ok4_read:
	mov head,ax			! 保存待读磁头号
	xor ax,ax
ok3_read:
	mov sread,ax        ! ax保存当前磁道已读的总扇区数
	shl cx,#9			! 上次读取的扇区数
	add bx,cx			
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read

read_track:				! 读从 sread已读扇区后的 al 个扇区
	push ax
	push bx
	push cx
	push dx
	mov dx,track		! 取当前磁道号
	mov cx,sread		! 取当前磁道上已读扇区数
	inc cx				! cl = 开始扇区
	mov ch,dl			! ch = 柱面号
	mov dx,head			! 取当前磁头号
	mov dh,dl			! dh = 磁头号
	mov dl,#0			! dl = 驱动器号
	and dx,#0x0100		! 磁头号不大于1
	mov ah,#2			! 读扇区
	int 0x13
	jc bad_rt			! 如果出错，则跳转
	pop dx
	pop cx
	pop bx
	pop ax
	ret
bad_rt:	mov ax,#0 		! ah = 0：系统复位
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track		! 重新读数据

!/*
! * This procedure turns off the floppy drive motor, so
! * that we enter the kernel in a known state, and
! * don't have to worry about it later.
! */
kill_motor:				! 关闭软驱马达
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
