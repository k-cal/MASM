TITLE Sorting Random Integers     (RandomMerge.asm)

;Albert Chang
;changal@oregonstate.edu
;CS271-400
;Assignment 5 (Program 5)
;Due 2016-2-28
;Description: This program takes a number from 10 to 200, then generates that many random integers
; into an array. The random integers will be within the range of 100 to 999. The array is displayed,
; sorted, and displayed again, along with the median value (this is displayed before the sorted
; array, but calculated after the sorting for obvious reasons). The display is done with ten 
; numbers to a line, and some alignment to look presentable.

INCLUDE Irvine32.inc

MAX_REQUEST     =       200
MIN_REQUEST     =       10
MAX_RANGE       =       999
MIN_RANGE       =       100
MY_NAME         EQU     <"Albert Chang">

; The following symbols are just to make things clearer in the recursive merge sort procedure (valueCompare)
;  later on. They aren't necessary, and we could easily do without them (just have [ebp - #] as necessary)
;  in the procedure, but having these symbols makes the code easier to read. Easier to write too.
L_index         EQU     DWORD PTR [ebp - 4]
R_index         EQU     DWORD PTR [ebp - 8]
T_index         EQU     DWORD PTR [ebp - 12]
distance        EQU     DWORD PTR [ebp - 16]
midpoint        EQU     DWORD PTR [ebp - 20]
; I'm still good about not having global variables. I use strings as global variables only because the
;  instructions specifically say it's allowed. I might be better off making them constants like these local
;  variable symbols, but I don't think it matters too much.

.data

program_intro   BYTE    "Sorting Random Integers               Programmed by ",MY_NAME,0
instruction1a   BYTE    "This program generates random numbers in the range [",0
instruction1b   BYTE    "],",0
instruction2    BYTE    "displays the list, sorts the list (in descending order), and calculates the",0
instruction3    BYTE    "median value. Finally, it displays the sorted list (in descending order).",0

ec_message      BYTE    "**EC: Used merge sort (recursive algorithm)",0

doubledot       BYTE    " .. ",0

prompt_number   BYTE    "How many number should be generated [",0
prompt_close    BYTE    "]: ",0
error_msg       BYTE    "Invalid input",0

unsorted_title  BYTE    "The unsorted random numbers:",0
sorted_title    BYTE    "The sorted list:",0
median_msg      BYTE    "The median is ",0
singledot       BYTE    ".",0

three_space     BYTE    "   ",0     ; for formatting

;line_breaker    DWORD   0 ; This fellow is now a local variable or something. His service is no longer needed.
; He served his purpose well, breaking lines whenever they got too long. We will never forget his contributions.

array_size      DWORD   ?         ; This will be user input
int_array       DWORD   MAX_REQUEST DUP(0); Filled with 0 so we can easily see if there's a mistake (minimum value is 100).
temp_array      DWORD   MAX_REQUEST DUP(0); This array is a temporary array for working with merge sort "in place".

; I consulted an outside source for ideas on how to approach merge sort in MASM.
; Here's the link: http://www.cprogramming.com/tutorial/computersciencetheory/merge.html
; That's not assembly language, but the concepts transfer just fine.

.code
main PROC
; Randomise early, even before the intro.
    call    Randomize 
; Say hello.
    call    introduction
    
    call    CrLf
; Get the request.
    push    OFFSET array_size
    call    getUserData
    
    call    CrLf
; Fill the array.
    push    OFFSET int_array
    push    array_size
    call    fillArray
; Print the array.
    push    OFFSET int_array
    push    array_size
    push    OFFSET unsorted_title
    call    printArray
    
    call    CrLf
    call    CrLf
; Sort the array.
    push    OFFSET int_array
    push    array_size
    push    OFFSET temp_array ; Note that my merge sort implementation uses two arrays to avoid needing heap allocation.
    call    mergeSort         ; See the long comment at the end of the file to understand more about why this helps.
; Calculate and print the median.
    push    OFFSET int_array
    push    array_size
    call    showMedian
    
    call    CrLf
; Print the sorted array.
    push    OFFSET int_array
    push    array_size
    push    OFFSET sorted_title
    call    printArray
    
    call    CrLf
    
	exit	; exit to operating system
main ENDP


