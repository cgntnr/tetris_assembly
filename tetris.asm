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

; BEGIN:main
main:
    addi    sp, zero, 0x2000
    call    reset_game

m_loop:
m_loop2:
    addi    s0, zero, RATE
m_loop3:
    addi    s0, s0, -1
    call    draw_gsa
    call    display_score
    addi    a0, zero, NOTHING
    call    draw_tetromino
    call    wait
    call    get_input
    beq     v0, zero, m_act_end
    add     a0, v0, zero
    call    act
m_act_end:
    addi    a0, zero, FALLING
    call    draw_tetromino
    bne     s0, zero, m_loop3

    addi    a0, zero, NOTHING
    call    draw_tetromino
    addi    a0, zero, moveD
    call    act
    bne     v0, zero, m_loop2_end
    addi    a0, zero, FALLING
    call    draw_tetromino
    br      m_loop2

m_loop2_end:
    addi    a0, zero, PLACED
    call    draw_tetromino

m_loop_rfl:
    call    detect_full_line
    addi    t0, zero, 8
    beq     v0, t0, m_loop_rfl_end
    add     a0, v0, zero
    call    remove_full_line
    call    increment_score
    call    display_score
    br      m_loop_rfl

m_loop_rfl_end:
    call    generate_tetromino
    addi    a0, zero, OVERLAP
    call    detect_collision
    addi    t0, zero, NONE
    bne     v0, t0, m_loop_end
    addi    a0, zero, FALLING
    call    draw_tetromino
    br      m_loop

m_loop_end:
	
	br main
    ret
; END:main

; BEGIN:clear_leds
clear_leds:
    stw     zero, LEDS(zero)
    stw     zero, LEDS+4(zero)
    stw     zero, LEDS+8(zero)
    ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
    andi    t0, a0, 12      ; t0: led word offset
    ldw     t1, LEDS(t0)    ; t1: led word value
    andi    a0, a0, 3       ; a0: led bit offset
    slli    a0, a0, 3
    add     a0, a0, a1
    addi    t2, zero, 1     ; t2: led bit mask
    sll     t2, t2, a0
    or      t1, t1, t2
    stw     t1, LEDS(t0)
    ret
; END:set_pixel

; BEGIN:wait
wait:
    addi    t0, zero, 1
    slli    t0, t0, 20       ; NOTE: should be changed to 20 to run on the Gecko
loop:
    addi    t0, t0, -1
    bne     t0, zero, loop
    ret
; END:wait

; BEGIN:in_gsa
in_gsa:
    cmplti  t0, a0, 0
    or      v0, zero, t0
    cmpgei  t0, a0, 12
    or      v0, v0, t0
    cmplti  t0, a1, 0
    or      v0, v0, t0
    cmpgei  t0, a1, 8
    or      v0, v0, t0
    ret
; END:in_gsa

; BEGIN:get_gsa
get_gsa:
    slli    a0, a0, 3       ; a0: gsa offset
    add     a0, a0, a1
    slli    a0, a0, 2
    ldw     v0, GSA(a0)
    ret
; END:get_gsa

; BEGIN:set_gsa
set_gsa:
    slli    a0, a0, 3       ; a0: gsa offset
    add     a0, a0, a1
    slli    a0, a0, 2
    stw     a2, GSA(a0)
    ret
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
    addi    sp, sp, -12
    stw     ra, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)

    call    clear_leds
    addi    s0, zero, 12    ; s0: x coordinate

loop_x:
    addi    s0, s0, -1
    addi    s1, zero, 8     ; s1: y coordinate

loop_y:
    addi    s1, s1, -1

    add     a0, s0, zero
    add     a1, s1, zero
    call    get_gsa

    beq     v0, zero, loop_y_end

    add     a0, s0, zero
    add     a1, s1, zero
    call    set_pixel

loop_y_end:
    bne     s1, zero, loop_y

    bne     s0, zero, loop_x

    ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     ra, 8(sp)
    addi    sp, sp, 12

    ret
; END:draw_gsa

