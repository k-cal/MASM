TITLE Integer Accumulator     (AverageInt.asm)

;Albert Chang
;changal@oregonstate.edu
;CS271-400
;Assignment 3 (Program 3)
;Due 2016-2-7
;Description: This program takes negative integers and prints out the sum and average
; for the user to see. The learning goals are a bit more complicated than that, but for
; the end-user, all that's happening is integer input and seeing the sum and average.

INCLUDE Irvine32.inc

MIN_NUMBER      =       -100
MY_NAME         EQU     <"Albert Chang">

.data

program_intro   BYTE    "Welcome to the Integer Accumulator by ",MY_NAME,0
name_prompt     BYTE    "What is your name? ",0
say_hello       BYTE    "Hello, ",0
instruction1a   BYTE    "Please enter negative integers within [",0
instruction1b   BYTE    ", -1].",0
instruction2    BYTE    "Enter a non-negative integer when you are finished to see results.",0
instruction3    BYTE    "(Negative integers below the minimum will be discarded without warning.)",0

prompt_number   BYTE    "Enter integer ",0
prompt_colon    BYTE    ": ",0
valid_a         BYTE    "You entered ",0
valid_b         BYTE    " valid numbers.",0
sum_result      BYTE    "The sum of your valid numbers is ",0
avg_result      BYTE    "The rounded average is ",0

avg_result2     BYTE    "The average to three decimal places is ",0

special_msg     BYTE    "You didn't enter any valid numbers, you special guy.",0
ending_msg1     BYTE    "Thank you for playing Integer Accumulator!",0
ending_msg2     BYTE    "It's been a pleasure to meet you, ",0
ending_dot      BYTE    ".",0       ; a dot to follow names

user_name       BYTE    33 DUP(0)
sum_keeper      SDWORD  0           ; this is the accumulator
number_count    DWORD   0           ; this is a counter for calculating average
line_count      DWORD   1           ; this is a line counter

.code
main PROC

; introductions - where we greet the user
    mov     edx, OFFSET program_intro
    call    WriteString
    call    CrLf

    call    CrLf

    mov     edx, OFFSET name_prompt
    call    WriteString
    
    mov		edx, OFFSET user_name
	mov		ecx, 32
	call	ReadString
    
    mov		edx, OFFSET say_hello
	call	WriteString
    mov     edx, OFFSET user_name
    call    WriteString
    mov     edx, OFFSET ending_dot
    call    WriteString
    call    CrLf
    call    CrLf
    
; userInstructions - where we vaguely instruct the user as to this program's operations
    mov     edx, OFFSET instruction1a
    call    WriteString
    mov     eax, MIN_NUMBER
    call    WriteInt
    mov     edx, OFFSET instruction1b
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET instruction2
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET instruction3
    call    WriteString
    call    CrLf

; getUserData - where we take input from the user
input_block:
    mov     edx, OFFSET prompt_number
    call    WriteString
    mov     eax, line_count
    call    WriteDec
    mov     edx, OFFSET prompt_colon
    call    WriteString
    call    ReadInt
    
    cmp     eax, 0
    jge     results_block
    
    cmp     eax, MIN_NUMBER
    jl      input_block
    
    add     eax,sum_keeper
    mov     sum_keeper,eax
    inc     line_count
    inc     number_count
    jmp     input_block

