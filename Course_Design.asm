data segment
    file       db "C:\Einword.txt",0
    handle     dw ?
    str0       db "WELCOME!$"
    str1       db "Simple English-English Dictionary$"
    str2       db "Options：1.input, 2.delete, 3.search, 4.modify, 5.exit$"
    str3       db "explain:$"
    str4       db "synonym:$"
    str5       db "antonym:$"
    str6       db "An error occurred, please re-enter!$"
    str7       db "thank you!$ "
    input_hint db "please enter:$"
    searchhint db  "you might be looking for:$"
    error      db "no such word$"
    next_w     db "Please enter any key:$"
    now        dw 0                                   ;现在查找到的字母数
    count      dw 0                                   ;现在查找到的单词
    cnt        dw 0                                   ;现在已经储存的单词数
    maywnum    dw 0                                   ;此变量用于存储searchw的下一个空间指针
    word1      db 20   dup(" ")                       ;单词
    word2      db 40   dup(" ")                       ;解释
    word3      db 20   dup(" ")                       ;同义词
    word4      db 20   dup(" ")                       ;反义词
    word_add   db 100  dup(" ")                       ;一个单词的和
    words      db 4000 dup(" ")                       ;总的单词，已每个单词的内容定一个100行大小的空间  
    searchw    db 100  dup(" ")                       ;查找的可能查找单词
ends                  

stack segment
    dw   128  dup(0)
ends

code segment
start: 
    mov ax, data
    mov ds, ax
    mov es, ax
;--------------------------------------------------宏----------------------------------------------------;
;屏幕宏
   scroll macro cont, ulrow, ulcol, lrrow, lrcol, att ;清屏或上卷宏定义
        mov ah, 6                                     ;清屏或上卷
        mov al, cont                                  ;N=上卷行数，N=0清屏
        mov ch, ulrow                                 ;左上角行号
        mov cl, ulcol                                 ;左上角列号
        mov dh, lrrow                                 ;右下角行号
        mov dl, lrcol                                 ;右下角列号
        mov bh, att                                   ;卷入行属性
        int 10h
    endm
;置光标位置   
    curse macro y, x
        mov ah, 2                                     
        mov dh, y                                     ;行号
        mov dl, x                                     ;列号
        mov bh, 0                                     ;当前页
        int 10h
    endm 
;清除word_add宏
    clean macro 
        local loop1
        mov cx, 100
        mov word_add, 20h
        mov di, cx
        dec di
        loop1:
            mov word_add[di], 20h
            dec di
            loop loop1
    endm 
;单词转移宏
    word_transfer macro addr1，addr2，place           ;place表示放进去的位置
        local for
        push si
        push di
        push cx
        mov ah, 0ah                               
        lea dx, addr1
        int 21h
        mov ch, 0
        mov cl, addr1[1]                              ;多少个字母
        mov si, 2
        mov di, place
        for:
            push dx                                   ;转移到word_add
            mov dl, addr1[si]
            mov addr2[di], dl
            inc  si
            inc  di 
            pop  dx
            loop for 
        pop cx
        pop di
        pop si
     endm
;插入words宏
    words_insert macro loc, adr1, adr2
        local loop1,loop2                             ;loc表示第几个单词
        push si
        push di
        push cx
        push dx
        push ax
        mov  cx, 0
        mov  ax, 0
        mov  dx, 0 
        mov  ax, cnt                                  
        sub  ax, loc 
        cmp  ax, 0 
        jz add1                                       ;在尾部直接插入
        mov  dl, 64h                                  ;减去代表着将后面的向后移
        mov  cx, ax                                   ;此时ax表示要移动的单词数
        inc  cx
        mov  di, ax
        dec  di  
        loop1:
            mov  dl, adr2[di]                         ;向后移过程
            mov  adr2[di+100], dl
            dec  di
            loop loop1
        add1:                                         ;加入到插入前的准备
            mov  cx, 100 
            mov  si, 100
            mov  ax, loc 
            mov  bx, 100
            mul  bx
            add  si, ax
            mov  di, 100 
            inc  cx
            dec  di
            dec  si
        loop2:                                        ;插入循环
            mov  dl, adr1[di]
            mov  adr2[si], dl
            dec  di
            dec  si 
            loop loop2  
        pop  ax
        pop  dx
        pop  cx
        pop  di
        pop  si
    endm 