; BEGIN:draw_tetromino
draw_tetromino:

    addi    sp, sp, -32
    stw     ra, 28(sp)
	stw     s6, 24(sp)
    stw     s5, 20(sp)
    stw     s4, 16(sp)
    stw     s3, 12(sp)
    stw     s2, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)

	ldw		s0, T_X(zero)
	ldw 	s1, T_Y(zero)
	ldw		s2,	T_type(zero)
	ldw 	s3, T_orientation(zero)
	add		s4, zero, zero		#to compute index in DRAW_Ax and DRAW_Ay	
	add  	s5,	zero, zero		#temp address
	add 	s6, zero, zero		#temp change for anchor 

	slli	s4, s2, 4 		    #type * 16 
	slli	s3, s3, 2			#orientation * 4
	add 	s4,	s4, s3	 		#index computed

	add 	a2, zero, a0		#giving p to a2 for calling set_gsa
	add 	a0, zero, s0		
	add		a1, zero, s1		

	call	set_gsa				#anchor point set in GSA

	ldw		s5, DRAW_Ax(s4)
	ldw		s6,	0(s5)
	add		a0, s0, s6
	ldw		s5,	DRAW_Ay(s4)
	ldw		s6,	0(s5)	
	add		a1, s1, s6	
	call 	set_gsa				#computing and setting second pixel of tetromino
		
	ldw		s5, DRAW_Ax(s4)	
	ldw		s6,	4(s5)	
	add		a0, s0, s6
	ldw		s5,	DRAW_Ay(s4)
	ldw		s6,	4(s5)	
	add		a1, s1, s6	

	call 	set_gsa				#computing and setting third of tetromino

	ldw		s5, DRAW_Ax(s4)	
	ldw		s6,	8(s5)	
	add		a0, s0, s6
	ldw		s5,	DRAW_Ay(s4)
	ldw		s6,	8(s5)	
	add		a1, s1, s6
	
	call 	set_gsa				#computing and setting last pixel of tetromino

	ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     s2, 8(sp)
    ldw     s3, 12(sp)
    ldw     s4, 16(sp)
    ldw     s5, 20(sp)
    ldw     s6, 24(sp)
    ldw     ra, 28(sp)
 	addi    sp, sp, 32

    ret
; END:draw_tetromino

; BEGIN:generate_tetromino
generate_tetromino:
   
	addi    sp, sp, -20
    stw     s4, 16(sp)
    stw     s3, 12(sp)
    stw     s2, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)

	addi 	s1, zero, 5
	addi	s2, zero, START_X			#default x
	addi	s3, zero, START_Y	 		#default y
	addi	s4, zero, N					#default orientation

generate:

	ldw		s0, RANDOM_NUM(zero)
    andi    s0, s0, 7

	blt		s0, zero, generate 
	bge 	s0, s1	, generate			#type in s0
	
	stw 	s0,	T_type(zero) 
	stw 	s2,	T_X(zero)
	stw 	s3,	T_Y(zero)
	stw		s4, T_orientation(zero)

	ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     s2, 8(sp)
    ldw     s3, 12(sp)
    ldw     s4, 16(sp)
 	addi    sp, sp, 20

	ret
; END:generate_tetromino

