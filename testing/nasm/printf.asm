
global _main
global _printf

extern _ExitProcess@4
extern _GetStdHandle@4
extern _WriteConsoleA@20

section .data
    msg:    db  'Hello\r\n%s', 0
    msg2:   db  'jAsON', 0

section .text
    _main:
        push ebp
        mov  ebp, esp

        push msg2
        push msg
        call _printf

        push 0
        call _ExitProcess@4

        pop ebp
        ret 0


    _printf:
        push ebp                ; push the base pointer
        mov  ebp, esp           ; ebp := esp
        sub  esp, 8             ; get 2 dwords of stack space (esp = ebp - 8)

        mov  dword [ebp - 4], 0 ; initialize local variable 'written'
        mov  dword [ebp - 8], 0 ; initialize local variable 'argcounter'

    .printloop:
        mov  eax, [ebp + 8]     ; load the format string pointer into eax
        cmp  byte [eax], '%'    ; check for '%'
        je  .format

        cmp  byte [eax], '\'    ; check for '\'
        je   .escape

        jmp  .print

    .escape:
        inc  dword [ebp + 8]
        mov  eax, [ebp + 8]

        cmp  byte [eax], 'n'
        je   .newline

        cmp  byte [eax], 'r'
        je   .bell

        jmp  .printEscape

    .bell:
        mov  eax, 7
        jmp  .finish

    .newline:
        mov  eax, 10
        jmp  .finish

    .finish:
        push eax
        call _printChar@4

        jmp .loopend

    .printEscape:
        push dword [eax]
        call _printChar@4

        jmp .loopend
    
    .format:
        inc  dword [ebp + 8]    ; increment format string pointer
        inc  dword [ebp - 8]    ; increment the arg counter

        ; Calculate where the argument is on the stack
        ; edx = (ebp + 8) + argc * 4
        mov  edx, [ebp - 8]
        imul edx, edx, 4
        add  edx, 8
        add  edx, ebp

        mov  eax, [ebp + 8]      
        cmp  byte [eax], 'c'    ; check for 'c' 
        je   .charformat

        cmp  byte [eax], 's'    ; check for 's'
        je   .stringformat

        cmp  byte [eax], 'd'    ; check for 'd'
        je   .intformat

        ; clean up stack frame
        mov  eax, -1
        mov  esp, ebp           ; move the base pointer into the stack pointer
        pop  ebp                ; pop the original base pointer 
        ret  8

    .intformat:
        mov  ecx, [edx]         ; ecx holds the number
        cmp  ecx, 0             ; check if number is negative
        jl   .ifneg

        mov  ebx, 0             ; set digit counter to 0
        jg   .ifbcdloop         ; else
        
        push '0'
        call _printChar@4
        jmp  .loopend

    .ifneg:                     ; print negative sign and negate number
        push ecx
        push edx

        push '-'
        call _printChar@4

        pop  edx
        pop  ecx
        neg  dword ecx

        mov  ebx, 0             ; set the digit counter to 0

    ; The algorithm implemented is this:
    ;   For a number 'n', it's "last" digit is n % 10. Then, n / 10 is the new 'n'.
    ;   Each digit is pushed onto the stack and popped in reverse order to print 
    ;   them in correctly. 'div' calculates both the n % 10 and n / 10 with n % 10
    ;   stored in edx and n / 10 stored in eax.
    .ifbcdloop:                 
        inc  ebx                ; increment digit counter

        mov  eax, ecx
        mov  ecx, 10
        mov  edx, 0
        div  ecx
        mov  ecx, eax 

        add  edx, 48            ; convert to ASCII and push on the stack
        push edx

        cmp  ecx, 0
        jne  .ifbcdloop

    .ifprintloop:
        pop  eax
        push ebx
        
        push eax
        call _printChar@4

        pop  ebx

        dec  ebx                ; decrement the digit counter
        cmp  ebx, 0             ; if there are no more digits, goto loopend
        jne  .ifprintloop
        jmp  .loopend

    .stringformat:
        mov  eax, [edx]         ; set eax to be the pointer to the argument string
        cmp  byte [eax], 0      ; if (*eax == 0)
        je   .loopend           ;     goto loopend;

        push edx                ; push the edx register onto the stack

        push dword [eax]
        call _printChar@4

        pop  edx                ; pop the stack to the edx register

        inc  dword [edx]
        jmp  .stringformat

    .charformat:
        push dword [edx]
        call _printChar@4

        jmp  .loopend

    .print:
        mov  ebx, [ebp + 8]     ; move the format string pointer into ebx
        push dword [ebx]
        call _printChar@4

    .loopend:
        inc dword [ebp + 8]     ; increment the position of the format string pointer
        mov eax, [ebp + 8]
        cmp byte [eax], 0       ; check to see if character pointed to by eax is NULL
        jne .printloop          ; Jump if not NULL character

        mov  eax, 0             ; return 0

        ; clean up stack frame
        mov  esp, ebp           ; move the base pointer into the stack pointer
        pop  ebp                ; pop the original base pointer 
        ret  8


    _printChar@4:               ; printChar (char)
        push ebp
        mov  ebp, esp
        sub  esp, 4             ; reserve for 'written'

        push dword -11
        call _GetStdHandle@4

        push dword 0            ; push NULL argument
        lea  ebx, [ebp - 4]
        push ebx                ; push the address for 'written'
        push 1                  ; push the length of 1 character
        mov  ebx, ebp
        add  ebx, 8
        push ebx                ; push calculated stack pointer to the char
        push eax                ; push the standard handle
        call _WriteConsoleA@20

        ; clean up stack frame
        mov eax, [ebp - 4]
        mov esp, ebp
        pop ebp
        ret 4
