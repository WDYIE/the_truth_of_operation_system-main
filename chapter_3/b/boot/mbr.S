                                    ;主引导程序 
                                    ;------------------------------------------------------------
%include "boot.inc"
SECTION MBR vstart=0x7c00         
    mov ax,cs      
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

                                    ; 清屏
                                    ;利用0x06号功能，上卷全部行，则可清屏。
                                    ; -----------------------------------------------------------
                                    ;INT 0x10   功能号:0x06	   功能描述:上卷窗口
                                    ;------------------------------------------------------
                                    ;输入：
                                    ;AH 功能号= 0x06
                                    ;AL = 上卷的行数(如果为0,表示全部)
                                    ;BH = 上卷行属性
                                    ;(CL,CH) = 窗口左上角的(X,Y)位置
                                    ;(DL,DH) = 窗口右下角的(X,Y)位置
                                    ;无返回值：
    mov ax, 0600h
    mov bx, 0700h
    mov cx, 0                       ; 左上角: (0, 0)
    mov dx, 184fh		            ; 右下角: (80,25),
				                    ; 因为VGA文本模式中，一行只能容纳80个字符,共25行。
				                    ; 下标从0开始，所以0x18=24,0x4f=79
    int 10h                         ; int 10h

                                    ; 输出字符串:MBR
    mov byte [gs:0x00],'1'
    mov byte [gs:0x01],0xA4

    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0xA4

    mov byte [gs:0x04],'M'
    mov byte [gs:0x05],0xA4	        ;A表示绿色背景闪烁，4表示前景色为红色

    mov byte [gs:0x06],'B'
    mov byte [gs:0x07],0xA4

    mov byte [gs:0x08],'R'
    mov byte [gs:0x09],0xA4
	 
    mov eax,LOADER_START_SECTOR	    ; 起始扇区lba地址
    mov bx,LOADER_BASE_ADDR         ; 写入的地址
    mov cx,1			            ; 待读入的扇区数
    call rd_disk_m_16		        ; 以下读取程序的起始部分（一个扇区）
  
    jmp LOADER_BASE_ADDR
       
                                    ;-------------------------------------------------------------------------------
                                    ;功能:读取硬盘n个扇区
rd_disk_m_16:	   
                                    ;-------------------------------------------------------------------------------
				                    ; eax=LBA扇区号
				                    ; ebx=将数据写入的内存地址
				                    ; ecx=读入的扇区数
    mov esi,eax	                    ;备份eax
    mov di,cx		                ;备份cx
                                    ;读写硬盘:
                                    ;第1步：选择特定通道的寄存器，设置要读取的扇区数
    mov dx,0x1f2
    mov al,cl                       ;cx为1，cl则为1
    out dx,al                       ;读取的扇区数，0x1f2端口号对应Sector count寄存器。

    mov eax,esi	                    ;恢复ax

                                    ;第2步：在特定通道寄存器中放入要读取扇区的地址，将LBA地址存入0x1f3 ~ 0x1f6
                                    ;LBA地址7~0位写入端口0x1f3
    mov dx,0x1f3                    ;LBA low 寄存器 
    out dx,al                       ;在50行的时候，就将loader所在的硬盘lba地址存入exa了。

                                    ;LBA地址15~8位写入端口0x1f4
    mov cl,8                        
    shr eax,cl                       ;右移8位,因为7-0已经存入low寄存器了。
    mov dx,0x1f4                     ;LBA mid 寄存器 
    out dx,al

                                    ;LBA地址23~16位写入端口0x1f5
    shr eax,cl
    mov dx,0x1f5                     ;LBA high 寄存器 
    out dx,al

    shr eax,cl
    and al,0x0f	                    ;and 操作取低四位，lba第24~27位 lba28只有28位，
    or al,0xe0	                    ; 设置7～4位为1110,表示lba模式
    mov dx,0x1f6
    out dx,al

                                    ;第3步：向0x1f7端口写入读命令，0x20 
    mov dx,0x1f7
    mov al,0x20                        
    out dx,al

                                    ;第4步：检测硬盘状态
.not_ready:
                                    ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
    nop
    in al,dx
    and al,0x88	                    ;第4位为1表示硬盘控制器已准备好数据传输，第7位为1表示硬盘忙
    cmp al,0x08                     ;al-0x08 如果相等,ZF置位为1。JE可以调转。不相等，ZF置零，双重否定表示结果非零。
    jnz .not_ready	                ;不相等，若未准备好，继续等。

                                    ;第5步：从0x1f0端口读数据
    mov ax, di                      ;di当中存储的是要读取的扇区数，65行备份到di为1.
    mov dx, 256                     ;每个扇区512字节，一次读取两个字节，所以一个扇区就要读取256次，与扇区数相乘，就等得到总读取次数
    mul dx                          ;p133,dx16位，被乘数隐藏在ax中，乘积是32位的，高16位放在dx中，低16位放在ax中。
    mov cx, ax	                    ;结果256显然结果只影响了ax，cx用于控制循环次数。
    mov dx, 0x1f0
.go_on_read:
    in ax,dx                        ;磁盘准备好后，数据端口存放的为2个字节数据。
    mov [bx],ax                     ;[bx]表示bx所指向的地址，实模式下bx bp是基地址寄存器，用于基址寻址。
    add bx,2		                ;将地址往后摞动两个字节
    loop .go_on_read                ;LOOP指令会将CX寄存器的值减1，并将程序控制权转移到.go_on_read处执行，直到CX寄存器的值为0时结束循环
    ret                             ;函数rd_disk_m_16返回。

    times 510-($-$$) db 0
    db 0x55,0xaa