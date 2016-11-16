TITLE Composite Numbers     (CompositePrime.asm)

;Albert Chang
;changal@oregonstate.edu
;CS271-400
;Assignment 4 (Program 4)
;Due 2016-2-14
;Description: This program takes a number from 1 to 400, then displays that many composite numbers.
; Composite numbers are positive numbers that are not prime and not 1.
; (1 is not prime, but it's also not composite. 1 is special.)
; The display is done with ten numbers to a line, and some alignment to look presentable.

INCLUDE Irvine32.inc

MAX_NUMBER      =       8000
MY_NAME         EQU     <"Albert Chang">
FALSE           =       0   ; This will be used for some boolean flags.
TRUE            =       1   ; It's not necessary, but it helps me to keep track of what I'm doing.

.data

program_intro   BYTE    "Composite Numbers     Programmed by ",MY_NAME,0
instruction1    BYTE    "Enter the number of composite numbers you would like to see.",0
instruction2a   BYTE    "I'll accept orders for up to ",0 ; MAX_NUMBER goes between 2a and 2b.
instruction2b   BYTE    " composites.",0

prompt_number   BYTE    "Enter the number of composites to display [1 .. ",0
prompt_close    BYTE    "]: ",0
error_msg       BYTE    "Out of range.  Try again.",0
prompt_colon    BYTE    ": ",0

ending_msg      BYTE    "Results certified by ",MY_NAME,".  Goodbye.",0

three_space     BYTE    "   ",0     ; for formatting
four_space      BYTE    "    ",0    ; for formatting
five_space      BYTE    "     ",0   ; for formatting
six_space       BYTE    "      ",0  ; for formatting

composite_flag  BYTE    FALSE ; Just using 0 and 1 for true and false, but this helps to make it explicit.
valid_flag      BYTE    FALSE ; Same idea here.
user_number     DWORD   ?
current_int     DWORD   1     ; Initialise to 1 (our loop adds 1 at the start of every time through so this works out to starting with 2).

line_breaker    DWORD   0     ; This fellow breaks lines.
page_breaker    DWORD   0     ; This fellow breaks hearts. Also pages.

array_size      DWORD   0           ; I don't ever use this, but I think it's good form to keep track of the numbers added to the array.
prime_array     DWORD   1200 DUP(2) ; I do use this array though. I just don't use the counter I set up for keeping track of the spots used.
; I don't know how to best handle dynamic arrays in MASM. I'm sorry about using a static array.
; This array is ridiculously large because there are about 1200 (rounded up) primes between 1 and the 8000th composite number. 
; Only about 100 of them will ever be used (because the prime/composite check stops after passing the square root of the integer).
; DUP(2) is because 2 is the smallest prime.


.code
main PROC

    call    introduction
    call    getUserData
    call    showComposites
    call    farewell
    
	exit	; exit to operating system
main ENDP


; introduction
;This procedure just introduces the program's purpose.
;receives: Nothing.
;returns: Nothing.
;preconditions; Nothing. (introductory strings have to exist though)
;registers changed: None. (EAX and EDX are used, but pushed beforehand and popped at the end)
introduction PROC
    push    edx
    push    eax

    mov     edx, OFFSET program_intro
    call    WriteString
    call    Crlf
    
    call    Crlf

    mov     edx, OFFSET instruction1
    call    WriteString
    call    Crlf
    
    mov     edx, OFFSET instruction2a
    call    WriteString
    mov     eax, MAX_NUMBER
    call    WriteDec
    mov     edx, OFFSET instruction2b
    call    WriteString
    call    Crlf
    call    Crlf
    
    pop     eax
    pop     edx
    ret
introduction ENDP
    
    
; getUserData
;This procedure takes the user input (one integer).
;receives: No arguments, but the user will be prompted for input.
;returns: Stores the user's number into a global variable named user_number.
;preconditions; Nothing in particular. valid_flag needs to exist (doesn't have to be initialised).
;registers changed: None. (EAX and EDX are pushed/popped)
getUserData PROC
    push    edx
    push    eax

re_prompting:
    mov     edx, OFFSET prompt_number
    call    WriteString
    mov     eax, MAX_NUMBER
    call    WriteDec
    mov     edx, OFFSET prompt_close
    call    WriteString
    call    ReadDec
    mov     user_number, eax
    call    validate
    cmp     valid_flag, TRUE
    jne     re_prompting
    
    pop     eax
    pop     edx
    ret
getUserData ENDP
    
    
; validate (just a getUserData subprocedure)
;This procedure validates the input from getUserData.
;receives: user_number is used for comparison, but it's taken as a global variable.
;returns: Changes the value of valid_flag to 1 if user_number is valid (ike a boolean flag).
;preconditions: user_number (the argument, kind of) is properly set beforehand (to some value).
;registers changed: None. (EDX pushed/popped)
validate    PROC
    push    edx

    mov     valid_flag, FALSE   ; This isn't really necessary, but set the flag to FALSE before checking just in case.
    cmp     user_number, 0
    jle     skip_valid_toggle
    cmp     user_number, MAX_NUMBER
    ja      skip_valid_toggle
    
    mov     valid_flag, TRUE    ; Check is essentially "if not invalid, set TRUE".
    jmp     skip_error_message
skip_valid_toggle:
    mov     edx, OFFSET error_msg
    call    WriteString
    call    Crlf

skip_error_message:
    pop     edx
    ret
validate    ENDP


; showComposites (for grading purposes, note that the 1 to n loop is in this procedure)
;This procedure checks numbers for composite-ness (with a sub-procedure) and prints them (with a sub-procedure)
; if they're composite up to a total of n numbers (n is specified by the user in the variable user_number).
;receives: Uses the user_number specified earlier. (Also needs several other global variables to function,
;          though they aren't really passed as arguments.)
;returns: Nothing returned, but prints composites to the console (the sub-procedure does the actual printing).
;preconditions: user_number is valid (within the program's specified range); current_int is initialised to 2;
;               composite_flag exists (doesn't need to be initialised).
;               prime_array and array_size need to exist.
;registers changed: None. (ECX, EAX, EDI pushed/popped)
showComposites  PROC
    push    ecx
    push    eax
    push    edi
    
    mov     edi, OFFSET prime_array

    call    Crlf
    mov     ecx, user_number        ; Though not mentioned yet, user_number is the "n" in "1 to n" composites.
number_loop:
    inc     current_int
    call    isComposite             ; isComposite just checks if current_int is composite and toggle flag to TRUE (1) if necessary.
    cmp     composite_flag, TRUE    ; This check makes sense because we're essentially checking for primality,
    je      printing_time           ;  and isComposite will toggle composite_flag if not prime.

    mov     eax, current_int        ; If prime, store the integer into EAX.
    mov     [edi], eax              ; Then store EAX into the next spot in the array.
    inc     array_size              ; Counting up the number of values stored into the array, even though I don't ever use this count.
    add     edi, 4                  ; Using DWORD, so increase the index by 4 bytes.
    jmp     number_loop             ; We don't decrement ECX if printing didn't occur (the user wants n composites, not composites up to n).
                                    ;  This is a nested loop, but they both lead to the same label.
printing_time:
    call    printComposites
    loop    number_loop
    
    call    Crlf
    call    Crlf
    
    pop     edi
    pop     eax
    pop     ecx
    ret
showComposites ENDP


; isComposite (kind of a showComposites sub-procedure)
;This procedure checks whether numbers are prime (but toggles a flag to indicate composite-ness).
;receives: Uses several integers as global variables (current_int, current_check). Also uses an
;          array for the extra credit (still global).
;returns: Toggles a global variable (composite_flag) to TRUE (integer 1) if necessary.
;preconditions: current_int is a positive number; current_check is initialised to 2.
;               composite_flag needs to exist. prime_array needs to contain valid primes up to or
;               past the square root of current_int. If it doesn't, this will be an infinite loop.
;               The only way to exit the loop is to reach a divisor greater than or equal to the
;               square root of curent_int.
;registers changed: None. (EDX, EBX, EAX, ESI pushed/popped)
isComposite PROC
    push    edx
    push    ebx
    push    eax
    push    esi
    
    mov     composite_flag, FALSE   ; Reset the flag to FALSE (just 0) before starting the check.
    mov     esi, OFFSET prime_array ; This is why we pushed ESI at the beginning. We're reusing it here.
    
composite_start:
    mov     ebx, [esi]          ; The divisor to be used is moved into EBX.
    
    mov     eax, ebx            ; We square the currently checked divisor, because we know that if the
    mul     eax                 ;  square is larger than the integer we're checking for primality, then
    cmp     eax, current_int    ;  the integer won't be divisible by any divisors above that.
    ja      composite_end       ; Leave the loop when we're past the square root.

    mov     eax, current_int
    xor     edx, edx
    div     ebx
    cmp     edx, 0          ; Compare the remainder to 0. If 0, we found a divisor and we're done.
    je      composite_found
    
    add     esi, 4          ; Same idea here as in showComposites. Using DWORD.
    jmp     composite_start
    
composite_found:    
    mov     composite_flag, TRUE   ; Only set the flag to true if necessary.
    
composite_end:
    pop     esi
    pop     eax
    pop     ebx
    pop     edx
    ret
isComposite ENDP

; An additional note here about showComposites and isComposite
;  I use EDI for showComposites because I'm storing data, and ESI for isComposite because I'm reading data.
;  I think this is why they're called "destination" and "source", but I'm not sure I'm using them correctly.
;  It's possible I have them switched up in my mind. The program runs fine though.


; printComposites
;This procedure prints composites according to the formatting guidelines specified in the assignment.
;(It doesn't need to be a separate procedure, but this makes things easier for me.)
;receives: Uses the current_int specified by showComposites.
;returns: Nothing returned, but prints composites to the console.
;preconditions: current_int is a valid number. It doesn't have to be composite though, as this procedure just
;               prints things. Two additional variables, line_breaker and page_breaker, need to be initialised to 0.
;registers changed: None. (EDX and EAX pushed/popped)
printComposites  PROC
    push    edx
    push    eax

    cmp     line_breaker, 10
    jb      line_break_done
    call    Crlf
    mov     line_breaker, 0
    
    cmp     page_breaker, 400
    jb      line_break_done
    call    Crlf
    call    WaitMsg
    mov     page_breaker, 0
    call    Crlf
    call    Crlf
    
line_break_done:
    inc     page_breaker
    inc     line_breaker
    mov     eax, current_int
    call    WriteDec
    
; This section is "one_digit", though it has no label.
    cmp     current_int, 9
    ja      two_digit
    mov     edx, OFFSET six_space
    call    WriteString
    jmp     done_spacing

two_digit:
    cmp     current_int, 99
    ja      three_digit
    mov     edx, OFFSET five_space
    call    WriteString
    jmp     done_spacing
    
three_digit:
    cmp     current_int, 999
    ja      four_digit
    mov     edx, OFFSET four_space
    call    WriteString
    jmp     done_spacing
    
four_digit:
    mov     edx, OFFSET three_space
    call    WriteString
    
done_spacing:
    pop     eax
    pop     edx
    ret
printComposites ENDP


; farewell
;This procedure just says goodbye.
;receives: Nothing.
;returns: Nothing.
;preconditions: Nothing. (ending message has to exist)
;registers changed: None (EDX and EAX pushed/popped)
farewell    PROC
    push    edx
    push    eax

    mov     edx, OFFSET ending_msg
    call    WriteString
    
    pop     eax
    pop     edx
    ret
farewell ENDP
    
END main
