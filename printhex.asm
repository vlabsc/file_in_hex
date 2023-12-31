; printhex.asm
; file in hex version 11
; version 11 - speed test with powershell
; file size limit check - completed
; yet to do - error handling

section '.data' data readable writeable
hextable db '0123456789ABCDEF'
hexstring rb 48
db 0    ; end of string 
filterstring rb 16
db 0 

section '.text' code readable executable

proc print_hex hexprint_buffer_total_lines_to_display, \
                    hexprint_buffer_total_columns_to_display, \
                    hexprint_buffer_last_line_columns_to_display, \
                    inputfile_read_buffer_address
    
    mov dword [hexprint_buffer_total_lines_to_display], ecx
    mov dword [hexprint_buffer_total_columns_to_display], edx
    mov [hexprint_buffer_last_line_columns_to_display], r8
    mov [inputfile_read_buffer_address], r9

    pushall
    local row_address_print rb 0x4

    mov dword [row_address_print], dword 0x00000000

    xor rsi, rsi
    xor rdi, rdi
    xor r14, r14
    xor r15, r15

    mov esi, dword [inputfile_read_buffer_address]

    iteration_loop_each_rows_start:
        ; save the position - start
        ; first time the hex values are printed
        ; then again for the same bytes we need to print ASCII
        ; so the buffer_index is savted into 'buffer_index_save' 
        ; to start specific to that row
        ; esi holds the original offset, edi is incremented for every cell display
        xor rcx, rcx
        ;mov esi, edi
        ; save the position - end

        ; check if row_index is less then hexprint_buffer_total_lines_to_display - start
        ; the total rows should be less than hexprint_buffer_total_lines_to_display
        ; hexprint_buffer_total_lines_to_display = file size / bytes to show per line
        ; the reminder would go into hexprint_buffer_last_line_columns_to_display
        xor ecx, ecx        
        cmp dword [hexprint_buffer_total_lines_to_display], r14d
        je iteration_loop_each_rows_end
        ; check if row_index is less then hexprint_buffer_total_lines_to_display - end

        xor rdx, rdx
        xor rcx, rcx
        xor r15, r15

        invoke printf, "0x%08x [ ", dword [row_address_print]        
        
        xor edi, edi
        ;mov esi, dword [inputfile_read_buffer_address]
        mov edi, esi
        
        xor r15d, r15d
        lea ebx, [hextable]
        lea r15d, [hexstring]
        mov ecx, 16         ; 16 bytes at a time
        looop:
            mov al, byte [edi]
            and al, 0xf0
            shr al, 4

            xlatb
            mov [r15d], al

            inc r15d    

            mov al, byte [edi]
            and al, 0xf

            xlatb
            mov [r15d], al

            inc r15d    

            mov [r15d], byte 0x20

            inc edi
            inc r15d    
        loop looop            

        invoke printf, "%s ] ", addr hexstring


        ; print the ASCII of the row - start 

        ; restore the position
        ; first time the hex values are printed
        ; then again for the same bytes we need to print ASCII
        ; so the buffer_index is restored from 'buffer_index_save' 
        ; to start specific to that row
        ; esi holds the original offset, edi is incremented for every cell display
        xor ecx, ecx
        xor edi, edi
        ;mov edi, esi    ; restore
        lea edi, [filterstring]
        xor r15d, r15d

        invoke printf, "[ "
        .iteration_loop_cols_ascii_start:
            cmp r15b, byte [hexprint_buffer_total_columns_to_display]
            je .iteration_loop_cols_ascii_end
            
            ;mov ecx, esi
            ;mov ecx, [ecx]
            mov ecx, [esi]
            cmp byte cl, 0x20
            jge .check_ascii_readable_1
            jmp .ascii_not_normal_print
            .check_ascii_readable_1:
                cmp byte cl, 0x7e
                jle .ascii_normal_print
                jmp .ascii_not_normal_print
            .ascii_normal_print:
                ;invoke printf, "%c", [char_to_print]
                mov [edi], byte cl
                jmp .check_ascii_readable_1_out
            .ascii_not_normal_print:
                mov [edi], byte 0x2e
                ;invoke printf, "."
            .check_ascii_readable_1_out:
            inc edi
            inc esi
            inc r15b
            jmp .iteration_loop_cols_ascii_start
        .iteration_loop_cols_ascii_end:
        invoke printf, "%s ] ", addr filterstring
        ; print the ASCII of the row - end

        ;l at this point one row is over. hence calculation are made

        inc r14d            ; one row is over
        ;mov esi, edi

        mov dword ecx, dword [hexprint_buffer_total_columns_to_display]
        add dword [row_address_print], dword ecx    
        
        call print_newline
        jmp iteration_loop_each_rows_start
    iteration_loop_each_rows_end:


