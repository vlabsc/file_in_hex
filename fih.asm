; fih.asm
; file in hex version 10
; version 10 - argument from command line for file - completed
; file size limit check - completed
; yet to do - error handling

format PE64 console
entry main

include 'C:\fasm\INCLUDE\WIN64AX.INC'

include 'V:\OneHalf\Programming\asm\FASM\libs\libs.inc'
include 'V:\OneHalf\Programming\asm\FASM\libs\macros.inc'


section '.data' data readable writeable
month_print_index db 1
cmd_line_argument_pointer dd 0x00000000

cmd_line_arg1_address dd 1
cmd_line_arg2_address dd 1

inputfile_opened_handle dd 0
;inputfile_name db 'sample2.exe', 0
inputfile_name_address dd 0x0

;inputfile_name db 'ascii.png', 0
;inputfile_name db 'howto.pdf', 0
inputfile_size dd 0
inputfile_max_size_allowed dd 4100000   ; 4100000 bytes


hexprint_start_address dd 0x00000000
hexprint_buffer_total_lines_to_display dd 0
hexprint_buffer_total_columns_to_display dd 16; each line displays 16 bytes
hexprint_buffer_last_line_columns_to_display dd 0  ; each line displays 8 bytes

inputfile_bytes_read_by_readfile dd 0   ; this will be returned by ReadFile
inputfile_read_buffer_address dd ?

getcurrentdir_buffer rb 256
getcurrentdir_buffer_length dw 256


section '.text' code readable executable

main:
    pushall

    invoke GetCommandLineA
    mov [cmd_line_argument_pointer], eax

    mov eax, [cmd_line_argument_pointer]
    fastcall find_number_of_command_line_arguments, eax

    cmp eax, 0x0
    je no_arguments_passed
    cmp eax, 0x1
    jg too_many_arguments_passed
    jmp correct_arguments_passed

no_arguments_passed:
    invoke printf, "no arguments passed ..."
    call print_newline
    jmp exitall
too_many_arguments_passed:
    invoke printf, "too many arguments passed ..."
    call print_newline
    jmp exitall

correct_arguments_passed:




    ;debugbreak

    fastcall get_argument_strings_for_one_argument, [cmd_line_argument_pointer], \
                        cmd_line_arg1_address, cmd_line_arg2_address


    
    ;debugbreak
    mov eax, [cmd_line_arg1_address]
    push rax
    mov eax, [cmd_line_arg2_address]
    push rax

    pop rax
    pop rax


    xor rax, rax
    mov eax, [cmd_line_arg2_address]
    mov [inputfile_name_address], eax


    ;call clrscr
    invoke printf, "file in hex 9 in FASM"
    call print_newline

    ; windbg - C:\Program Files (x86)\Windows Kits\10\Debuggers
    ;invoke GetCurrentDirectory, [getcurrentdir_buffer_length], addr getcurrentdir_buffer

    ;jmp .program_exit

    ;invoke CreateFileA, addr inputfile_name, GENERIC_READ, 0, NULL, OPEN_EXISTING, \
                        ;FILE_ATTRIBUTE_NORMAL, NULL
    invoke CreateFileA, [inputfile_name_address], GENERIC_READ, 0, NULL, OPEN_EXISTING, \
                        FILE_ATTRIBUTE_NORMAL, NULL
    mov [inputfile_opened_handle], eax
    
    cmp eax, -1
    jne .openfileok
    ;invoke printf, "error in opening the file %s. error code: %d", addr inputfile_name, eax
    invoke printf, "error in opening the file %s. error code: %d", \
                    [inputfile_name_address], eax
    call print_newline
    jmp .program_exit    

.openfileok:
    ;invoke printf, "file %s opened successfully.", addr inputfile_name
    invoke printf, "file %s opened successfully.", [inputfile_name_address]
    call print_newline    

.openfileok1:

    invoke GetFileSize, [inputfile_opened_handle], NULL
    mov [inputfile_size], eax

    ;invoke printf, "file %s size is: %d bytes. ", addr inputfile_name, [inputfile_size]
    invoke printf, "file %s size is: %d bytes. ", [inputfile_name_address], [inputfile_size]


    ; if file size is less than threshold, then proceed else exit the whole program    
    xor rbx, rbx
    mov ebx, [inputfile_max_size_allowed]
    cmp [inputfile_size], ebx
    jle .filesizeok

    invoke printf, "file size is bigger than: %d bytes. exiting.", \
                    [inputfile_max_size_allowed]
    jmp .program_exit

.filesizeok:

    ;inputfile_read_buffer_address
    xor eax, eax

    ; allocate address based on inputfile_max_size_allowed
    mov eax, GMEM_FIXED
    or eax, GMEM_ZEROINIT
    invoke GlobalAlloc, eax, [inputfile_max_size_allowed]
    mov [inputfile_read_buffer_address], eax
    invoke printf, "buffer allocated at address: 0x%x", [inputfile_read_buffer_address]
    call print_newline

    ; bp addr 00404268 
    invoke ReadFile, [inputfile_opened_handle], [inputfile_read_buffer_address], \
                        [inputfile_max_size_allowed], addr inputfile_bytes_read_by_readfile, \
                        NULL

    xor rax, rax
    xor rdx, rdx
    xor rcx, rcx

    ; following logic finds out how many lines to print out start
    mov eax, [inputfile_bytes_read_by_readfile]
    mov ecx, [hexprint_buffer_total_columns_to_display]

    div ecx
    mov [hexprint_buffer_total_lines_to_display], eax
    mov [hexprint_buffer_last_line_columns_to_display], edx
    ; end

    fastcall print_hex, [hexprint_buffer_total_lines_to_display], \
                    [hexprint_buffer_total_columns_to_display], \
                    [hexprint_buffer_last_line_columns_to_display], \
                    [inputfile_read_buffer_address]

    ;invoke printf, "buffer allocated at address: 0x%x", [inputfile_read_buffer_address]
    ;call print_newline



.program_exit:
    call print_newline
    invoke printf, "end of file reached."

closehandle:
    invoke CloseHandle, [inputfile_opened_handle]

exitall:
    call print_newline
    invoke printf, "exiting ..."
    call print_newline

    popall
    ret 


include 'printhex.asm'




section '.idata' import data readable
    library msvcrt, 'msvcrt.dll',\
            kernel32, 'kernel32.dll'
        import msvcrt,\
            printf, 'printf'

        include 'C:\fasm\INCLUDE\API\KERNEL32.INC'