;输入宏
    word_input macro mark, place                             
        local loop1,loop2,loop3,loop4,exit     
        mov ax, mark    
        cmp ax, 1
            jz loop1                                  ;标志一为单词     
        cmp ax, 2
            jz loop2                                  ;标志二为解释     
        cmp ax, 3
            jz loop3                                  ;标志三为同义词       
        cmp ax, 4
            jz loop4                                  ;标志四为反义词
        loop1:
            word_transfer word1,word_add,place        ;输入单词
            jmp exit
        loop2:
            word_transfer word2,word_add,place        ;输入解释 
            jmp exit
        loop3:
            word_transfer word3,word_add,place        ;输入同义词
            jmp exit
        loop4:
            word_transfer word4,word_add,place        ;输入反义词
            jmp exit                                                                                
        exit:                                                       
    endm
;删除宏
    words_delete macro adr1,loc
        push si
        push di
        push cx
        push dx
        push ax
        mov  cx, 0
        mov  ax, 0
        mov  dx, 0  
        mov  ax, cnt                                  
        sub  ax, loc
        dec  ax
        mov  dx, 100                                  ;减去代表着将后面的向前移
        mul  dx
        mov  cx, ax                                   ;此时ax表示要移动的单词数
        mov  ax, loc
        mov  dx, 100
        mul  dx
        mov  di, ax  
        loop1:
            mov  dl, adr1[di+100]                     ;向前移过程
            mov  adr1[di], dl
            inc  di
            loop loop1 
        sub12:                                        ;加入到删除前的准备
            mov  cx, 100
            mov  ax, cnt 
            dec  ax
            mov  bx, 100
            mul  bx
            mov  di, ax 
        loop2:                                        ;最后100个删除循环
            mov  adr1[di], 20h
            inc  di 
            loop loop2
        pop  ax
        pop  dx
        pop  cx
        pop  di
        pop  si
    endm
;查找输出宏,在words中，从第count个开始输出100个
    words_search macro adr1,loc 
        local loop1,loop2,loop3
        push si
        push di
        push cx
        push dx
        push ax
        call print_show
        mov  ax, loc
        mov  dx, 100
        mul  dx
        mov  dx, 0
        mov  cx, 40
        mov  di, ax
        add  di, 20
        curse 12, 12 
        loop1:
            mov  dl, adr1[di]
            mov  ah,2
            int 21h
            inc di
            loop loop1
        curse 18, 12 
        mov  cx, 20
        loop2:
            mov  dl, adr1[di]
            mov  ah,2
            int 21h
            inc di
            loop loop2
        curse 18, 51 
        mov  cx, 20
        loop3:
            mov  dl, adr1[di]
            mov  ah,2
            int 21h
            inc di
            loop loop3
        pop  ax
        pop  dx
        pop  cx
        pop  di
        pop  si
    endm
;--------------------------------------------------主函数--------------------------------------------------;
;创建文件层 
    import:
        ;mov ah, 3ch                                   ;新建文件，已经在C:\emu8086\emu8086\vdrive文件夹创建
        ;mov cx, 0
        ;lea dx, file                         
        ;int 21h
        mov al, 0                                     ;打开方式为写
        mov ah, 3DH                                   ;打开文件
        lea dx, file
        int 21h
        mov handle, ax                                ;保存文件码
        mov ah, 3FH                                   ;读取文件
        mov bx, handle                                ;将文件代号传送至bx
        mov cx, 4000
        lea dx, words                                 ;数据缓冲区地址 
        int 21h      
        mov bx, handle                                ;将文件代号传送至bx
        mov ah, 3EH                                   ;关闭文件
        int 21h