; BEGIN:detect_collision
detect_collision:

    addi    sp, sp, -36
    stw     ra, 32(sp)
    stw     s7, 28(sp)
    stw     s6, 24(sp)
    stw     s5, 20(sp)
    stw     s4, 16(sp)
    stw     s3, 12(sp)
    stw     s2, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)


	ldw		s6, T_X(zero)
	ldw 	s7, T_Y(zero)
	ldw		t2,	T_type(zero)
	ldw 	t3, T_orientation(zero)
	add		t4, a0, zero		#storing argument of function	
	
	#t4 used after function calls might be changed 
    addi    sp, sp, -4
    stw     t4, 0(sp)

	add  	t5,	zero, zero		#temp address
	add 	t6, zero, zero		#temp change for anchor 


	slli	t2, t2, 4 		    #type*16 
	slli	t3, t3, 2			#orientation * 4
	add 	t2,	t2, t3	 		#index computed

	ldw		t5, DRAW_Ax(t2)	
	ldw		t6,	0(t5)	
	add		s0, s6, t6			#x coordinate of second brick
	ldw		t5,	DRAW_Ay(t2)
	ldw		t6,	0(t5)	
	add		s1, s7, t6			#y coordinate of second brick

	ldw		t5, DRAW_Ax(t2)	
	ldw		t6,	4(t5)	
	add		s2, s6, t6			#x coordinate of third brick
	ldw		t5,	DRAW_Ay(t2)
	ldw		t6,	4(t5)	
	add		s3, s7, t6			#y coordinate of third brick

	ldw		t5, DRAW_Ax(t2)	
	ldw		t6,	8(t5)
	add		s4, s6, t6			#x coordinate of last brick
	ldw		t5,	DRAW_Ay(t2)
	ldw		t6,	8(t5)
	add		s5, s7, t6			#y coordinate of last brick

	cmpeqi	t7, a0, OVERLAP	
	bne 	t7, zero, case_Overlap	
	cmpeqi	t7, a0, E_COL	
	bne 	t7, zero, E_collision
	cmpeqi	t7, a0, W_COL	
	bne 	t7, zero, W_collision
	cmpeqi	t7, a0, So_COL	
	bne 	t7, zero, So_collision

#in case of E_COL W_COL S_COL increment or decrement to get x,y for intented direction
#check if they are empty in GSA 
#as soon as any of them is not empty jump to col_detected


E_collision:

#east positions for x coordinates 
#will check with in_gsa and get_gsa to detect collisions

	addi 	s6, s6, 1
	addi    s0, s0, 1
	addi    s2, s2, 1
	addi 	s4, s4, 1		
 
		#####	could be helper function, repeated in each case
	add		a0, s6, zero 
	add	    a1, s7, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s6, zero 
	add	    a1, s7, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	

	add		a0, s0, zero 
	add	    a1, s1, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s0, zero 
	add	    a1, s1, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected

	add		a0, s2, zero 
	add	    a1, s3, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s2, zero 
	add	    a1, s3, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED 
	bne 	t7, zero, col_detected

	add		a0, s4, zero 
	add	    a1, s5, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s4, zero 
	add	    a1, s5, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	
		#####	could be helper function, repeated in each case

	jmpi	no_collision

W_collision:

	addi s6, s6, -1
	addi s0, s0, -1
	addi s2, s2, -1
	addi s4, s4, -1	
	
		#####	
	add		a0, s6, zero 
	add	    a1, s7, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s6, zero 
	add	    a1, s7, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	

	add		a0, s0, zero 
	add	    a1, s1, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s0, zero 
	add	    a1, s1, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected

	add		a0, s2, zero 
	add	    a1, s3, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s2, zero 
	add	    a1, s3, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED 
	bne 	t7, zero, col_detected

	add		a0, s4, zero 
	add	    a1, s5, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s4, zero 
	add	    a1, s5, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	
		#####	

	jmpi	no_collision

So_collision:

	addi s7, s7, 1
	addi s1, s1, 1
	addi s3, s3, 1
	addi s5, s5, 1

		#####	
	add		a0, s6, zero 
	add	    a1, s7, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s6, zero 
	add	    a1, s7, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	

	add		a0, s0, zero 
	add	    a1, s1, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s0, zero 
	add	    a1, s1, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected

	add		a0, s2, zero 
	add	    a1, s3, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s2, zero 
	add	    a1, s3, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED 
	bne 	t7, zero, col_detected

	add		a0, s4, zero 
	add	    a1, s5, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s4, zero 
	add	    a1, s5, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	
		#####	

	jmpi	no_collision

