TITLE Macros and IO     (InputOutput.asm)

;Albert Chang
;changal@oregonstate.edu
;CS271-400
;Assignment 6 (Program 6A)
;Due 2016-3-13
;Description: Two macro wrappers for ReadString and WriteString, and two procedures for our own
; implementations of Irvine's read/write procedures (unsigned integers only) using only ReadString
; and WriteString (and math, of course). The test program collects ten values, and shows the sum 
; and average. (It also has some basic data validation, all the usual stuff for a solid program.)
; The real fun is in the macros and procedures here. The test program is just that, a simple test. 

INCLUDE Irvine32.inc

MY_NAME         EQU     <"Albert Chang">
NUMBER_INTS     =       10
; NUMBER_INTS is defined here for easy changing later on.

;~~~~~~~~~~~~~~~~~~
; getString (macro)
;This macro wraps up Irvine's ReadString procedure
;receives: address to store a string, address for a friendly prompt, and length of string (a DWORD).
;returns: string is stored into the first address.
;preconditions: addresses are valid.
;registers changed: None. (EDX, ECX preserved)
;~~~~~~~~~~~~~~~~~~
getString   MACRO   stringAddress, promptAddress, stringLength
    push    edx
    push    ecx
    
    mov     edx, promptAddress
    call    WriteString
    
    mov     edx, stringAddress
    mov     ecx, stringLength
    call    ReadString
    
    pop     ecx
    pop     edx
ENDM
    
;~~~~~~~~~~~~~~~~~~
; displayString (macro)
;This macro wraps up Irvine's WriteString procedure
;receives: address holding a null-terminated string.
;returns: Nothing, but the string is printed.
;preconditions: String exists (and null-terminated).
;registers changed: None. (EDX preserved)
;~~~~~~~~~~~~~~~~~~
displayString   MACRO   address
    push    edx
    
    mov     edx, address
    call    WriteString
    
    pop     edx
ENDM

; ~~~~~~~~~~~~~~~~~~
; divWrapper (macro)
; This macro is my own form of three-operand unsigned division. (With four operands, not three.)
; receives: Four mem32 parameters (by reference, so passing their addresses):
;           quotient, remainder, dividend, divisor
;           quotient and remainder are output parameters (values will be stored in those addresses)
;           dividend and divisor are input parameters (they need valid integer values for 32-bit division)
; returns: The dividend is divided by the divisor and properly stored in the quotient and remainder.
; preconditions: The parameters are valid.
; registers changed: None. (EAX/EBX/ECX/EDX preserved)
; ~~~~~~~~~~~~~~~~~~
divWrapper  MACRO   quotient, remainder, dividend, divisor
    push    edx
    push    ebx
    push    eax
    push    ecx
    
    xor     edx, edx
    
    mov     ecx, dividend
    mov     eax, [ecx]
    
    mov     ecx, divisor
    mov     ebx, [ecx]
    div     ebx
    
    mov     ecx, quotient
    mov     [ecx], eax
    
    mov     ecx, remainder
    mov     [ecx], edx
    
    pop     ecx
    pop     eax
    pop     ebx
    pop     edx
ENDM

.data

program_intro   BYTE    "PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",0
by_line         BYTE    "Written by: ",MY_NAME,0

instruction1a   BYTE    "Please provide ",0
instruction1b   BYTE    " unsigned decimal integers.",0
instruction2    BYTE    "Each number needs to be small enough to fit inside a 32 bit register.",0
instruction3a   BYTE    "After you have finished inputting the raw numbers I will display a list",0
instruction3b   BYTE    "of the integers, their sum, and their average value.",0

ec_message      BYTE    "**EC: There's also a division macro. It's not much to look at.",0

comma_space     BYTE    ", ",0

prompt_number   BYTE    "Please enter an unsigned number: ",0
re_prompt       BYTE    "Please try again: ",0
error_msg       BYTE    "ERROR: You did not enter an unsigned number or your number was too big.",0

array_title     BYTE    "You entered the following numbers:",0
sum_title       BYTE    "The sum of these numbers is: ",0
average_title   BYTE    "The average is: ",0

thanks          BYTE    "Thanks for playing!",0

user_sum        DWORD   ?
user_average    DWORD   ?
user_remainder  DWORD   ? ; This is never actually useful, but I want my division macro to be more robust.

