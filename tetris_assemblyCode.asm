;; game state memory location
  .equ T_X, 0x1000                  ; falling tetrominoe position on x
  .equ T_Y, 0x1004                  ; falling tetrominoe position on y
  .equ T_type, 0x1008               ; falling tetrominoe type
  .equ T_orientation, 0x100C        ; falling tetrominoe orientation
  .equ SCORE,  0x1010               ; score
  .equ GSA, 0x1014                  ; Game State Array starting address
  .equ SEVEN_SEGS, 0x1198           ; 7-segment display addresses
  .equ LEDS, 0x2000                 ; LED address
  .equ RANDOM_NUM, 0x2010           ; Random number generator address
  .equ BUTTONS, 0x2030              ; Buttons addresses

  ;; type enumeration
  .equ C, 0x00
  .equ B, 0x01
  .equ T, 0x02
  .equ S, 0x03
  .equ L, 0x04

  ;; GSA type
  .equ NOTHING, 0x0
  .equ PLACED, 0x1
  .equ FALLING, 0x2

  ;; orientation enumeration
  .equ N, 0
  .equ E, 1
  .equ So, 2
  .equ W, 3
  .equ ORIENTATION_END, 4

  ;; collision boundaries
  .equ COL_X, 4
  .equ COL_Y, 3

  ;; Rotation enumeration
  .equ CLOCKWISE, 0
  .equ COUNTERCLOCKWISE, 1

  ;; Button enumeration
  .equ moveL, 0x01
  .equ rotL, 0x02
  .equ reset, 0x04
  .equ rotR, 0x08
  .equ moveR, 0x10
  .equ moveD, 0x20

  ;; Collision return ENUM
  .equ W_COL, 0
  .equ E_COL, 1
  .equ So_COL, 2
  .equ OVERLAP, 3
  .equ NONE, 4

  ;; start location
  .equ START_X, 6
  .equ START_Y, 1

  ;; game rate of tetrominoe falling down (in terms of game loop iteration)
  .equ RATE, 5

  ;; standard limits
  .equ X_LIMIT, 12
  .equ Y_LIMIT, 8


  ;; TODO Insert your code here
; BEGIN:main
main:
;  addi t0 , zero , 4 addi t1 , zero , 4 addi a0 , zero , 1 addi t3 ,zero , 3 stw t0 , T_X(zero) stw t1 , T_Y(zero) stw t1 , T_type(zero) stw t3 , T_orientation(zero)


addi sp , zero , 0x1FFC ; stack
addi s7 , zero , RATE ; t7 = RATE
call reset_game 
bigRepeat :
smallRepeat : 
addi s0 , zero , 0 ; t0 = i
firstWhile : 
call draw_gsa
call display_score
call wait
addi a0 , zero , NOTHING
call draw_tetromino
call get_input
beq v0 , zero , hello
add a0 , zero ,v0
call act
hello : 
addi a0 , zero , FALLING 
call draw_tetromino
addi s0 , s0 , 1
blt s0 , s7 , firstWhile

addi a0 , zero , NOTHING
call draw_tetromino
addi a0 , zero , moveD
call act 
addi a0 , zero , FALLING 
call draw_tetromino

beq v0 , zero , smallRepeat

addi a0 , zero , PLACED 
call draw_tetromino

secondWhile :
call detect_full_line 
addi s1 , zero , 8 ; si 8 donc pas de full line
beq v0 , s1 , justGo
add a0 , zero ,v0
call remove_full_line
call increment_score
call display_score 
br secondWhile 

justGo : 
call generate_tetromino
addi a0 , zero , OVERLAP
call detect_collision
addi s2 ,zero , NONE
bne v0 , s2 , checkingforUntilOverlaps ; There is overlap 
 
addi a0 , zero ,FALLING
call draw_tetromino

checkingforUntilOverlaps :
addi a0 , zero , OVERLAP
call detect_collision
bne v0 , a0 , bigRepeat
br main  













; END:main


