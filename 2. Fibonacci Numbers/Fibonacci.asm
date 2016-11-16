TITLE Fibonacci Numbers     (Fibonacci.asm)

;Albert Chang
;changal@oregonstate.edu
;CS271-400
;Assignment 2 (Program 2)
;Due 2016-1-24
;Description: This program calculates the first n Fibonacci numbers, where n is specified
; by the user. n can only go up to 46 because we are using DWORD data and the 47th number
; just won't fit in a DWORD. (I think the 47th number actually does fit, but the MSB will
; be 1 and this could cause confusion over whether the data is meant to be a signed or
; unsigned value.)

INCLUDE Irvine32.inc

MAX_NUMBER      =       46
MY_NAME         EQU     <"Albert Chang">

.data

program_title   BYTE    "Fibonacci Numbers",0
by_line         BYTE    "Programmed by ",MY_NAME,0
name_prompt     BYTE    "What's your name? ",0
say_hello       BYTE    "Hello, ",0
instruction1    BYTE    "Enter the number of Fibonacci terms to be displayed",0
instruction2    BYTE    "Give the number as an integer in the range [1 .. ",0
closing_brack   BYTE    "]",0
prompt_number   BYTE    "How many Fibonacci terms do you want? ",0
error_msg       BYTE    "Out of range. Enter a number in [1 .. ",0
ending_msg      BYTE    "Results certified by ",MY_NAME,".",0
say_goodbye     BYTE    "Goodbye, ",0
really_goodbye  BYTE    "I really mean it this time.",0

dot_string      BYTE    ".",0       ; because sometimes you need a dot

eight_space     BYTE    "        ",0; for formatting (inefficient formatting)
seven_space     BYTE    "       ",0 ; for formatting
six_space       BYTE    "      ",0  ; for formatting
five_space      BYTE    "     ",0   ; for formatting
four_space      BYTE    "    ",0    ; for formatting
three_space     BYTE    "   ",0     ; for formatting
two_space       BYTE    "  ",0      ; for formatting
one_space       BYTE    " ",0       ; for formatting
current_num     BYTE    0           ; for number counting

repeat_msg1     BYTE    "But wait. Enter 0 at the next prompt if you want to repeat the program",0
repeat_msg2     BYTE    "with the original functionality, enter 1 to repeat the program with a",0
repeat_msg3     BYTE    "very slight change, or just enter any other integer to quit the program.",0
repeat_prompt   BYTE    "Your choice? ",0
ec2_choice      DWORD   0           ; kind of like a boolean check, but not really

ec2_desc1       BYTE    "The very slight change is the program can display a specific Fibonacci term.",0
ec2_desc2       BYTE    "For example, entering 46 would display the 46th term.",0
ec2_desc3       BYTE    "This saves a bit of clutter. But we still can't go higher than ",0
ec2_prompt      BYTE    "Which term do you want to see? ",0


fibb_temp1      DWORD   1           ; the two fibb_temp variables store numbers as they're calculated and they
fibb_temp2      DWORD   0           ;  should allow the loop to work properly for showing the first two numbers
line_counter    DWORD   0           ; an extra variable to count to five and reset (for line breaks)

user_name       BYTE    33 DUP(0)   ; the user's name; I assume 32 characters is a good length for a name field
user_number     DWORD   ?           ; the integer to be entered by user

; An additional comment about the "fibb_temp" variables:
;  The 0 is first stored in the second because my code first adds the two variables to the eax register and
;  prints to show the new number. Then fibb_temp2 is moved to fibb_temp1 (using ebx as an intermediate) and the
;  current number in eax is moved to fibb_temp1. The way this works out, the contents of the two variables will
;  be, in order, 1,0, 0,1, 1,1 and so on.
;  I just noticed that I spelled Fibonacci's name wrong with two "b" everywhere. I fixed it in the comments,
;  but I'll just pretend it was a stylistic choice for the variable names.