;定义屏幕界面
    screen:                                           
        scroll 0,  0,  0,  24, 79,  05h               ;清屏
        scroll 25, 0,  0,  24, 79,  71h               ;开外窗口，白色底
        scroll 23, 1,  1,  3,  78,  21h               ;最顶层框
        scroll 23, 5,  1,  9,  78,  21h               ;输入层
        scroll 23, 11, 1,  23，78,  21h               ;单词层，字体蓝色 
;判断多少字
   words_num:
        mov  di, 0  
        mov  cx, 40
        loopf:
            mov  al, words[di]
            cmp  al, 20h
            jz init
            inc cnt
            add di, 100
            loop loopf 
;显示简易英英字典
    init:
        curse 2, 23
        mov ah, 09h                                   
        lea dx, str1
        int 21h
        curse 7, 4     
        mov ah, 09h                                   ;显示选择消息
        lea dx, str2
        int 21h
        scroll 23, 11, 1,  23，78,  21h               ;单词层，字体蓝色 
        curse 15, 35
        mov ah, 09h                                   ;显示注释
        lea dx, str0
        int 21h 
;开始   
     begin:
        curse 7,  60
        mov ah, 0                                     ;读入选择
        int 16h                                           
        mov ah, 0eh                                   ;显示输入的字符
        int 10h
        cmp al, 49                                    ;选一输入
        jz input
        cmp al, 50                                    ;选二删除
        jz delete
        cmp al, 51                                    ;选三查找
        jz search                                     
        cmp al, 52                                    ;选四修改
        jz modify                                     
        cmp al, 53                                    ;选五退出
        jz exit
        scroll 23, 5, 1, 9, 78, 21h                   ;清空
        curse 7, 4  
        mov ah, 09h
        lea dx, str6                                  ;选其他错误
        int 21h
        mov ah, 0
        int 16h                                         
        curse 7, 4                                    ;重新输入
        mov ah, 09h                                  
        lea dx, str2
        int 21h
        jmp begin
;输入函数
     input:                                           
        call clear
        call print_show
        curse 7, 20
        word_input 1, 0
        curse 12, 12
        word_input 2, 20
        curse 18, 12
        word_input 3, 60
        curse 18, 51
        word_input 4, 80                              ;将所有东西输入完
        call word_insert
        mov ax, cnt
        add ax, 1                                     ;将cnt加一，其他清零
        mov cnt, ax
        mov now,  0
        mov count,0
        clean
        jmp init
;删除函数         
     delete:                                          
        call clear
        call print_show
        curse 7, 20
        mov ah, 0ah                               
        lea dx, word1
        int 21h
        call word_delete
        delete_op:
        mov ax, cnt                                    ;将cnt减一，其他清零
        sub ax, 1
        mov cnt, ax
        mov now,  0
        mov count,0
        clean 
        jmp init
;查找函数        
     search:                                          
        call clear
        call print_show
        curse 7, 20
        mov ah, 0ah                               
        lea dx, word1
        int 21h
        call word_search
        search_op:
        mov now,  0
        mov count,0
        clean
        jmp init                                     ;这个的总数cnt不用变
;修改函数        
     modify:                                          
        call clear
        call print_show 
        curse 7, 20
        mov ah, 0ah                               
        lea dx, word1
        int 21h
        call word_modify 
        modify_op:
        mov now,  0
        mov count,0
        clean 
        jmp init
;结束函数        
     exit:
        mov bx, handle
        mov al, 1                                     ;打开方式为写
        mov ah, 3DH                                   ;打开文件
        lea dx, file
        int 21h
        mov bx, handle
        mov cx, 4000
        mov ah, 40h                  
        lea dx, words
        int 21h
        mov bx, handle                                ;将文件代号传送至bx
        mov ah, 3EH                                   ;关闭文件
        int 21h
        scroll 23, 11, 1,  23，78,  21h               ;单词层，字体蓝色 
        curse 15, 35
        mov ah, 09h                                   ;显示注释
        lea dx, str7
        int 21h                                           
        mov ax, 4c00h                                 
        int 21h