; BEGIN:clear_leds
clear_leds:
stw zero , LEDS(zero)
stw zero , LEDS+4(zero)
stw zero , LEDS+8(zero)
ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
srli t1 , a0 , 2 ; diviser x par 4 
slli t1 , t1 , 2 
andi t2 , a0 , 3 ; t2 = x mod 4
slli t2, t2, 3 ; 8 * x mod 4
add  t2 ,t2 ,a1
addi t4 , zero , 1 
sll t4 , t4 , t2
ldw t3 , LEDS(t1)
or t3 , t3 , t4 

stw t3 , LEDS(t1)
ret
; END:set_pixel



; BEGIN:wait
wait:

addi t0 , zero , 1
slli t0 , t0 , 20 ; should be 20 
counter:
addi t0,t0 , -1
bne t0 , zero , counter
ret

; END:wait



; BEGIN:in_gsa
in_gsa:
addi t0 , zero , 11
addi t1 , zero , 7
blt a0 , zero , OutputOne
blt t0 , a0 , OutputOne
blt a1 , zero ,OutputOne
blt t1 , a1 , OutputOne

addi v0 , zero , 0
ret
OutputOne:
addi v0 , zero , 1
ret

; END:in_gsa

; BEGIN:get_gsa
get_gsa:
slli t0 , a0 , 3 ; t0 = 8*x
add t0 , t0 , a1 ; t0 = 8*x +y 
slli t0 , t0 , 2 ; 4* t0 car word aligned 1000 - 1004 - 1008 
ldw v0 , GSA(t0)  
ret
; END:get_gsa

; BEGIN:set_gsa
set_gsa:
slli t0 , a0 , 3 ; t0 = 8*x
add t0 , t0 , a1 ; t0 = 8*x +y 
slli t0 , t0 , 2
stw a2 , GSA(t0)  
ret
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
addi sp, sp, -12
stw ra, 0(sp)
stw t5, 4(sp)
stw t7, 8(sp)
call clear_leds
ldw ra, 0(sp)
ldw t5, 4(sp)
ldw t7, 8(sp)
addi sp, sp, 12

addi t5 , zero , 0 ; t5 is the loop counter
addi t7 ,zero , 96 ; 96 elements to loop 
loop :
beq t5 , t7 , exit
andi a1 , t5 , 7 ; a1 = y = counter mod (8)
sub a0 , t5 , a1 ; a2 = x = (counter - y )/ 8
srli a0 , a0 , 3 ; a2 = x = (counter - y )/ 8   
                         
addi sp, sp, -20
stw ra, 0(sp)
stw t5, 4(sp)
stw t7, 8(sp)
stw a0 , 12(sp) 
stw a1 , 16(sp)
call get_gsa
ldw ra, 0(sp)
ldw t5, 4(sp)
ldw t7, 8(sp)
ldw a0 ,12(sp)
ldw a1 , 16(sp)
addi sp, sp,20


addi t5 , t5 ,1 ; incrementing loop counter
beq v0 , zero , loop ; if gsa is nothing then nothing to do ( clear leds have already set all leds to 0 )

addi sp, sp, -12
stw ra, 0(sp)
stw t5, 4(sp)
stw t7, 8(sp)
call set_pixel
ldw ra, 0(sp)
ldw t5, 4(sp)
ldw t7, 8(sp)
addi sp, sp, 12

br loop  

exit :
ret

; END:draw_gsa


; BEGIN:draw_tetromino
draw_tetromino:
addi sp, sp, -32
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)
stw s3, 12(sp)
stw s4, 16(sp)
stw s5, 20(sp)
stw s6, 24(sp)
stw s7, 28(sp)

add a2 , zero , a0 ; Adapting the GSA element to a2 to be compatible with set_gsa                       
ldw a0 , T_X(zero)
ldw a1 , T_Y(zero)
ldw s0 , T_type(zero)
ldw s1 , T_orientation(zero)

add s2 , a0 , zero ; saving T_X
add s3 , a1 , zero ; saving T_Y

addi sp , sp , -4
stw ra, 0(sp)
call set_gsa
ldw ra, 0(sp)
addi sp, sp, 4


slli t0 , s0 , 2
add t0 , t0 , s1
slli t0,t0 ,2 ; t0 = indice = (4 * type + orientation) * 4
ldw t1 , DRAW_Ax(t0) ; adress of x1 (ADRESS of the first element of the array )
ldw t2 , DRAW_Ay(t0) ; adress of y1 (ADRESS of the first element of the array )