;~~~~~~~~~~~~~~~~~~
; introduction
;This procedure just introduces the program's purpose.
;receives: Nothing.
;returns: Nothing.
;preconditions: Nothing. (introductory strings have to exist though)
;registers changed: None. (EAX and EDX are pushed/popped)
; EBP isn't used at all because there's nothing really going on here.
;~~~~~~~~~~~~~~~~~~
introduction PROC
    push    edx
    push    eax

    mov     edx, OFFSET program_intro
    call    WriteString
    call    Crlf
    
    mov     edx, OFFSET ec_message
    call    WriteString
    call    CrLf
    call    Crlf
    
    mov     edx, OFFSET instruction1a
    call    WriteString
    mov     eax, MIN_RANGE
    call    WriteDec
    mov     edx, OFFSET doubledot
    call    WriteString
    mov     eax, MAX_RANGE
    call    WriteDec
    mov     edx, OFFSET instruction1b
    call    WriteString
    call    Crlf
    
    mov     edx, OFFSET instruction2
    call    WriteString
    call    Crlf
    
    mov     edx, OFFSET instruction3
    call    WriteString
    call    Crlf
    
    
    pop     eax
    pop     edx
    ret
introduction ENDP


;~~~~~~~~~~~~~~~~~~
; getUserData
;This procedure takes the user input (one integer).
;receives: Takes a stack parameter (reference) of an address that user input will be stored into.
;returns: Stores the user's number into the address passed in as a stack parameter.
;preconditions: Nothing in particular. The stack parameter should properly reference an address to store a DWORD.
;registers changed: None. (EAX and EDX pushed/popped; EBP pushed/popped for stack frame)
;~~~~~~~~~~~~~~~~~~
getUserData PROC
    push    ebp
    mov     ebp, esp

    push    edx
    push    eax

    jmp     prompting
    
; This is a slight cheat I'm using to avoid having special logic to print the error message.
; Instead of checking if it needs to be printed, it's printed by default but skipped the first time.
; The end result is the same to the end user, but much less coding work for me.
re_prompting:
    mov     edx, OFFSET error_msg
    call    WriteString
    call    CrLf
    
prompting:
    mov     edx, OFFSET prompt_number
    call    WriteString
    mov     eax, MIN_REQUEST
    call    WriteDec
    mov     edx, OFFSET doubledot
    call    WriteString
    mov     eax, MAX_REQUEST
    call    WriteDec
    mov     edx, OFFSET prompt_close
    call    WriteString
    
    call    ReadDec
    
    ; Reprompt if too low or too high.
    cmp     eax, MIN_REQUEST
    jb      re_prompting
    cmp     eax, MAX_REQUEST
    ja      re_prompting

    mov     edx, [ebp + 8] ; I know it's unusual to use EDX over ESI or EDI, but I wanted to minimise
    mov     [edx], eax     ;  the total registers used. This procedure uses only EAX and EDX (EBP too).
    
    pop     eax
    pop     edx
    
    pop     ebp
    ret     4
getUserData ENDP


;~~~~~~~~~~~~~~~~~~
; fillArray
;This procedure fills an array with pseudorandom numbers in a specified range (global constant specified).
;receives: Takes two stack parameters in the following order:
;          address of array to store integers (reference)
;          size of array (or just amount of integers to fill) (value)
;returns: Fills the array passed in as a stack parameter.
;preconditions: The stack parameters should be valid (valid DWORD array, valid size)
;registers changed: None. (EAX, ECX, EDI pushed/popped; EBP pushed/popped for stack frame)
;~~~~~~~~~~~~~~~~~~
fillArray PROC
    push    ebp
    mov     ebp, esp

    push    edi
    push    ecx
    push    eax
    
    mov     ecx, [ebp + 8]  ; Aside from in the merge sort recursive function (called valueCompare),
    mov     edi, [ebp + 12] ;  I generally don't bother with names for local variables. I find the 
                            ;  parameter list a bit confusing (in what exactly it generates) so I
                            ;  prefer just keeping track of stack offsets by myself.
fill_loop:
    mov     eax, MAX_RANGE
    sub     eax, MIN_RANGE
    inc     eax             ; RandomRange goes to n-1 (n in EAX), so we add 1.
    call    RandomRange
    add     eax, MIN_RANGE
    mov     [edi], eax
    add     edi, 4
    loop    fill_loop
    
    pop     eax
    pop     ecx
    pop     edi
    
    pop     ebp
    ret     8