;--------------------------------------------------子程序--------------------------------------------------;
;插入函数
    word_insert proc
        push si
        push di
        push cx
        push dx
        push ax
        find1:                                         ;找到最佳的位置
            cmp  cnt, 0
            jz insert1
            mov di, now
            mov si, 0 
            mov al, word_add[si] 
            mov dl, words[di]
            cmp al, dl
            jz  next_letter
            jnge insert1
            ja next_word
        insert1:                                       ;判断可以插入
            words_insert  count, word_add, words
            jmp exit1
        next_letter:                                   ;判断可以进到下一个字母
            inc now
            call word_insert
        next_word:                                     ;判断可以进到下一个单词
            mov ax, cnt
            mov bx, count                              ;若下个数为空，就插入
            cmp ax, bx 
            jz insert1                                     
            inc count
            mov ax, count
            mov bx, 100
            mul bx
            mov now, ax
            call word_insert
        exit1:           
        pop  ax
        pop  dx
        pop  cx
        pop  di
        pop  si
        ret
    word_insert endp
;删除函数
    word_delete proc
        push si
        push di
        push cx
        push dx
        push ax
        mov cl, word1[1]                               ;查看有多少个字母
        mov ch, 0
        mov di, now 
        mov si, 2
        find2:                                         ;判断相等就继续，不相等下一个
            mov al, word1[si] 
            mov dl, words[di]
            cmp al, dl
            jne add2
            inc si
            inc di    
            loop find2
        next2:                                         ;正常出来单词数已经检查完了，是一样的    
            jmp  out2                                  ;相等就结束输出                                     
        add2:                                          ;若有下一个字母就下一个
            inc count                                  ;进入到下个单词
            mov ax, count 
            mov bx, cnt
            cmp ax, bx
            ja word_delete_error                       ;若找完了就结束
            mov bx, 100
            mul bx
            mov now, ax
            call  word_delete
        word_delete_error:
            curse 7, 4  
            mov ah, 09h
            lea dx, error                              ;找不到这个单词
            int 21h
            jmp exit2 
        out2:
            words_delete words,count
        exit2:
            call next_op
            jmp delete_op        
        pop  ax
        pop  dx
        pop  cx
        pop  di
        pop  si
        ret
    word_delete endp
;查找函数
    word_search proc
        push si
        push di
        push cx
        push dx
        push ax 
        mov cl, word1[1]                               ;查看有多少个字母
        mov ch, 0
        mov di, now 
        mov si, 2
        find3:                                         ;判断相等就继续，不相等下一个
            mov al, word1[si] 
            mov dl, words[di]
            cmp al, dl
            jne add3
            inc si
            inc di    
            loop find3
        next3:                                         ;正常出来单词数已经检查完了，是一样的
            jmp else3                                  ;相等就结束输出查看下一个单词，若有下一个字母就表示下个有可以打印出来  
        add3:                                          
            inc count                                  ;进入到下个单词
            mov ax, count 
            mov bx, cnt
            cmp ax, bx
            ja word_search_error
            mov bx, 100
            mul bx
            mov now, ax
            call word_search
        word_search_error:
            mov cx, maywnum
            cmp cx, 0
            jz  out_e
            scroll 23, 5, 1, 6, 78, 21h                ;输入层提示字体蓝色
            scroll 23, 7, 1, 9, 78, 21h                ;输入层
            curse 7, 4                                 
            mov ah, 09h
            lea dx, searchhint        
            int 21h 
            scroll 23, 11, 1,  23，78,  21h            ;单词层，字体蓝色
            curse 12, 4
            mov di, 0
            out__an:
                mov dl, searchw[di]
                cmp dl, 20h
                jz exit3
                mov ah, 02h
                int 21h 
                inc di
                loop out__an 
            out_e:
                curse 7, 4  
                mov ah, 09h
                lea dx, error                          ;找不到这个单词
                int 21h
                jmp exit3 
        out3:                                          ;输出
            words_search words, count
            jmp exit3
        else3:
            mov al, words[di]                          ;输出
            cmp al, 20h
            jz out3 
            mov di, now 
            mov cx, 20                                 ;设cx为10来,若结束就跳出去
            out__3:
                mov dl, words[di]
                cmp dl, 20h
                jz next_search
                mov si, maywnum
                mov searchw[si],  dl    
                inc si
                mov maywnum,si
                inc di
                loop out__3
        next_search:
            mov searchw[si], 44
            jmp add3
        exit3:
            call next_op
            jmp search_op                                          
        pop  ax
        pop  dx
        pop  cx
        pop  di
        pop  si
        ret
    word_search endp