addi t3 , t1 , 4
addi t4 , t2 , 4

ldw s5 , 0(t3) ; offset x2
ldw s6 , 0(t4) ; offset y2

addi t3 , t1 , 8
addi t4 , t2 , 8

ldw s7 , 0(t3) ; offset x3
ldw s4 , 0(t4) ; offset y3

ldw t1 , 0(t1) ;  offset x1
ldw t2 , 0(t2) ;  offset y1

add a0 , t1 , s2 ; updated x1
add a1 , t2 , s3 ; updated y1

addi sp , sp , -4
stw ra, 0(sp)
call set_gsa
ldw ra, 0(sp)
addi sp, sp, 4


add a0 , s5 , s2 ; updated x2
add a1 , s6 , s3 ; updated y2 

addi sp , sp , -4
stw ra, 0(sp)
call set_gsa
ldw ra, 0(sp)
addi sp, sp, 4


add a0 , s7 , s2 ; updated x3
add a1 , s4 , s3 ; updated y3 

addi sp , sp , -4
stw ra, 0(sp)
call set_gsa
ldw ra, 0(sp)
addi sp, sp, 4

ldw s0, 0(sp)
ldw s1, 4(sp)
ldw s2, 8(sp)
ldw s3, 12(sp)
ldw s4, 16(sp)
ldw s5, 20(sp)
ldw s6, 24(sp)
ldw s7, 28(sp)
addi sp, sp, 32

ret 

; END:draw_tetromino

; BEGIN:generate_tetromino
generate_tetromino:

ldw t0, RANDOM_NUM(zero)
;ldw t0, 0x11A8(zero) ; test only
andi t1, t0, 7
addi t2, zero, 4      ; pour verif si > 4
; blt t1, zero, generate_tetromino        ; if 0> (cas impossible on peut enlever)
blt t2, t1, generate_tetromino
addi t0, zero, 6            ; plus besoin du random donc réutiliser t0
addi t2, zero, 1           ; plus besoin du 4 pour comparaison
stw t0, T_X(zero)
stw t2, T_Y(zero)
stw zero, T_orientation(zero)
stw t1, T_type(zero)

ret

; END:generate_tetromino

; BEGIN:detect_collision
detect_collision:
addi sp, sp, -32
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)
stw s3, 12(sp)
stw s4, 16(sp)
stw s5, 20(sp)
stw s6, 24(sp)
stw s7, 28(sp)


ldw s0, T_X(zero)   ; x0 
ldw s1, T_Y(zero)   ; y0 

ldw t4, T_type(zero)
ldw t5, T_orientation(zero)

slli t4, t4, 2
add t4, t4, t5
slli t4, t4, 2

ldw t5, DRAW_Ax(t4)  ; address offset of x1
ldw t6, DRAW_Ay(t4)  ; address offset of y1
ldw s2, 0(t5)      ; offset x1
ldw s3, 0(t6)      ; offset y1
add s2, s0, s2     ; x1
add s3, s1, s3     ; y1

ldw s4, 4(t5)      ; offset x2
ldw s5, 4(t6)      ; offset y2
add s4, s0, s4     ; x2
add s5, s1, s5     ; y2

ldw s6, 8(t5)      ; offset x3
ldw s7, 8(t6)      ; offset y3
add s6, s0, s6     ; x3
add s7, s1, s7     ; y3
 

addi t0, zero, E_COL
addi t1, zero, W_COL
addi t2, zero, So_COL
addi t3, zero, OVERLAP

addi t7, zero, 1 ; to see if in_gsa = 1 (out of gsa) and to see if Placed (obstacle)

beq a0, t0, E_case
beq a0, t1, W_case
beq a0, t2, So_case
beq a0, t3, Overlap_case

E_case:

addi s0, s0, 1 ; move each pixel to east to see if there's a collision
addi s2, s2, 1
addi s4, s4, 1
addi s6, s6, 1
br continue