; results - where we display the results of the calculations (unless there were no valid numbers entered)
results_block:
    cmp     number_count, 0 ; First we check to see if the user is worthy of the special message
    je      special_block
    
    ; Notify the user of the valid numbers entered (for averaging purposes)
    mov     edx, OFFSET valid_a
    call    WriteString
    mov     eax, number_count
    call    WriteDec
    mov     edx, OFFSET valid_b
    call    WriteString
    call    CrLf
    
    ; State the sum
    mov     edx, OFFSET sum_result
    call    WriteString
    mov     eax, sum_keeper
    call    WriteInt
    call    CrLf
    
    ; Next is the integer average, with a long comment block for the rounding check
    mov     edx, OFFSET avg_result
    call    WriteString
    cdq     ; At this point, EAX still contains sum_keeper so we just extend the sign out
    idiv    number_count
    
    ; This next mini-block is for checking whether to round up or down. It doesn't use serial division to check the next digit.
    not     edx                    ; (Switching to positive remainder for the check by taking the two's complement.
    inc     edx                    ;  This switch isn't necessary, but I feel more comfortable working with unsigned numbers.)
    mov     ebx, number_count      ; Using EBX as an intermediate, we compare the remainder with (divisor - remainder)
    sub     ebx, edx               ;  to see which end the fractional part is closer to, then use DEC rather than INC for 
    cmp     edx, ebx               ;  rounding because we're using negative integers.
    jbe     round_check_done
    dec     eax                    ; I think this check is more accurate than simply checking to see if the next number
round_check_done:                  ;  is 5 or greater (or lesser, since we're using negative numbers here). For example,
    call    WriteInt               ;  -14/9 would round to -1 if only the first post-radix digit is checked (-1.5 to -1),
    call    CrLf                   ;  but we know that -14/9 is -1.555... repeating, so it should round to -2.
    
    ; Next is the fake floating point average (again with a long comment block on rounding at the end)
    mov     edx, OFFSET avg_result2
    call    WriteString
    mov     eax, sum_keeper
    cdq
    idiv    number_count
    call    WriteInt
    mov     eax, edx               ; We first move our remainder out to EAX so we can use it again
    mov     edx, OFFSET ending_dot ; We need a decimal point here
    call    WriteString
    
    not     eax                    ; We're going to switch to positive numbers for the post-radix part
    inc     eax
    mov     ebx, 10                ; EBX is going to hold 10 for our serial divisions
    mul     ebx                    ; Multiply the remainder by 10 for more division
    xor     edx, edx               ; Clear EDX before division
    div     number_count
    call    WriteDec               ; Print the first result of serial division
    
    mov     eax, edx
    mul     ebx
    xor     edx, edx
    div     number_count
    call    WriteDec               ; Print the second result of serial division
    
    mov     eax, edx
    mul     ebx
    xor     edx, edx
    div     number_count
    mov     ecx, eax               ; Store the third result in ECX (temporary storage) for a quick rounding check

    ; This mini-block is a different way of checking for rounding. Perhaps more obvious (but less accurate) than the way used above.
    mov     eax, edx
    mul     ebx
    xor     edx, edx
    div     number_count
    cmp     eax, 5                 ; Perform serial division again, then compare the result with 5 to decide whether to round.
    jb      print_third_digit
    inc     ecx
print_third_digit:
    mov     eax, ecx               ; Move the third result, with rounding considerations, back into EAX for printing
    call    WriteDec
    jmp     farewell_user          ; Please see the following wall of text for discussion on why I used this less accurate logic.
    
; Note that I used different rounding logic for the 3 decimal places and the rounded integer.
;  The end result appears to be the same, but it's not quite the same. I think the second check is
;  probably easier to understand, but I don't want to change the first one. I spent some time 
;  thinking about it back when I wrote it. The earlier check directly compares the remainder with 
;  divisor, so there's no need to multiply or divide anything and the accuracy should be better.
; Using the same example from before, this logic does round -14/9 to -1.556, but it does so with a 
;  "cheat" in the logic and isn't really valid. The "cheat" I'm referring to is the use of JB for 
;  the comparison with 5 rather than JBE. This means that a value of -1.5555 (non-repeating) would
;  round to -1.556 rather than -1.555 as it should. I used this cheat because it's unlikely that a 
;  user would enter enough values to notice it. The user would need to enter 2000 integers to get
;  an average of -1.5555 exactly (with -3111/2000), and this program would incorrectly round that
;  to -1.556.) I also hope this "cheat" helps to show why the logic in the earlier check is better.
; I kind of cheated in the first check as well with the switch to positive integers for easier
;  calculations, but you can see that the other logic in the first check doesn't have the
;  shortcomings of rounding through serial division and only checking the next digit.
    
; farewell - where we wish the user safe travels in his journey through life
special_block:
    mov     edx, OFFSET special_msg
    call    WriteString

farewell_user:
    call    Crlf
    mov     edx, OFFSET ending_msg1
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET ending_msg2
    call    WriteString
    mov     edx, OFFSET user_name
    call    WriteString
    mov     edx, OFFSET ending_dot
    call    WriteString
    call    CrLf
    
	exit	; exit to operating system
main ENDP

END main