case_Overlap:					
	#case where we check if there's an overlap in current situation

		#####	
	add		a0, s6, zero 
	add	    a1, s7, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s6, zero 
	add	    a1, s7, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	

	add		a0, s0, zero 
	add	    a1, s1, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s0, zero 
	add	    a1, s1, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected

	add		a0, s2, zero 
	add	    a1, s3, zero	
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s2, zero 
	add	    a1, s3, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED 
	bne 	t7, zero, col_detected

	add		a0, s4, zero 
	add	    a1, s5, zero
	call	in_gsa			#checking if inside screen
	bne		v0, zero, col_detected
	add		a0, s4, zero 
	add	    a1, s5, zero
	call 	get_gsa			#checking if empty
	cmpeqi	t7, v0, PLACED	 
	bne 	t7, zero, col_detected	
		#####	

no_collision:
	addi	v0, zero, NONE	
  	addi    sp, sp, 4 	#correcting sp position in case of no_collision
	jmpi fin	
	
col_detected:	
	ldw     t4, 0(sp)
 	addi    sp, sp, 4	#getting function argument out of stack

	add		v0, t4, zero	

fin:
	

	ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     s2, 8(sp)
    ldw     s3, 12(sp)
    ldw     s4, 16(sp)
    ldw     s5, 20(sp)
    ldw     s6, 24(sp)
    ldw     s7, 28(sp)
    ldw     ra, 32(sp)
 	addi    sp, sp, 36

	ret
; END:detect_collision



; BEGIN:rotate_tetromino
rotate_tetromino:
 
	addi    sp, sp, -8
    stw     s1, 4(sp)
 	stw     s0, 0(sp)

	add 	s0, zero, zero
	add		s1, zero, zero

	cmpeqi	s0, a0, rotL
	bne		s0, zero, rotateL
	
	cmpeqi	s0, a0, rotR
	bne		s0, zero, rotateR

rotateL:

	ldw 	s1, T_orientation(zero)
	beq 	s1, zero, north
	addi	s1, s1, -1
	stw		s1, T_orientation(zero)
	jmpi 	end

north:

	addi	s1, zero, W
	stw 	s1, T_orientation(zero)
	jmpi	end		

rotateR:	
	
	ldw		s1, T_orientation(zero)
	addi  	s1, s1, 1
	andi 	s1, s1, 3
	stw 	s1, T_orientation(zero)

end:
 	ldw     s0, 0(sp)
    ldw     s1, 4(sp)
	addi    sp, sp, 8

	ret
; END:rotate_tetromino



; BEGIN:act
act:

    addi    sp, sp, -36
    stw     ra, 32(sp)
	stw     s7, 28(sp)
	stw     s6, 24(sp)
    stw     s5, 20(sp)
    stw     s4, 16(sp)
    stw     s3, 12(sp)
    stw     s2, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)

	cmpeqi	s0, a0, moveD
	bne		s0, zero, moveDown	
	cmpeqi	s0, a0, moveL
	bne		s0, zero, moveLeft
	cmpeqi	s0, a0, moveR
	bne		s0, zero, moveRight
	cmpeqi	s0, a0, rotL
	bne		s0, zero, rotateLeft
	cmpeqi	s0, a0, rotR
	bne		s0, zero, rotateRight
	cmpeqi	s0, a0, reset
	bne		s0, zero, resetGame

moveDown:

	addi	a0, zero, So_COL
	call	detect_collision
	cmpeqi	s0, v0, NONE
	beq		s0, zero, failure
	
	ldw		s1, T_Y(zero)
	addi	s1, s1, 1
	stw 	s1, T_Y(zero)
	jmpi 	success

moveLeft:

	addi	a0, zero, W_COL
	call	detect_collision
	cmpeqi	s0, v0, NONE
	beq		s0, zero, failure
	
	ldw		s1, T_X(zero)
	addi	s1, s1, -1
	stw 	s1, T_X(zero)
	jmpi 	success

moveRight:

	addi	a0, zero, E_COL
	call	detect_collision
	cmpeqi	s0, v0, NONE
	beq		s0, zero, failure
	
	ldw		s1, T_X(zero)
	addi	s1, s1, 1
	stw 	s1, T_X(zero)
	jmpi 	success