W_case:
addi s0, s0, -1 ; move each pixel to west to see if there's a collision
addi s2, s2, -1
addi s4, s4, -1
addi s6, s6, -1

br continue

So_case:
addi s1, s1, 1 ; move each pixel to south to see if there's a collision
addi s3, s3, 1
addi s5, s5, 1
addi s7, s7, 1

br continue

Overlap_case:
; checks if some pixels of the tetromino overlap with a placed pixel or out of gsa, so we don't need to move anything since we consider it already rotated/ generated
br continue


continue:

addi sp, sp, -4
stw a0, 0(sp)     ; save the value of collision (a0 will be used for in_gsa and get_gsa)

; Checks for each pixel if in_gsa, and if it's in gsa, check in there's an obstacle, if not -> collision
add a0, zero, s0
add a1, zero, s1

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call in_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

add a0, zero, s2
add a1, zero, s3

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call in_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

add a0, zero, s4
add a1, zero, s5

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call in_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

add a0, zero, s6
add a1, zero, s7

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call in_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

; if ALL valid, we need to check if there's an obstacle
; addi s7, zero, 1  -> to see if get_gsa = 2 (already placed = obstacle)   

add a0, zero, s0
add a1, zero, s1

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call get_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

add a0, zero, s2
add a1, zero, s3

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call get_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

add a0, zero, s4
add a1, zero, s5

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call get_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

add a0, zero, s6
add a1, zero, s7

addi sp, sp, -8
stw ra, 0(sp)
stw t7, 4(sp)
call get_gsa
ldw ra, 0(sp)
ldw t7, 4(sp)
addi sp, sp, 8
beq v0, t7, collision

ldw a0, 0(sp)
addi sp, sp, 4

; no_Collision:
addi v0, zero, NONE

ldw s0, 0(sp)
ldw s1, 4(sp)
ldw s2, 8(sp)
ldw s3, 12(sp)
ldw s4, 16(sp)
ldw s5, 20(sp)
ldw s6, 24(sp)
ldw s7, 28(sp)
addi sp, sp, 32

ret
collision:
ldw a0, 0(sp)
addi sp, sp, 4

add v0, zero, a0
ldw s0, 0(sp)
ldw s1, 4(sp)
ldw s2, 8(sp)
ldw s3, 12(sp)
ldw s4, 16(sp)
ldw s5, 20(sp)
ldw s6, 24(sp)
ldw s7, 28(sp)
addi sp, sp, 32

ret

; END:detect_collision

; BEGIN:rotate_tetromino
rotate_tetromino:
ldw t0, T_orientation(zero)

addi t1, zero, rotR
addi t2, zero, rotL

beq a0, t1, rR
beq a0, t2, rL

rR : 
addi t0 , t0 , 1
andi t0 , t0 , 3
stw t0 , T_orientation(zero)
ret 

rL :
addi t0 , t0 , -1
andi t0 , t0 , 3
stw t0 , T_orientation(zero)
ret 

; END:rotate_tetromino




; BEGIN:act
act:
addi sp, sp, -32
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)
stw s3, 12(sp)
stw s4, 16(sp)
stw s5, 20(sp)
stw s6, 24(sp)
stw s7, 28(sp)

addi t0 , zero ,moveD
addi t1 , zero ,moveL
addi t2 , zero ,moveR
addi t3 , zero ,rotR
addi t4 , zero ,rotL
addi t5 , zero ,reset

addi s0 , zero , W_COL
addi s1 , zero , E_COL
addi s2 , zero , So_COL
addi s3 , zero , OVERLAP
addi s4 , zero , NONE




beq a0 , t0 , moveDproc
beq a0 , t1 , moveLproc
beq a0 , t2 , moveRproc
beq a0 , t3 , rotproc
beq a0 , t4 , rotproc
beq a0 , t5 , reset_game

br endOfAct 
moveDproc : 
addi a0 , zero , So_COL
addi sp , sp , -12
stw ra , 0(sp)
stw t6, 4(sp)
stw t7, 8(sp)
call detect_collision
ldw ra , 0(sp)
ldw t6, 4(sp)
ldw t7, 8(sp)
addi sp , sp , 12                                 ; I CHANGED SO THAT THE NEW S4 CAN BE TAKEN INTO CONSIDERATION     ; s4 used by detect
bne v0 , s4 , fail ; It Should be None to act ! 
ldw t6 , T_Y(zero)
addi t6 , t6 , 1
stw t6 , T_Y(zero)
addi v0 , zero ,0
br endOfAct

