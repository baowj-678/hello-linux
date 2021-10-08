# bootsect.s

## 简介

**引导扇区**代码，`bootsect.s`会被**bios**启动进程加载到**0x7c00**，然后会将**bootsect**加载到**0x90000**，并跳转到此位置。

## 常用汇编

### jc

当运算产生进位标志时，即CF=1时，跳转到目标程序处；



## 系统中断

### 0x13

* **功能**：**BIOS**读磁盘扇区；
* **控制**：
    * **ah=00H**：磁盘系统复位；
    * **ah=01H**：读取磁盘系统状态；
    * **ah=02H**：
        * **al**：扇区数量；
        * **ch**：柱面号；
        * **cl**：开始扇区；
        * **dh**：磁头号；
        * **dl**：驱动器号；
        * **es:bx**：内存地址；
    * **ah=03H**：写扇区；
    * **ah=08H**：读取驱动器参数；

### [0x10](https://blog.csdn.net/hua19880705/article/details/8125706)

* **功能**：显示字符；
* **控制**：
    * **ah=00H**：设置显示器模式；
    * **ah=01H**：设置光标形状；
    * **ah=02H**：设置光标位置；
    * **ah=03H**：读取光标位置；
    * **ah=13H**：在Teletype模式下显示字符串；
        * **bh**：页码；
        * **bl**：属性；
        * **cx**：字符串长度；
        * **es:bp**：显示字符串的地址；