rotateLeft:

	ldw		s3, T_X(zero)
	ldw		s4, T_Y(zero)
	ldw		s5, T_orientation(zero)

	addi	a0, zero, rotL
	call	rotate_tetromino
	addi	a0, zero, OVERLAP
	call	detect_collision
	cmpeqi	s0, v0, NONE
	bne		s0, zero, success		#rotation done and no overlap

	#overlap case

	ldw		s6, T_X(zero)
	cmplti	s7, s6, 6			#if T_X < 6 we ll shift tetromino to right
	bne		s7, zero, towardsRight
	jmpi 	towardsLeft	

rotateRight:

	ldw		s3, T_X(zero)
	ldw		s4, T_Y(zero)
	ldw		s5, T_orientation(zero)
	
	addi	a0, zero, rotR
	call	rotate_tetromino
	addi	a0, zero, OVERLAP
	call	detect_collision
	cmpeqi	s0, v0, NONE
	bne		s0, zero, success 	 #rotation done and no overlap

	#overlap case

	ldw		s6, T_X(zero)
	cmplti	s7, s6, 6			#if T_X < 6 we ll shift tetromino to right
	bne		s7, zero, towardsRight
	jmpi 	towardsLeft	

towardsLeft:
	addi	s6, s6, -1
	stw		s6, T_X(zero)
	addi	a0, zero, OVERLAP
	call	detect_collision
	cmpeqi	s0, v0, NONE
	bne		s0, zero, success 	 #shift by 1 and no collision

	addi	s6, s6, -1
	stw		s6, T_X(zero)
	addi	a0, zero, OVERLAP
	call	detect_collision			
	cmpeqi	s0, v0, NONE
	bne		s0, zero, success 	 #second shift and no collision
	
	jmpi 	failureRotate

towardsRight:

	addi	s6, s6, 1
	stw		s6, T_X(zero)
	addi	a0, zero, OVERLAP
	call	detect_collision
	cmpeqi	s0, v0, NONE
	bne		s0, zero, success 	 #shift by 1 and no collision

	addi	s6, s6, 1
	stw		s6, T_X(zero)
	addi	a0, zero, OVERLAP
	call	detect_collision			
	cmpeqi	s0, v0, NONE
	bne		s0, zero, success 	 #second shift and no collision
	
	jmpi 	failureRotate	

resetGame:
	call	reset_game
	jmpi	act_end  

failureRotate:

	addi	v0, zero, 1
	stw		s3, T_X(zero)
	stw		s4, T_Y(zero)
	stw		s5, T_orientation(zero)		#rot failed, giving old values

	jmpi 	act_end

success:
	add 	v0, zero,zero
	jmpi	act_end

failure:
	addi	v0, zero, 1 

act_end:	

	ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     s2, 8(sp)
    ldw     s3, 12(sp)
    ldw     s4, 16(sp)
    ldw     s5, 20(sp)
    ldw     s6, 24(sp)
    ldw     s7, 28(sp)
    ldw     ra, 32(sp)
 	addi    sp, sp, 36

	ret
; END:act


; BEGIN:get_input
get_input:
    ldw     t0, BUTTONS + 4(zero)
    stw     zero, BUTTONS + 4(zero)
    andi    v0, t0, 1
    bne     v0, zero, get_input_end
    andi    v0, t0, 2
    bne     v0, zero, get_input_end
    andi    v0, t0, 4
    bne     v0, zero, get_input_end
    andi    v0, t0, 8
    bne     v0, zero, get_input_end
    add     v0, t0, zero
get_input_end:
    ret
; END:get_input

; BEGIN:detect_full_line
detect_full_line:
    addi    sp, sp, -12
    stw     ra, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)

    addi    s0, zero, -1     ; s0: y position

dfl_loop_y:
    addi    s0, s0, 1
    addi    t0, zero, 8
    beq     s0, t0, dfl_end
    addi    s1, zero, 12     ; s1: x position

dfl_loop_x:
    addi    s1, s1, -1
    add     a0, s1, zero
    add     a1, s0, zero
    call    get_gsa
    addi    t0, zero, PLACED
    bne     v0, t0, dfl_loop_y
    bne     s1, zero, dfl_loop_x