moveLproc : 
addi a0 , zero , W_COL
addi sp , sp , -12
stw ra , 0(sp)
stw t6, 4(sp)
stw t7, 8(sp)
call detect_collision
ldw ra , 0(sp)
ldw t6, 4(sp)
ldw t7, 8(sp)
addi sp , sp , 12
bne v0 , s4 , fail ; It Should be None to act ! 
ldw t6 , T_X(zero)
addi t6 , t6 , -1
stw t6 , T_X(zero)
addi v0 , zero ,0
br endOfAct

moveRproc : 
addi a0 , zero , E_COL
addi sp , sp , -12
stw ra , 0(sp)
stw t6, 4(sp)
stw t7, 8(sp)
call detect_collision
ldw ra , 0(sp)
ldw t6, 4(sp)
ldw t7, 8(sp)
addi sp , sp , 12
bne v0 , s4 , fail ; It Should be None to act ! 
ldw t6 , T_X(zero)
addi t6 , t6 , 1
stw t6 , T_X(zero)
addi v0 , zero ,0
br endOfAct


rotproc : 
ldw s5 , T_orientation(zero) ; original orientation  , s5 is not used by rotate_tetromino
ldw s7 , T_X(zero) ; original X , s7 not used by rotate_tetromino

addi sp , sp , -12
stw ra , 0(sp)
stw t6, 4(sp)
stw t7, 8(sp)
call rotate_tetromino
ldw ra , 0(sp)
ldw t6, 4(sp)
ldw t7, 8(sp)
addi sp , sp , 12

addi a0 , zero , OVERLAP
addi sp , sp , -12
stw ra , 0(sp)
stw t6, 4(sp)
stw t7, 8(sp)
call detect_collision
ldw ra , 0(sp)
ldw t6, 4(sp)
ldw t7, 8(sp)
addi sp , sp , 12
addi s6 , zero , 0 ; the loop counter to modelize "at most 2" ! Rotate_tetromino Should not use it!

bne v0 , s4 , moveTowardsCenter
addi v0 , zero , 0 
br endOfAct

moveTowardsCenter : 

ldw t7 , T_X(zero)
addi t6 , zero , 6 ; the center

bge t7 , t6 , moveLeft

moveRight :
addi t0 , zero , 2
beq t0 , s6 , nothingtodo
addi t7 , t7 , 1 ; Case x<6 so moving by one to the right 
stw t7 ,T_X(zero)
addi s6 , s6, 1 ; incrementing loop counter

addi a0 , zero ,OVERLAP ; unnecessary bc a0 not supposed to change 
addi sp , sp , -12
stw ra , 0(sp)
stw t6, 4(sp)
stw t7, 8(sp)
call detect_collision
ldw ra , 0(sp)
ldw t6, 4(sp)
ldw t7, 8(sp)
addi sp , sp , 12
addi a0 , zero ,OVERLAP
beq v0 , a0 , moveRight

addi v0 , zero ,0 ; SUCCES
br endOfAct

moveLeft : 
addi t0 , zero , 2
beq t0 , s6 , nothingtodo
addi t7 , t7 , -1 ; Case x >= 6 so moving by one to the left 
stw t7 ,T_X(zero)
addi s6 , s6, 1 ; incrementing loop counter



addi a0 , zero , OVERLAP ; unnecessary bc a0 not supposed to change 
addi sp , sp , -12
stw ra , 0(sp)
stw t6, 4(sp)
stw t7, 8(sp)
call detect_collision
ldw ra , 0(sp)
ldw t6, 4(sp)
ldw t7, 8(sp)
addi sp , sp , 12
addi a0 , zero , OVERLAP
beq v0 , a0 , moveLeft

addi v0 , zero ,0 ; SUCCES
br endOfAct




nothingtodo : 
stw s5 , T_orientation(zero)
stw s7 , T_X(zero)
addi v0 , zero , 1 ; it failed !
br endOfAct