;修改函数
    word_modify proc
        push si
        push di
        push cx
        push dx
        push ax 
        mov cl, word1[1]+1                             ;查看有多少个字母
        mov ch, 0
        mov di, now 
        mov si, 2
        find4:                                         ;判断相等就继续，不相等下一个
            mov al, word1[si] 
            mov dl, words[di]
            cmp al, dl
            jne next4
            inc si
            inc di    
            loop find4
        next4:                                         ;正常出来判断单词数是不是一样的
            mov dl, words[di]
            cmp dl, 20h
            jz  out4                                   ;相等就结束输出      
        add4:                                          ;若有下一个字母就下个单词
            inc count                                  ;进入到下个单词
            mov ax, count 
            mov bx, cnt
            cmp ax, bx
            ja word_modify_error
            mov bx, 100
            mul bx
            mov now, ax
            call word_modify
        word_modify_error:
            curse 7, 4  
            mov ah, 09h
            lea dx, error                              ;找不到这个单词
            int 21h
            jmp exit4 
        out4:                                          ;
            curse 12, 12
            word_input 2, 20
            curse 18, 12
            word_input 3, 60
            curse 18, 51
            word_input 4, 80
            add now, 20
            mov cx,  80
            mov di, now
            mov si, 20
            in4:
                mov dl, word_add[si]
                mov words[di], dl
                inc di
                inc si
                loop in4         
        exit4:
            call next_op
            jmp modify_op
        pop  ax
        pop  dx
        pop  cx
        pop  di
        pop  si
        ret
    word_modify endp
;图像打印
    print_show proc
        scroll 23, 11, 1,  23，78,  21h               ;单词层，字体蓝色
        curse 12, 4
        mov ah, 09h                                   ;显示注释
        lea dx, str3
        int 21h
        curse 18, 4
        mov ah, 09h                                   ;显示同义词
        lea dx, str4
        int 21h
        curse 18, 43
        mov ah, 09h                                   ;显示反义词
        lea dx, str5
        int 21h
        ret
    print_show endp
;提示输入
    clear proc                                        ;清除输入层程序
        push ax
        push bx
        push cx
        push dx
        scroll 23, 5, 1, 6, 78, 21h                   ;输入层提示字体蓝色
        scroll 23, 7, 1, 9, 78, 21h                   ;输入层
        curse 7, 4                                 
        mov ah, 09h
        lea dx, input_hint        
        int 21h
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    clear endp
;表示清除    
    next_op proc                                        ;清除输入层程序
        push ax
        push bx
        push cx
        push dx
        scroll 23, 5, 1, 6, 78, 21h                   ;输入层提示字体蓝色
        scroll 23, 7, 1, 9, 78, 21h                   ;输入层
        curse 7, 4                                 
        mov ah, 09h
        lea dx, next_w        
        int 21h
        curse 7, 30
        mov ah,1
        int 21h
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    next_op endp                    
ends 

end start ; 