fillArray ENDP


;~~~~~~~~~~~~~~~~~~
; printArray
;This procedure prints the contents of an integer array (ten to a line)
;receives: Takes three stack parameters in the following order:
;          address of array to store integers (reference)
;          size of array (or just amount of integers to print) (value)
;          address of a string to serve as title for array (reference)
;returns: Prints the array to console (nothing returned).
;preconditions: The stack parameters should be valid (valid DWORD array, valid size, valid string)
;registers changed: None. (EAX, EBX, ECX, EDX, EDI pushed/popped; EBP pushed/popped for stack frame)
;~~~~~~~~~~~~~~~~~~
printArray PROC
    push    ebp
    mov     ebp, esp

    push    edi
    push    edx
    push    ecx
    push    ebx
    push    eax
    
    mov     edx, [ebp + 8]  ; We first use EDX to print the title.
    call    WriteString
    call    CrLf
    
    mov     ecx, [ebp + 12]
    mov     edi, [ebp + 16]
    mov     ebx, 0          ; We're going to use EBX as the line_breaker now.
                            ; The former line_breaker will always live on in our hearts.
                            
    mov     edx, OFFSET three_space ; We go ahead and take care of EDX first, outside the loop.

print_loop:
    inc     ebx
    mov     eax, [edi]
    call    WriteDec
    call    WriteString ; Recall that EDX already has the address of three_space.
                        ; This does not change throughout the loop.    
    cmp     ebx, 10     ; EBX is taking over the role of line_breaker the best it can.
    jb      no_break    ; It has big shoes to fill.
    
    cmp     ecx, 1      ; We also skip the break if we're at the final iteration through the loop.
    je      no_break
    
    call    CrLf
    mov     ebx, 0
    
no_break:
    add     edi, 4
    loop    print_loop
    
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    pop     edi
    
    pop     ebp
    ret     12
printArray ENDP


;~~~~~~~~~~~~~~~~~~
; mergeSort
;This procedure sorts an integer array (from big to small, not small to big)
;receives: Takes three stack parameters in the following order:
;          address of array to store integers (reference)
;          size of array (or just amount of integers to print) (value)
;          address of a second array (identical to first) to work with (reference)
;returns: Sorts the array that was passed in by reference.
;preconditions: The stack parameters should be valid (two valid DWORD arrays, valid size)
;registers changed: None. (EAX pushed/popped; EBP pushed/popped for stack frame)
;~~~~~~~~~~~~~~~~~~
mergeSort PROC
    push    ebp
    mov     ebp, esp

    push    eax
    
    mov     eax, [ebp + 16] ; This procedure takes its parameters and directly passes them
    push    eax             ;  to the next procedure to do the actual work.
    mov     eax, 0
    push    eax
    mov     eax, [ebp + 12]
    push    eax
    mov     eax, [ebp + 8]
    push    eax
    
    call    valueCompare ; You may have noticed that mergeSort is just a wrapper procedure
                         ;  that calls valueCompare, so its existence isn't necessary.
    pop     eax          ;  I think having a wrapper here is preferable because it helps
                         ;  to hide some of the inner workings of the merge sort from the
    pop     ebp          ;  user. It simplifies things a bit. All the user needs to know is
    ret     12           ;  to pass the array, the array's size, and an identically sized
mergeSort ENDP           ;  dummy array to mergeSort.