fail : 
addi v0 , zero , 1 ; it fails 
br endOfAct


endOfAct : 
ldw s0, 0(sp)
ldw s1, 4(sp)
ldw s2, 8(sp)
ldw s3, 12(sp)
ldw s4, 16(sp)
ldw s5, 20(sp)
ldw s6, 24(sp)
ldw s7, 28(sp)
addi sp, sp, 32
ret


; END:act





; BEGIN:get_input
get_input : 
addi sp, sp, -20
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)
stw s3, 12(sp)
stw s4, 16(sp)


addi t0 , zero , 1  ; mask = 000000....1
slli t1 , t0 , 1 ; ti = 00000...ieme bit = 1 ....000
slli t2 , t0 , 2
slli t3 , t0 , 3
slli t4 , t0 , 4

ldw t5 , BUTTONS +4 (zero)
and s0 , t0 , t5 ; s0 = t5 & mask pour bit 0
and s1 , t1 , t5
and s2 , t2 , t5
and s3 , t3 , t5
and s4 , t4 , t5

addi t6 , zero , moveL ;preparation de l'output si jamais on a trouvé un match
beq s0 , t0 , foundMatch ; si on trouve que edgecapture & mask = mask cad le bit contient 1 et on commence de 0 pour traiter le cas 2 bouttons presses en mm temps

addi t6 , zero , rotL
beq s1 , t1 , foundMatch

addi t6 , zero , reset
beq s2 , t2 , foundMatch

addi t6 , zero , rotR
beq s3 , t3 , foundMatch

addi t6 , zero ,moveR
beq s4 , t4 , foundMatch

addi v0 , zero , 0 ; no button pressed
ldw s0, 0(sp)
ldw s1, 4(sp)
ldw s2, 8(sp)
ldw s3, 12(sp)
ldw s4, 16(sp)
addi sp, sp, 20
ret 

foundMatch : 
add v0 , zero , t6
addi t7, zero, 0b11111
nor t7, t7, zero
and t5, t5, t7
stw t5 , BUTTONS +4 (zero)

ldw s0, 0(sp)
ldw s1, 4(sp)
ldw s2, 8(sp)
ldw s3, 12(sp)
ldw s4, 16(sp)
addi sp, sp, 20
ret
 




; END:get_input

; BEGIN:detect_full_line
detect_full_line:

addi t0 , zero , 0 ; y loop
addi t1 , zero , 0 ; x loop

addi t5 , zero , 1 
addi t6 , zero , 12
addi t7 , zero , 8
loopOverX : 
slli t4 , t1 , 3 ; t4 = 8*x
addi t2 , zero , 0 ; GSA value
add t3 , t4 , t0 ; indice of GSA = t3 = 8*x +y 
slli t3 , t3 , 2 ; word aligned 

ldw t2 , GSA(t3)
bne t2 , t5 , nextLine
addi t1 , t1 , 1
blt t1 , t6 , loopOverX
add v0 , zero,t0
ret

nextLine : 
addi t1 , zero , 0
addi t0 , t0 ,1
blt t0 , t7 , loopOverX
add v0 , zero ,t7 ; v0 = t7 = 8
ret
; END:detect_full_line


; BEGIN:remove_full_line
remove_full_line:
addi sp , sp ,-4
stw s1 , 0(sp)

addi t2, zero, 3   ; counter for On/Off loops  (t2 bcause set_gsa only uses t0)
add a1, zero, a0  ; a1 for set_gsa takes y_coord which is a0 here
add s1 , a1 , zero

loop_on_off:
addi t1, zero, 11 ; counter for x: 0..11
addi t2, t2, -1

loop_to_set_leds_off:
add a0, zero, t1  ; a0 = x
add a1 , s1 , zero
addi a2, zero, NOTHING    ;; a2 = gsa to set
addi sp, sp, -12
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
call set_gsa
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
addi sp, sp, 12
addi t1, t1, -1
bge t1, zero, loop_to_set_leds_off

addi sp, sp, -12
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
call draw_gsa
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
addi sp, sp, 12