dfl_end:
    add     v0, s0, zero

    ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     ra, 8(sp)
    addi    sp, sp, 12

    ret
; END:detect_full_line

; BEGIN:remove_full_line
remove_full_line:
    addi    sp, sp, -12
    stw     ra, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)

    add     s0, a0, zero    ; s0: y position
    addi    s1, zero, 5     ; s1: loop counter

rfl_blink_loop:
    addi    s1, s1, -1
    add     a0, s0, zero
    andi    a1, s1, 1
    call    gsa_set_line
    call    draw_gsa
    call    wait
    bne     s1, zero, rfl_blink_loop

rfl_move_loop_y:
    beq     s0, zero, rfl_end
    addi    s1, zero, 12    ; s1: x position

rfl_move_loop_x:
    addi    s1, s1, -1

    add     a0, s1, zero
    addi    a1, s0, -1
    call    get_gsa

    add     a0, s1, zero
    add     a1, s0, zero
    add     a2, v0, zero
    call    set_gsa

    bne     s1, zero, rfl_move_loop_x

    addi    s0, s0, -1
    br      rfl_move_loop_y

rfl_end:
    add     a0, zero, zero
    add     a1, zero, zero
    call    gsa_set_line

    ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     ra, 8(sp)
    addi    sp, sp, 12

    ret
; END:remove_full_line

; BEGIN:increment_score
increment_score:
    ldw     t0, SCORE(zero)
    addi    t0, t0, 1
    stw     t0, SCORE(zero)
    ret
; END:increment_score

; BEGIN:display_score
display_score:
    addi    sp, sp, -4
    stw     ra, 0(sp)

    ldw     a0, SCORE(zero)
    addi    a1, zero, 1000
    addi    a2, zero, 0
    call    display_score_digit

    add     a0, v0, zero
    addi    a1, zero, 100
    addi    a2, zero, 4
    call    display_score_digit

    add     a0, v0, zero
    addi    a1, zero, 10
    addi    a2, zero, 8
    call    display_score_digit

    add     a0, v0, zero
    addi    a1, zero, 1
    addi    a2, zero, 12
    call    display_score_digit

    ldw     ra, 0(sp)
    addi    sp, sp, 4

    ret
; END:display_score

; BEGIN:helper
gsa_set_line:
    addi    sp, sp, -12
    stw     ra, 8(sp)
    stw     s1, 4(sp)
    stw     s0, 0(sp)

    add     s2, a1, zero    ; s2: value
    add     s1, a0, zero    ; s1: y position
    addi    s0, zero, 12    ; s0: x position

gsl_loop:
    addi    s0, s0, -1

    add     a0, s0, zero
    add     a1, s1, zero
    add     a2, s2, zero
    call    set_gsa

    bne     s0, zero, gsl_loop

    ldw     s0, 0(sp)
    ldw     s1, 4(sp)
    ldw     ra, 8(sp)
    addi    sp, sp, 12

    ret


display_score_digit:
    add     t0, zero, zero
    add     t1, zero, zero
dsd_loop:
    add     t0, t0, a1
    blt     a0, t0, dsd_loop_end
    addi    t1, t1, 1
    br      dsd_loop
dsd_loop_end:
    sub     t0, t0, a1
    slli    t1, t1, 2
    ldw     t1, font_data(t1)
    stw     t1, SEVEN_SEGS(a2)
    sub     v0, a0, t0
    ret
; END:helper

; BEGIN:reset_game
reset_game:
    addi    sp, sp, -8
    stw     ra, 0(sp)
    stw     s0, 4(sp)

    stw     zero, SCORE(zero)
    call    display_score

    call    generate_tetromino
    addi    s0, zero, 384
rg_loop:
    addi    s0, s0, -4
    stw     zero, GSA(s0)
    bne     s0, zero, rg_loop

    addi    a0, zero, FALLING
    call    draw_tetromino

    call    draw_gsa

    ldw     s0, 4(sp)
    ldw     ra, 0(sp)
    addi    sp, sp, 8

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