;~~~~~~~~~~~~~~~~~~
; valueCompare
;This procedure is the "heart of the merge sort" as I have mentioned below in my old Python code.
; Unlike my Python code though, it takes indices as parameters because this version isn't going to
; keep creating new arrays recursively (I'm thinking avoiding use of the heap is preferable). The
; parameters indices are given labels for use within the procedure this time. I have a feeling things
; will get confusing otherwise in a recursive procedure.
;receives: Takes four stack parameters in the following order:
;          address of array to store integers (reference)
;          the "left" side index of the array (value)
;          the "right" side inded of the array (value)
;          address of a second array (identical to first) to work with (reference)
;returns: Sorts the array that was passed in by reference.
;preconditions: The stack parameters should be valid (two valid DWORD arrays, valid indices)
;registers changed: None. (EAX, EBX, ECX, EDX, EDI, ESI pushed/popped; EBP pushed/popped for stack frame)
;~~~~~~~~~~~~~~~~~~
valueCompare PROC,
    v_temp_array:PTR DWORD,
    v_right:DWORD,
    v_left:DWORD,
    v_main_array:PTR DWORD
    ; I also need local variables, but LOCAL confuses me so I'll handle it myself.
    ; I have some EQU symbols up above to serve as variable names that you may have noticed.
    ; I use the "v_" prefix so I don't get confused. But I don't use them for the local variables
    ;  I made symbols for way back at the top of the file. Maybe not very consistent, but we can
    ;  still read the code just fine so it's all good.
    
    sub     esp, 20 ; Space for five local DWORDs: three index counters, midpoint, and distance.
    
    push    esi     ; I don't like using PUSHAD. The offsets make the stack frame strange (no more EBP + 8).
    push    edi     ; So I will keep pushing everything in my own preferred order.
    push    edx     ; 
    push    ecx     ; I made space for the local variables before pushing the registers so that the offsets
    push    ebx     ;  from EBP are easier to remember and use.
    push    eax
         
; Check for base case. (If the two indices are within 1 of each other, it means we have a 1-length array.)
    mov     eax, v_left
    inc     eax            ; We don't "INC v_left" because that would be really counter-productive.
    cmp     eax, v_right
    je      recursion_done ; A 1-length array has nothing to sort.
    
; Find midpoint for recursion fun. This is a basic feature of any merge sort implementation.
    mov     eax, v_right
    sub     eax, v_left
    mov     distance, eax ; Store the distance between right and left for later use.
    xor     edx, edx      ; Always remember to clear EDX before 32-bit division. (No sign extension because unsigned DIV.)
    mov     ebx, 2
    div     ebx
    mov     midpoint, eax ; midpoint now holds the middle index. EDX holds 1 or 0, but we ignore it for now.
    
    mov     eax, v_left
    mov     L_index, eax  ; Initialising some local variables, now that we have the midpoint.
    add     eax, midpoint
    mov     R_index, eax  ; L_index will count up for the left half, R_index for the right half.
    
; The next two blocks are just pushing arguments for recursive calls using the left and right halves of the array.
    push    v_main_array
    mov     eax, v_left
    push    eax           ; I could just push v_left directly, but this looks nice, and we're going to move it into EAX anyway.
    add     eax, midpoint ; We moved v_left into EAX because we have to add the midpoint.
    push    eax           ; This is the recursive right, which is just v_left + midpoint.
    push    v_temp_array
    call    valueCompare  ; Recursively call the procedure for the left half.
    
    push    v_main_array
    push    eax          ; This left is the same as the right above (v_left + midpoint) if I handled register PUSH/POP correctly.
    push    v_right      ; This is the even righter right. More righteous than v_left + midpoint
    push    v_temp_array
    call    valueCompare ; Recursively call the procedure for the right half.
    
    mov     ecx, distance ; The next loop will really go the distance.
                        
    mov     T_index, 0    ; This is the last index local variable we made space for earlier.

compare_loop_start:
    mov     esi, L_index    ; I'm using ESI for left, EDI for right.
    mov     edi, R_index    ; They aren't used as source and destination in this loop.

    mov     edx, v_left     ; Check to see if we reached the end of the left-side portion first.
    add     edx, midpoint
    cmp     esi, edx
    jae     insert_right
    
    cmp     edi, v_right    ; Next check to see if we're done with the right-side portion.
    jae     insert_left
    
    mov     edx, v_main_array    ; EDX is used to hold array address.    
    mov     eax, [edx + esi*4]   ; Again, EAX and EDX[ESI] are for left side
    mov     ebx, [edx + edi*4]   ; EBX and EDX[EDI] are for right side
    cmp     eax, ebx
    jb      insert_right
    
insert_left:
    mov     edx, v_main_array ; There is some repeated code here because the earlier checks could skip
    mov     eax, [edx + esi*4];  past the comparison (have to make sure the right values are in EAX and EBX).
    
    inc     L_index
    mov     edx, v_temp_array  ; We have to work with the temporary array to insert.
    mov     edi, T_index       ; We use the EDI register that was used for the other side.
    mov     [edx + edi*4], eax ; EAX is left side value.
    jmp     compare_loop_end
    
insert_right:
    mov     edx, v_main_array ; See the comment on repeated code under "insert left".
    mov     ebx, [edx + edi*4]
    
    inc     R_index
    mov     edx, v_temp_array  ; We have to work with the temporary array to insert.
    mov     esi, T_index       ; We use the ESI register that was used for the other side.
    mov     [edx + esi*4], ebx ; EBX is right side value.
    
compare_loop_end:
    inc     T_index
    loop    compare_loop_start
    
; Next part writes the temporary work back to the correct portion of the main array.
    mov     edi, v_left ; The index starts at v_left because we're not necessarily
                        ;  working with the start of the array in recursive calls.
write_back_loop:
    mov     edx, v_temp_array
    mov     esi, edi
    sub     esi, v_left        ; Because we work from the beginning of the temporary array, regardless of v_left.
    mov     eax, [edx + esi*4] ; Temporary array value is in EAX.
    
    mov     edx, v_main_array
    mov     [edx + edi*4], eax ; EAX value (from temporary array) moved to proper spot in main array.
    
    inc     edi
    cmp     edi, v_right    ; Loop until EDI is at v_right, indicating we're finished with the section of the array.
    jb      write_back_loop
    ; I generally like using LOOP, but this loop isn't using LOOP because we're counting up, not down.
    ; ECX is free to wander around for a bit. We'll be sure to get its attention when we need it.
    
recursion_done:
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    pop     edi
    pop     esi

    add     esp, 20     ; Get rid of the local variables.
    
    ret
valueCompare ENDP


;~~~~~~~~~~~~~~~~~~
; showMedian
;This procedure calculates and prints a median. It's kind of anti-climactic after the majesty of the merge sort.
;receives: Takes two stack parameters in the following order:
;          address of array to store integers (reference)
;          the size of the array (value)
;returns: Prints out a median (but doesn't store it into any variable for later use).
;preconditions: The stack parameters should be valid (valid DWORD array, valid size).
;registers changed: None. (EAX, EBX, ECX, EDX, EDI, ESI pushed/popped; EBP pushed/popped for stack frame)
;~~~~~~~~~~~~~~~~~~
showMedian PROC
    push    ebp
    mov     ebp, esp
    
    push    edx
    push    ecx     ; Using ECX like a local variable because I'm lazy.
    push    ebx     ; Same with EBX.
    push    eax
    
    mov     eax, [ebp + 8] ; Get the array's size.
    xor     edx, edx
    mov     ebx, 2
    div     ebx
    
    cmp     edx, 0  ; Check to see if we have an even number of values.
    je     even_median
    
; This initial part is only for odd medians. Not odd in value, but index. I'm not sure that makes
;  sense grammatically, but you know what I mean. Like in an array with 3 things, the second thing
;  at index 1 would be the median.
    mov     edx, [ebp + 12] ; Get the array's address.
    mov     ecx, [edx + eax*4]   ; ECX now holds the median.
    mov     eax, ecx        ; EAX now holds the median. The previous step was superfluous.
    jmp     print_median
    
even_median:
    mov     edx, [ebp + 12]    ; Get the array's address.
    mov     ecx, [edx + eax*4] ; ECX now holds the upper value for the median.
    dec     eax
    mov     ebx, [edx + eax*4] ; EBX now holds the lower value for the median.
    
    xor     edx, edx    ; Clear EDX.
    mov     eax, ebx    ; Move in the lower median value.
    add     eax, ecx    ; Add the higher median value.
    mov     ebx, 2      ; Prepare to divide.
    div     ebx         ; Divide by two.
    cmp     edx, 0      ; See if we have to round the new median.
    je      print_median
    inc     eax         ; Round up, because we're using positive values and dividing by 2.
    
print_median:
    mov     edx, OFFSET median_msg
    call    WriteString
    call    WriteDec    ; The median is already in EAX.
    mov     edx, OFFSET singledot
    call    WriteString
    call    CrLf
    
    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    
    pop     ebp
    ret     8
showMedian ENDP
    
END main