number_ints_mem DWORD   NUMBER_INTS    
; This is only for my division macro. It may seem strange, but after thinking about the possibility of
;  incorrect parameters passed to the macro by unaware users (meaning passing registers instead of only
;  memory and immediate operands, I decided to go with reference parameters (so that a user would know
;  explicitly that registers aren't valid operands).

int_array       DWORD   NUMBER_INTS DUP(0)

.code
main PROC

    ; For fun, uncomment this and verify the registers are preserved properly at the end of the program.
    ; mov     eax, 0AAAAAAAAh
    ; mov     ebx, 0BBBBBBBBh
    ; mov     ecx, 0CCCCCCCCh
    ; mov     edx, 0DDDDDDDDh
    ; mov     edi, 0EEEEEEEEh
    ; mov     esi, 0FFFFFFFFh
    
; Introduction
;  I made this into a procedure and pushed all the relevant strings to print.
    push    OFFSET program_intro
    push    OFFSET by_line
    push    OFFSET instruction1a
    push    OFFSET instruction1b
    push    OFFSET instruction2
    push    OFFSET instruction3a
    push    OFFSET instruction3b
    push    NUMBER_INTS
    push    OFFSET ec_message
    call    introduction
    
    call    CrLf
    
; Populate array
    push    OFFSET prompt_number
    push    OFFSET re_prompt
    push    OFFSET error_msg
    push    OFFSET int_array
    push    NUMBER_INTS
    call    arrayMaker
    
    call    CrLf
    
; Calculate sum
    push    OFFSET int_array
    push    NUMBER_INTS
    push    OFFSET user_sum
    call    arraySum

; Calculate average
;  The average calculation is just simple division, so I didn't create a procedure for it.
;  Instead, I created a macro for fun.
    divWrapper  OFFSET user_average, OFFSET user_remainder, OFFSET user_sum, OFFSET number_ints_mem
    
; Print array
    displayString OFFSET array_title
    call    CrLf
    
    push    OFFSET int_array
    push    NUMBER_INTS
    push    OFFSET comma_space
    call    arrayPrinter
    
; Outroduction
;  Like introduction, but backwards. Also prints the sum and average.

    push    OFFSET sum_title
    push    OFFSET average_title
    push    OFFSET thanks
    push    user_sum
    push    user_average
    call    outroduction
    
	exit	; exit to operating system
main ENDP


;~~~~~~~~~~~~~~~~~~
; readVal
;This procedure takes user input (as a string) and converts to an unsigned integer.
;receives: Takes a stack parameter (reference) of an address that user input will be stored into (DWORD integer)
;          and a few more for prompts. This may be confusing, so here it is in order:
;          Address to store user input
;          Address for initial prompt
;          Address for "try again"
;          Address for error message (this is part of the try again prompt)
;returns: Stores the user's number into the address passed in as a stack parameter.
;preconditions: Nothing in particular. The stack parameter should properly reference an address to store a DWORD.
;registers changed: None. (EAX/EBX/ECX/EDX/ESI preserved)
;~~~~~~~~~~~~~~~~~~
readVal PROC,
    rv_error_message:DWORD,
    rv_try_again:DWORD,
    rv_prompt:DWORD,
    rv_integer:DWORD  ; These are all addresses, not actual DWORD integers.
    
    sub     esp, 16   ; Space for a local variable (a temporary byte string 16 bytes long).
                      ; Use 16 because the maximum number of digits in a DWORD is 10 digits.
    push    esi       ; 16 gives us a 5-digit buffer to catch invalid numbers (larger numbers).
    push    edx
    push    ecx
    push    ebx
    push    eax
    
    cld     ; Just in case, make sure LODSB will move in the right direction.
    
    lea     esi, [ebp - 16]
    getString   esi, rv_prompt, 16
    jmp     conversion_start
    
retry:  ; This block is skipped the first time.
    displayString   rv_error_message  ; Point out the error. 
    call    CrLf
    
    lea     esi, [ebp - 16]
    getString   esi, rv_try_again, 16 ; Try again.
    
conversion_start:
    lea     esi, [ebp - 16] ; Prepare for some LODSB fun.
    xor     ebx, ebx        ; EBX will be the accumulator, because why not.
    mov     ecx, 10         ; ECX will just hold 10 for fast multiplication.
                            ; Kind of a waste of a perfectly good loop counter.
    jmp     skip_check      ; This prevents null strings (an initial 0 byte) from being entered as 0.
builder_loop:
    mov     al, BYTE PTR [esi] ; Doing a quick check to see if we're done.
    cmp     al, 0              ; If we reach the null character, we're at the end of the string.
    je      done_building
skip_check:                 ; First time through, we skip the check.
    xor     edx, edx        ; Clear EDX.
    mov     eax, ebx        ; Prepare for multiplication.
    mul     ecx
    cmp     edx, 0          ; If EDX has anything at all, EDX:EAX is too large for a DWORD.
    jne     retry
    
    mov     ebx, eax        ; Get the value back in the acumulator.
    xor     eax, eax        ; Clear EAX before getting a new byte. Just in case.
    lodsb                   ; Get that new byte.
    
    cmp     al, 48          ; If below 48, then it's invalid.
    jb      retry
    cmp     al, 57          ; If above 57, it's also invalid.
    ja      retry
    sub     al, 48          ; If valid, subtract 48 and add to accumulator.
    add     ebx, eax
    jc      retry           ; If a carry occurred, our number is too big. It's trashed.
    jmp     builder_loop
    
done_building:
    mov     edx, rv_integer
    mov     [edx], ebx
    
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    pop     esi
    
    add     esp, 16         ; Get rid of the local string.
    
    ret    
readVal ENDP


;~~~~~~~~~~~~~~~~~~
; writeVal
;This procedure is like the opposite of readVal. It takes an integer and prints it out as a string.
;receives: Takes a DWORD unsigned integer on the stack.
;returns: Prints the integer passed in (converts it to a string, then uses displayString macro).
;preconditions: Nothing in particular. The stack parameter should be a valid unsigned integer.
;registers changed: None. (EAX/EBX/EDX/EDI preserved)
;~~~~~~~~~~~~~~~~~~
writeVal PROC,
    wv_integer:DWORD  ; This is an actual DWORD integer, not an address.
    
    sub     esp, 12   ; Space for a local variable (a temporary byte string 12 bytes long).
                      ; Use 12 because the maximum number of digits in a DWORD is 10 digits.
    push    edi
    push    edx
    push    ebx
    push    eax
    
    std     ; Just in case, make sure STOSB will move in the right direction (that is, backwards).

; Note that we're starting at the end of the variable rather than the front of it here,
;  because we're building through the string backwards. As for why it's EBP - 1, well I actually
;  used the memory watcher in Visual Studio and saw that the right place to start is EBP - 1.
; I expected it to be EBP at first (we are subtracting 12 from EBP, after all) but I can't argue
;  with empirical results. I think it has to do with how the stack counts addresses backwards.
; Starting from EBP - 12, there are 12 bytes available, up to EBP - 1. EBP would be the 13th byte.
    lea     edi, [ebp - 1]  ; Prepare for some STOSB fun.
    mov     ebx, 10         ; EBX will hold 10 for fast division.
    mov     al, 0           ; Strings are null-terminated, so we terminate it first. 
    stosb                   ; Remember, we're going backwards.
    mov     eax, wv_integer ; Prepare to do some stuff with the parameter.

builder_loop:
    xor     edx, edx        ; Clear EDX before division.
    div     ebx             ; Division by 10 (remainder is now a digit we can use).
    add     edx, 48         ; Because the character for 0 is ASCII 48, and the remainder is our digit.
    xchg    eax, edx        ; I've never used XCHG before, so I want to try it now.
    stosb                   ; Move the remainder byte to the string (character byte array).
    xchg    eax, edx        ; Move the remainder and quotient back to where they were.
    cmp     eax, 0          ; If EAX (the quotient again) is 0, then we're done.
    je      done_building
    
    jmp     builder_loop
    
done_building:
    inc     edi             ; STOSB will end up one past the start of our string, so we move it back.
    displayString edi       ; Now we print the string we just built with our printing macro.
    
    pop     eax
    pop     ebx
    pop     edx
    pop     edi
    
    add     esp, 12         ; Get rid of the local string.
    
    ret    
writeVal ENDP


;~~~~~~~~~~~~~~~~~~
; arraySum
;This procedure just sums all the values in the array. No validation,
;  so if the sum is greater than DWORD size, there's going to be some great failure.
;receives: Takes three parameters in this order:
;          Address of array containing DWORD integers (reference)
;          Number of values in that array (DWORD, value)
;          Address of a DWORD to store the sum (reference)
;returns: Stores the calculated sum in the memory location passed in for the sum
;preconditions: The array and its size should be valid.
;registers changed: None. (EAX/EBX/EDX/EDI preserved)
;~~~~~~~~~~~~~~~~~~
arraySum PROC,
    as_sum:DWORD,
    as_number:DWORD,
    as_array:DWORD
    
    push    edx
    push    ecx
    push    eax
    
    mov     ecx, 0
    mov     edx, as_array
    
    xor     eax, eax    ; EAX is our accumulator, as it should be.
    
sum_loop:
    add     eax, [edx + ecx*4]
    inc     ecx
    cmp     ecx, as_number
    jb      sum_loop
    
    mov     edx, as_sum
    mov     [edx], eax
    
    pop     eax
    pop     ecx
    pop     edx
    
    ret
arraySum ENDP


;~~~~~~~~~~~~~~~~~~
; arrayMaker
;This was originally in the main procedure, but moved out because why not.
; The procedure is just a simple loop that calls readVal and populates the array.
;receives: Takes most of the parameters readVal needs (for obvious reasons), and more:
;          Address for initial prompt
;          Address for "try again"
;          Address for error message (this is part of the try again prompt)
;          Address of integer array
;          Number of values to put into array (DWORD)
;returns: Uses readVal to fill the array with the specified number of values 
;preconditions: All parameters need to be valid.
;registers changed: None. (ECX/EDX preserved)
;~~~~~~~~~~~~~~~~~~
arrayMaker PROC,
    am_array_size:DWORD,
    am_array:DWORD,
    am_error_message:DWORD,
    am_try_again:DWORD,
    am_prompt:DWORD
    
    push    edx
    push    ecx
    
    mov     edx, am_array
    mov     ecx, am_array_size
array_fill_loop:
    push    edx     ; Directly push the address of the next spot to be filled.
    push    am_prompt
    push    am_try_again
    push    am_error_message
    call    readVal
    
    add     edx, 4  ; Go to the next DWORD address in the array.
    loop    array_fill_loop
    
    pop     ecx
    pop     edx
    
    ret
arrayMaker ENDP


;~~~~~~~~~~~~~~~~~~
; arrayPrinter
;This was originally in the main procedure, but moved out because why not.
; The procedure is just a simple loop that calls writeVal to print an array.
;receives: writeVal doesn't need much, but this procedures needs two parameters:
;          Address of array to print
;          Number of values to print (DWORD)
;          Address of separator between values (a string address)
;returns: Uses writeVal to print unsigned values from the array.
;preconditions: All parameters need to be valid (so unsigned DWORDs).
;registers changed: None. (ECX/EDX preserved)
;~~~~~~~~~~~~~~~~~~
arrayPrinter PROC,
    ap_separator:DWORD,
    ap_array_size:DWORD,
    ap_array:DWORD
    
    push    edx
    push    ecx
    
    mov     edx, ap_array
    mov     ecx, ap_array_size
array_print_loop:
    push    [edx]          ; Directly push the integer to be printed.
    call    writeVal
    
    add     edx, 4         ; Go to the next DWORD address in the array.
    cmp     ecx, 1
    je      skip_separator ; To prevent the last separator from showing.
    
    displayString ap_separator
    
skip_separator:
    loop    array_print_loop
    
    call    CrLf           ; This is a line-printing procedure, so it should end with a CrLf.
    
    pop     ecx
    pop     edx
    
    ret
arrayPrinter ENDP


;~~~~~~~~~~~~~~~~~~
; introduction
;This was originally in the main procedure, but moved out because why not.
; The procedure does all the introductory printing.
;receives: Many strings to print, and one integer to print:
;          OFFSET program_intro
;          OFFSET by_line
;          OFFSET instruction1a
;          OFFSET instruction1b
;          OFFSET instruction2
;          OFFSET instruction3a
;          OFFSET instruction3b
;          the one integer to print (DWORD)
;          OFFSET ec_message (only one for now)
;returns: Uses displayString and writeVal to print stuff.
;preconditions: All parameters need to be valid.
;registers changed: None.
;~~~~~~~~~~~~~~~~~~
introduction PROC,
    id_ec:DWORD,
    id_number:DWORD,
    id_instr3b:DWORD,
    id_instr3a:DWORD,
    id_instr2:DWORD,
    id_instr1b:DWORD,
    id_instr1a:DWORD,
    id_byline:DWORD,
    id_intro:DWORD
    
    displayString id_intro
    call    CrLf
    displayString id_byline
    call    CrLf
    displayString id_ec
    call    Crlf
    call    CrLf
    
    displayString id_instr1a
    push    id_number
    call    writeVal
    displayString id_instr1b
    call    CrLf
    displayString id_instr2
    call    CrLf
    displayString id_instr3a
    call    CrLf
    displayString id_instr3b
    call    CrLf
    
    ret
introduction ENDP


;~~~~~~~~~~~~~~~~~~
; outroduction
;This was originally in the main procedure, but moved out because why not.
; The procedure does all the outroductory printing.
;receives: A few strings and integers to print.
;          OFFSET sum_title
;          OFFSET average_title
;          OFFSET thanks
;          user_sum (DWORD sum of array values)
;          user_average (DWORD average of array values)
;returns: Uses displayString and writeVal to print stuff.
;preconditions: All parameters need to be valid.
;registers changed: None.
;~~~~~~~~~~~~~~~~~~
outroduction PROC,
    od_average:DWORD,
    od_sum:DWORD,
    od_thanks:DWORD,
    od_average_title:DWORD,
    od_sum_title:DWORD

    displayString od_sum_title
    push    od_sum
    call    writeVal
    call    CrLf
    
    displayString od_average_title
    push    od_average
    call    writeVal
    call    CrLf
    call    CrLf
    
    displayString od_thanks
    call    CrLf
    
    ret
outroduction ENDP
    
END main