; -----------------------------------------------------------------------------------
    ; now let's iterate the last row

    cmp byte [hexprint_buffer_last_line_columns_to_display], 0x0
    je print_hex_return


    xor ecx, ecx
    mov ecx, 49
    lea r15d, [hexstring]

    looop3:
        mov [r15d], byte 0x0
        inc r15d
    loop looop3

    ; save the position - start
    ; first time the hex values are printed
    ; then again for the same bytes we need to print ASCII
    ; so the buffer_index is savted into 'buffer_index_save' 
    ; to start specific to that row
    ; esi holds the original offset, edi is incremented for every cell display
    xor rcx, rcx
    ;mov esi, edi
    mov edi, esi
    ; save the position - end

    xor rcx, rcx
    xor rdx, rdx
    xor r15, r15

    invoke printf, "0x%08x [ ", dword [row_address_print]

    
    .iteration_loop_last_row_start:
        xor r15d, r15d
        lea ebx, [hextable]
        lea r15d, [hexstring]
        xor ecx, ecx
        mov cl, byte [hexprint_buffer_last_line_columns_to_display]

        looop2:
            mov al, byte [edi]
            and al, 0xf0
            shr al, 4

            xlatb
            mov [r15d], al

            inc r15d    

            mov al, byte [edi]
            and al, 0xf

            xlatb
            mov [r15d], al

            inc r15d    

            mov [r15d], byte 0x20

            inc edi
            inc r15d    
        loop looop2
        invoke printf, "%s ", addr hexstring

        xor ebx, ebx
        mov bl, byte [hexprint_buffer_total_columns_to_display]
        sub bl, byte [hexprint_buffer_last_line_columns_to_display]

        looop4:
            test ebx, ebx
            je looop4_comeout
            invoke printf, "   "
            dec ebx
            jmp looop4
        looop4_comeout:

        invoke printf, "] "


        ; print the ASCII of the last row - start 

        ; restore the position
        ; first time the hex values are printed
        ; then again for the same bytes we need to print ASCII
        ; so the buffer_index is restored from 'buffer_index_save' 
        ; to start specific to that row
        ; esi holds the original offset, edi is incremented for every cell display
        ;debugbreak

        mov edi, esi
        xor r15, r15

        invoke printf, "[ "
        .iteration_loop_last_row_col_ascii_start:
            cmp r15b, byte [hexprint_buffer_total_columns_to_display]
            je .iteration_loop_last_row_ascii_end

            cmp r15b, byte [hexprint_buffer_last_line_columns_to_display]
            ; no jle because the col_index starts at 0
            jl .iteration_loop_last_last_row_col_1
            invoke printf, " "
            jmp .iteration_loop_last_last_row_col_2

            .iteration_loop_last_last_row_col_1:
                mov ecx, edi
                ;add ecx, dword [inputfile_read_buffer_address]
                mov ecx, [ecx]
                fastcall print_ascii_character, ecx

            .iteration_loop_last_last_row_col_2:

            inc edi
            inc r15b    ; one column is over

            jmp .iteration_loop_last_row_col_ascii_start
        .iteration_loop_last_row_ascii_end:
        invoke printf, " ]"
        ; print the ASCII of the row - end


print_hex_return:

    popall
    ret
endp



proc print_ascii_character, char_to_print
    ; ascii - 0x20 to 0x7e looks readable

    pushall

    mov byte [char_to_print], byte cl
    cmp byte [char_to_print], 0x20
            jge .check_ascii_readable_1
            jmp .ascii_not_normal_print
            .check_ascii_readable_1:
                cmp byte [char_to_print], 0x7e
                jle .ascii_normal_print
                jmp .ascii_not_normal_print
            .ascii_normal_print:
                invoke printf, "%c", [char_to_print]
                jmp .check_ascii_readable_1_out
            .ascii_not_normal_print:
                invoke printf, "."
            .check_ascii_readable_1_out:

    popall
    ret
endp