; Other thoughts about incredible things:
;  Special things that we can do now include formatting the text in different colors (perhaps changing as the
;  values increase) or displaying in hexadecimal or binary. These don't really seem incredible to me though,
;  because they just involve using more of Irvine's library and don't actually make the program more useful.
;  That is, displaying the values as a rainbow doesn't actually do anything in terms of the information
;  presented, and displaying them in hexadecimal or binary actually makes them harder to read. I'm assuming 
;  even advanced programmers still find decimal numbers easier to read than hexadecimal and binary. So without
;  trying to create flashy visual effects that don't really affect functionality in any way, all the additions
;  I could really think of are the following:
;
;  Allow users to select and display one number if they want to know the n-th term for some reason (which I did)
;  Allow the user to enter a number and tell them which term it is in the sequence
;  Figure out a way to use QWORD and make the program able to run a lot longer
;
;  The last option is a bit beyond me right now (I'm not sure it's even possible to use QWORD in 32-bit
;  programs without some advanced understanding of how to format and store data, like chopping the QWORD into
;  two DWORD, performing the addition on them seperately while accounting for carries, and then printing them
;  somehow without using Irvine's WriteDec procedure because WriteDec only prints the contents of EAX.) The
;  second option shouldn't be too hard to implement, but it requires first generating and storing the 46
;  numbers we have into an array (rather than generating them "on the fly" with a loop block only for as much
;  as the user desires), then comparing the user's input to each value in the array. This seems like a waste of
;  time (realistically, who would think "I remember 2178309 is a  Fibonacci number, but I just can't remember
;  which one it is"?) so I didn't really want to code that option either. So while my small addition to the
;  program is not quite incredible, it's the only possibly useful (and feasible, because the shift to QWORD
;  would definitely be more useful but I'm not sure I can handle that) addition I could think of. I would
;  definitely want to know about any incredibly useful functions added by other students in the past later,
;  because I don't think my addition is worthy of being called incredible.

.code
main PROC

; introductions - where we greet the user
    mov     edx, OFFSET program_title
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET by_line
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
    
title_skip: ; I think it's unnecessary to keep having the title appear on repeat passes through the program
    call   CrLf
    cmp    ec2_choice, 1
    je     instruction_alt
    
; userInstructions - where we instruct the user as to this program's operations
    mov     edx, OFFSET instruction1
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET instruction2
    call    WriteString
    mov     eax, MAX_NUMBER           ; I print "MAX_NUMBER" instead of just having "46" in the string because Paul
    call    WriteDec                  ;  mentioned using the constant for both user instructions and validation. I think
    mov     edx, OFFSET closing_brack ;  his idea is probably a better practice than having the number in the string.
    call    WriteString
    mov     edx, OFFSET dot_string
    call    WriteString
    call    CrLf
    
    call    CrLf
    
    jmp     validation_block ; This jump is only necessary because of the alternate instruction block below
    
; userInstructions(alternative) - where we instruct the user as to this program's operations
instruction_alt:
    mov     edx, OFFSET ec2_desc1
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET ec2_desc2
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET ec2_desc3
    call    WriteString
    mov     eax, MAX_NUMBER
    call    WriteDec
    mov     edx, OFFSET dot_string
    call    WriteString
    call    CrLf
    
    call    CrLf

; getUserData - where we take input from the user
validation_block:
    cmp     ec2_choice, 1    ; This is still a post-test loop, the ec2_choice value is just for the slight twist
    je      alternate_prompt ; I thought it would be bad to have an inaccurate prompt, so I made a special prompt
    mov     edx, OFFSET prompt_number
    jmp     prompt_done
alternate_prompt:                  ; This alternate prompt is for the slight twist, but the actual
    mov     edx, OFFSET ec2_prompt ;  validation process is still the same
prompt_done:    
    call    WriteString
    call    ReadInt
    mov     user_number, eax    ; The actual test for the loop starts below here
    cmp     eax, 1              ; First check if the number is too low,
    jb      error_block
    cmp     eax, MAX_NUMBER     ; then check if the number is too high,
    jbe     validation_done     ; and skip the error block if the number is valid
error_block:
    mov     edx, OFFSET error_msg
    call    WriteString
    mov     eax, MAX_NUMBER
    call    WriteDec
    mov     edx, OFFSET closing_brack
    call    WriteString
    call    CrLf
    jmp     validation_block

; displayFibs - where we display the numbers in Fibonacci's sequence
validation_done:
    call    CrLf
    
    mov     ecx, user_number
    cmp     ec2_choice, 1
    je      fibb_loop_alt   ; For the slight twist, we use a different block of code (that is mostly identical)
    
fibb_loop:
    mov     eax, fibb_temp1 ; In case it's not entirely clear what I'm doing, I always move fibb_temp2 to fibb_temp1
    add     eax, fibb_temp2 ;  and eax to fibb_temp2 after each number is calculated and printed because having
    mov     ebx, fibb_temp2 ;  fibb_temp1 and fibb_temp2 initialised to 1 and 0 respectively allows me to "repeat"
    mov     fibb_temp1, ebx ;  the first step of the calculation for the first two times through the loop
    mov     fibb_temp2, eax 
    call    WriteDec
    mov     edx, OFFSET five_space
    call    WriteString
    inc     current_num ; We're only counting the numbers as they're printed for the extra credit
    jmp     ec_check    ; The ec_check block is still "within" the loop, but it breaks the
                        ;  "loop" instruction (too long a loop) so it had to be moved out
line_check: ; We figure out when to have line breaks with a simple counter that resets every five numbers
    cmp     ecx, 1
    je      end_of_fibb_loop ; This check just helps to avoid an extra line break if the user chose a multiple of five
    
    inc     line_counter     ; This counter is for the actual line break check
    cmp     line_counter, 5
    jne     end_of_fibb_loop
    call    CrLf
    mov     line_counter, 0  ; When it reaches five, a line break happens and it is reset to 0

end_of_fibb_loop:
    loop    fibb_loop
    jmp     farewell_user

; The next part is for the extra credit columns, and may seem kind of silly.
;  I'm not sure how to handle cursor movement properly, so I am adding spaces "manually"
;  based on how many numbers in we are. I have it outside of the "fibb_loop" because these
;  checks are so long that they make the loop too long for the "loop" instruction to work,
;  but in terms of the flow through the code they are still within the loop.
ec_check:
    cmp     current_num, 6
    ja      two_digit
    mov     edx, OFFSET eight_space
    call    WriteString
    jmp     line_check
two_digit:
    cmp     current_num, 11
    ja      three_digit
    mov     edx, OFFSET seven_space
    call    WriteString
    jmp     line_check
three_digit:
    cmp     current_num, 16
    ja      four_digit
    mov     edx, OFFSET six_space
    call    WriteString
    jmp     line_check
four_digit:
    cmp     current_num, 20
    ja      five_digit
    mov     edx, OFFSET five_space
    call    WriteString
    jmp     line_check
five_digit:
    cmp     current_num, 25
    ja      six_digit
    mov     edx, OFFSET four_space
    call    WriteString
    jmp     line_check
six_digit:
    cmp     current_num, 30
    ja      seven_digit
    mov     edx, OFFSET three_space
    call    WriteString
    jmp     line_check
seven_digit:
    cmp     current_num, 35
    ja      eight_digit
    mov     edx, OFFSET two_space
    call    WriteString
    jmp     line_check
eight_digit:
    cmp     current_num, 40
    ja      line_check
    mov     edx, OFFSET one_space
    call    WriteString
    jmp     line_check
    
; displayFibsAlternate - where we display only one number in Fibonacci's sequence
fibb_loop_alt:
    mov     eax, fibb_temp1
    add     eax, fibb_temp2
    cmp     ecx, 1
    jne     skip_write ; This jump is the main difference with the slight twist
    call    WriteDec
skip_write:
    mov     ebx, fibb_temp2
    mov     fibb_temp1, ebx
    mov     fibb_temp2, eax
    inc     current_num

    loop    fibb_loop_alt
    jmp     farewell_user
; I realise the simple "skip_write" check can be done within the primary displayFibs section, but I worried
;  that the slightly different logic (losing the checks for spacing and gaining a check for just not writing)
;  might cause unintended behavior. The main thing consideration is implementing additional checks for whether
;  to skip or not skip (because the idea would be to skip most of the loop until the final number is reached)
;  would require a nested conditional that I'm not sure I can pull off correctly. Simply having a different
;  block of code probably takes less lines of code overall.
    
; farewell - where we wish the user safe travels in his journey through life
farewell_user:
    call    CrLf
    call    CrLf
    
    mov     edx, OFFSET ending_msg
    call    WriteString
    call    CrLf
    
    mov		edx, OFFSET say_goodbye
	call	WriteString
    mov     edx, OFFSET user_name
    call    WriteString
    mov     edx, OFFSET dot_string
    call    WriteString
    call    CrLf
    
    call    CrLf

    mov		edx, OFFSET repeat_msg1 ; the following block prompts the user to maybe repeat the program
	call	WriteString
    call    CrLf
    
    mov     edx, OFFSET repeat_msg2
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET repeat_msg3
    call    WriteString
    call    CrLf
    
    mov     edx, OFFSET repeat_prompt
    call    WriteString
    
    call    ReadInt
    cmp     eax, 1
    ja      really_quit
    cmp     eax, 0
    jb      really_quit
    
; If the user decides to repeat the program, we reinitialise a few values before going back to the beginning
    mov     ec2_choice, eax     ; We also keep track of the program's alternative option
    mov     fibb_temp1, 1
    mov     fibb_temp2, 0
    mov     current_num, 0
    mov     line_counter, 0
    jmp     title_skip
    
really_quit:
    call    CrLf
    mov		edx, OFFSET say_goodbye
	call	WriteString
    mov     edx, OFFSET user_name
    call    WriteString
    mov     edx, OFFSET dot_string
    call    WriteString
    call    CrLf
    
    call    CrLf
    mov     edx, OFFSET really_goodbye
    call    WriteString
    
	exit	; exit to operating system
main ENDP

END main