addi sp, sp, -12
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
call wait
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
addi sp, sp, 12


beq t2, zero, removing_procedure  ; tant que t2 ≠ 0, on remet On, sinon on laisse Off (3 fois Off 2 On)

addi t1, zero, 11 ; counter for x: 0..11

loop_to_set_leds_on:
add a0, zero, t1
add a1 , zero ,s1
addi a2, zero, PLACED
addi sp, sp, -12
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
call set_gsa
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
addi sp, sp, 12
addi t1, t1, -1
bge t1, zero, loop_to_set_leds_on

addi sp, sp, -12
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
call draw_gsa
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
addi sp, sp, 12

addi sp, sp, -12
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
call wait
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
addi sp, sp, 12


br loop_on_off

removing_procedure: 
add t2, zero, a1
addi t2, t2, -1 ; counter for y beginning from the line above  the full line

for_each_line:
addi t1, zero, 11 ; counter for x

for_each_x:
add a0, zero, t1 ; a0 =x 
add a1, zero, t2  ; a1 = y

addi sp, sp, -20
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
stw a0 ,12(sp)
stw a1, 16(sp)
call get_gsa ;v0 = gsa of (x,y)
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
ldw a0 ,12(sp)
ldw a1 , 16(sp)
addi sp, sp,20

addi a1, a1, 1  ; we need to set the pixel under (x,y) which is (x, y+1) to v0
add a2, zero, v0
addi sp, sp, -20
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
stw a0 ,12(sp)
stw a1, 16(sp)
call set_gsa 
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
ldw a0 ,12(sp)
ldw a1 , 16(sp)
addi sp, sp,20

addi t1, t1, -1
bge t1, zero, for_each_x



addi t2, t2, -1
bge t2, zero, for_each_line

addi t1, zero, 11 ; counter for x


set_first_line_to0:
add a0, zero, t1
addi a1, zero, 0
addi a2, zero, NOTHING

addi sp, sp, -12
stw ra, 0(sp)
stw t1 ,4(sp)
stw t2 ,8(sp)
call set_gsa 
ldw ra, 0(sp)
ldw t1 ,4(sp)
ldw t2 ,8(sp)
addi sp, sp, 12

addi t1, t1, -1
bge t1, zero, set_first_line_to0

ldw s1 ,0(sp)
addi sp , sp ,4
ret
; END:remove_full_line

; BEGIN:increment_score
increment_score:
ldw t0, SCORE(zero)
addi t1, zero, 9999

beq t0, t1, finished

addi t0, t0, 1
stw t0, SCORE(zero)

finished:
ret

; END:increment_score

; BEGIN:display_score
display_score:
ldw t0, SCORE(zero)
addi t1, zero, 0 ; counter of digit

loop_on_thousands:
addi t0, t0, -1000
blt t0, zero, set_digit_thousands
addi t1, t1, 1
br loop_on_thousands

set_digit_thousands:
slli t1, t1, 2
ldw t2, font_data(t1)
stw t2, SEVEN_SEGS(zero)

addi t1, zero, 0 ; counter of digit
addi t0, t0, 1000

loop_on_hundreds:
addi t0, t0, -100
blt t0, zero, set_digit_hundreds
addi t1, t1, 1
br loop_on_hundreds

set_digit_hundreds:
slli t1, t1, 2
ldw t2, font_data(t1)
stw t2, SEVEN_SEGS+4(zero)

addi t1, zero, 0 ; counter of digit
addi t0, t0, 100

loop_on_tens:
addi t0, t0, -10
blt t0, zero, set_digit_tens
addi t1, t1, 1
br loop_on_tens

set_digit_tens:
slli t1, t1, 2
ldw t2, font_data(t1)
stw t2, SEVEN_SEGS+8(zero)

addi t1, zero, 0 ; counter of digit
addi t0, t0, 10

loop_on_units:
addi t0, t0, -1
blt t0, zero, set_digit_units
addi t1, t1, 1
br loop_on_units

set_digit_units:
slli t1, t1, 2
ldw t2, font_data(t1)
stw t2, SEVEN_SEGS+12(zero)

ret

; END:display_score



; BEGIN:reset_game
reset_game:

addi sp, sp, -4
stw ra, 0(sp)
call clear_leds
ldw ra, 0(sp)
addi sp, sp, 4

stw zero, SCORE(zero)

addi sp, sp, -4
stw ra, 0(sp)
call display_score
ldw ra, 0(sp)
addi sp, sp, 4


addi t0, zero, 95 ; coutner for gsa

loop_to_set_gsa:
slli t1, t0, 2
stw zero, GSA(t1)
addi t0, t0, -1
bge t0, zero, loop_to_set_gsa

addi sp, sp, -4
stw ra, 0(sp)
call generate_tetromino
ldw ra, 0(sp)
addi sp, sp, 4

addi a0, zero, FALLING

addi sp, sp, -4
stw ra, 0(sp)
call draw_tetromino
ldw ra, 0(sp)
addi sp, sp, 4

addi sp, sp, -4
stw ra, 0(sp)
call draw_gsa
ldw ra, 0(sp)
addi sp, sp, 4

ret

; END:reset_game

font_data:
    .word 0xFC  ; 0
    .word 0x60  ; 1
    .word 0xDA  ; 2
    .word 0xF2  ; 3
    .word 0x66  ; 4
    .word 0xB6  ; 5
    .word 0xBE  ; 6
    .word 0xE0  ; 7
    .word 0xFE  ; 8
    .word 0xF6  ; 9

C_N_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_N_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_E_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_E_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

C_So_X:
  .word 0x01
  .word 0x00
  .word 0x01

C_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

C_W_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0xFFFFFFFF

C_W_Y:
  .word 0x00
  .word 0x01
  .word 0x01

B_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_N_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x02

B_So_X:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

B_So_Y:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_X:
  .word 0x00
  .word 0x00
  .word 0x00

B_W_Y:
  .word 0xFFFFFFFE
  .word 0xFFFFFFFF
  .word 0x01

T_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_E_X:
  .word 0x00
  .word 0x01
  .word 0x00

T_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

T_So_Y:
  .word 0x00
  .word 0x01
  .word 0x00

T_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0x00

T_W_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_X:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_N_Y:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_E_X:
  .word 0x00
  .word 0x01
  .word 0x01

S_E_Y:
  .word 0xFFFFFFFF
  .word 0x00
  .word 0x01

S_So_X:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

S_So_Y:
  .word 0x00
  .word 0x01
  .word 0x01

S_W_X:
  .word 0x00
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

S_W_Y:
  .word 0x01
  .word 0x00
  .word 0xFFFFFFFF

L_N_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_N_Y:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_E_X:
  .word 0x00
  .word 0x00
  .word 0x01

L_E_Y:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0x01

L_So_X:
  .word 0xFFFFFFFF
  .word 0x01
  .word 0xFFFFFFFF

L_So_Y:
  .word 0x00
  .word 0x00
  .word 0x01

L_W_X:
  .word 0x00
  .word 0x00
  .word 0xFFFFFFFF

L_W_Y:
  .word 0x01
  .word 0xFFFFFFFF
  .word 0xFFFFFFFF

DRAW_Ax:                        ; address of shape arrays, x axis
    .word C_N_X
    .word C_E_X
    .word C_So_X
    .word C_W_X
    .word B_N_X
    .word B_E_X
    .word B_So_X
    .word B_W_X
    .word T_N_X
    .word T_E_X
    .word T_So_X
    .word T_W_X
    .word S_N_X
    .word S_E_X
    .word S_So_X
    .word S_W_X
    .word L_N_X
    .word L_E_X
    .word L_So_X
    .word L_W_X

DRAW_Ay:                        ; address of shape arrays, y_axis
    .word C_N_Y
    .word C_E_Y
    .word C_So_Y
    .word C_W_Y
    .word B_N_Y
    .word B_E_Y
    .word B_So_Y
    .word B_W_Y
    .word T_N_Y
    .word T_E_Y
    .word T_So_Y
    .word T_W_Y
    .word S_N_Y
    .word S_E_Y
    .word S_So_Y
    .word S_W_Y
    .word L_N_Y
    .word L_E_Y
    .word L_So_Y
    .word L_W_Y