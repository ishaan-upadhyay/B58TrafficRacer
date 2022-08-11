###################################################################### 
# CSCB58 Summer 2022 Project 
# University of Toronto, Scarborough 
# 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 (update this as needed) 
# - Unit height in pixels: 8 (update this as needed) 
# - Display width in pixels: 256 (update this as needed) 
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 
# 
# Basic features that were implemented successfully 
# - Basic feature a/b/c (choose the ones that apply) 
# 
# Additional features that were implemented successfully 
# - Additional feature a/b/c (choose the ones that apply) 
#  
# Link to the video demo 
# - Insert YouTube/MyMedia/other URL here and make sure the video is accessible 
# 
# Any additional information that the TA needs to know: 
# - Write here, if any 
#  
######################################################################  
.data
speeds: .word -1, -1, -1, -1
lanes: .word -1, -1, -1, -1
count: .word 0
copy: .space 4096
.text
.globl main
#===============================================================================
main:
# Initialize background as grey square
sw $zero, -4($sp)
sw $zero, -8($sp)
li $s0, 32
sw $s0, -12($sp)
sw $s0, -16($sp)
li $s0, 0x808080
sw $s0, -20($sp)
sw $gp, -24($sp)
addi $sp, $sp, -24
jal drawRect

# Draw centre divider
li $s0, 15
sw $s0, -4($sp)
sw $zero, -8($sp)
li $s0, 32
sw $s0, -12($sp)
li $s0, 2
sw $s0, -16($sp)
li $s0, 0xFFFFFF
sw $s0, -20($sp)
sw $gp, -24($sp)
addi $sp, $sp, -24
jal drawRect

# Draw lane dividers
li $t9, 0
START_LOOP_LN: beq $t9, 32, END_LOOP_LN 
        # Tell drawRect to go to (7, ?) and (24, ?)
        li $s0, 7
		sw $s0, -4($sp)
        li $s0, 24
        sw $s0, -28($sp)

        # Go to (7, y) and (24, y)
		sw $t9, -8($sp)
        sw $t9, -32($sp)
        
        # Set height to 3
        li $s0, 3
	    sw $s0, -12($sp)
        sw $s0, -36($sp)
		
        # Set width to 1
        li $s0, 1
        sw $s0, -16($sp)
        sw $s0, -40($sp)
		
        # Set colour to white 
        li $s0, 0xFFFFFF
        sw $s0, -20($sp)
        sw $s0, -44($sp)

        sw $gp, -24($sp)
        sw $gp, -48($sp)

		addi $sp, $sp, -48
		jal drawRect # draw nth lane divider between opposite traffic lanes
		jal drawRect # draw nth lane divider between same direction traffic 
UPDATE_LOOP_LN:
	addi $t9, $t9, 4
	j START_LOOP_LN
END_LOOP_LN:
    li $s1, 3 # start at speed of 1
    li $s2, 26 # car will always stay at y level 25, x can vary between 0 and 27
    li $s3, 0 # flag for hard mode
    li $s4, 3 # lives
    li $s5, 0 # invincibility flag
    li $s6, 0 # timer until next car spawns
    li $s7, 0 # store current score

move $s0, $s2
sw $s0, -4($sp)
    
li $s0, 25
sw $s0, -8($sp)
    
li $s0, 6
sw $s0, -12($sp)
    
li $s0, 5
sw $s0, -16($sp)
    
li $s0, 0xFF0000
sw $s0, -20($sp)
    
move $s0, $gp
sw $s0, -24($sp)
addi $sp, $sp, -24
jal drawRect

# Copy whatever we've done into copy array
li $s0, 0
move $t8, $gp
START_LOOP_COPY: beq $s0, 4096, END_LOOP_COPY
                 lw $t9, 0($t8)
                 sw $t9, copy($s0) 
UPDATE_LOOP_COPY: addi $s0, $s0, 4
		         addi $t8, $t8, 4
                 j START_LOOP_COPY   
END_LOOP_COPY:  li $t8, 0
                j inputProcess

li $v0, 10
syscall
#===============================================================================
inputProcess:
# Wait for a keypress before advancing
    li $t9, 0xffff0000 
    lw $t8, 0($t9) 
    # li $a0, 500
    # syscall # 500 ms pause before either updating player car or jumping to update other
    beq $t8, 1, keypress_happened
    j updateOther
# Check game over flag, if game is not over check for WASD
	keypress_happened: bgtz $s4, handleWASD
# If 1, only listen for [restart] key
	handleQ:

	handleWASD:
            lw $t2, 4($t9)
            li $t8, 0 # Reset the keypress_happened flag to 0
            # Check what keypress is being handled
            beq $t2, 0x77, handleW
            beq $t2, 0x61, handleA
            beq $t2, 0x73, handleS
            beq $t2, 0x64, handleD
            # If none of these keys were pressed, jump to collision check
            j updateOther 
            handleW: 
                # If speed is maximum already, update other cars, else increment then jump
                beq $s1, 5, updateOther
                addi $s1, $s1, 1
                j updateOther
            handleA:
                beq $s2, 0, updateCar
                # Draw a gray rectangle over where the car previously was
                move $s0, $s2
                addi $s0, $s0, 4 # go to rightmost edge of previous location
                sw $s0, -4($sp)

                li $s0, 25 # y is constant
                sw $s0, -8($sp)

                li $s0, 6
                sw $s0, -12($sp)

                li $s0, 1
                sw $s0, -16($sp)
                
                li $s0, 0x808080
                sw $s0, -20($sp)
                
                la $s0, copy
                sw $s0, -24($sp)
                addi $sp, $sp, -24
                jal drawRect

                addi $s2, $s2, -1 # go to (x-1, y)
                j updateCar
            handleS:
                beq $s1, 3, updateOther
                addi $s1, $s1, -1 # reduce speed by 1
                j updateOther
            handleD:
                beq $s2, 27, updateCar
                # Draw a gray rectangle over where the car previously was
                move $s0, $s2 # go to leftmost edge of previous location
                sw $s0, -4($sp)

                li $s0, 25 # y is constant
                sw $s0, -8($sp)

                li $s0, 6
                sw $s0, -12($sp)

                li $s0, 1
                sw $s0, -16($sp)
                
                li $s0, 0x808080
                sw $s0, -20($sp)
                
                la $s0, copy
                sw $s0, -24($sp)
                addi $sp, $sp, -24
                jal drawRect

                addi $s2, $s2, 1 # go to (x+1, y)
                j updateCar
#===============================================================================	
updateCar:
    # Redraw the lane dividers on the strip car can move in, in case they were drawn over
    li $s0, 7
    sw $s0, -4($sp)
    sw $s0, -28($sp)
    li $s0, 24
    sw $s0, -52($sp)
    sw $s0, -76($sp)

    li $s0, 25 # y is constant
    sw $s0, -8($sp) # (7, 25) from first call
    sw $s0, -56($sp) # (24, 25) from second call
    li $s0, 28 
    sw $s0, -32($sp) # (7, 28) from third call
    sw $s0, -80($sp) # (24, 28) from fourth call

    li $s0, 2
    sw $s0, -12($sp)
    sw $s0, -60($sp)
    li $s0, 3
    sw $s0, -36($sp)
    sw $s0, -84($sp)

    li $s0, 1
    sw $s0, -16($sp)
    sw $s0, -40($sp)
    sw $s0, -64($sp)
    sw $s0, -88($sp)
                
    li $s0, 0xFFFFFF
    sw $s0, -20($sp)
    sw $s0, -44($sp)
    sw $s0, -68($sp)
    sw $s0, -92($sp)

    la $s0, copy
    sw $s0, -24($sp)
    sw $s0, -48($sp)
    sw $s0, -72($sp)
    sw $s0, -96($sp)
    
    addi $sp, $sp, -96
    jal drawRect
    jal drawRect
    jal drawRect
    jal drawRect
    
    # Redraw central divider
    li $s0, 15
    sw $s0, -4($sp)
    
    li $s0, 25
    sw $s0, -8($sp)
    
    li $s0, 6
    sw $s0, -12($sp)
    
    li $s0, 2
    sw $s0, -16($sp)
    
    li $s0, 0xFFFFFF
    sw $s0, -20($sp)
    
    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect
    
    # Draw car since its position has updated
    move $s0, $s2
    sw $s0, -4($sp)
    
    li $s0, 25
    sw $s0, -8($sp)
    
    li $s0, 6
    sw $s0, -12($sp)
    
    li $s0, 5
    sw $s0, -16($sp)
    
    li $s0, 0xFF0000
    sw $s0, -20($sp)
    
    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect
#===============================================================================
updateOther:
# Generate time until spawning the next car or pickup
# Pick between 2 upper bounds for easy and hard mode
    bgtz $s6, moveCars # if our timer hasn't hit 0 yet, continue to move cars
    beq $s6, 0, spawnCar # if our timer has finally hit 0, spawn a new car
        li $v0, 42
        li $a0, 0
        mult $s3, -2
        mflo $t9
        addi $t9, $t9, 5 # on easy, upper limit is 2500ms, hard, upper limit is 1500ms
        move $a1, $t9
        syscall # generate a random number in the appropriate range
        move $s6, $a0 # grab this number
    # Spawn new car (max 3 on screen anytime)
    spawnCar:
        la $t9, count
        lw $t9, 0($t9)
        beq $t9, 3, moveCars # there are already 3 cars on the screen, continue moving them
        # Pick a line to spawn into
        li $v0, 42
        li $a0, 0
        li $a1, 4 # generate a number between 0 and 3 to use as an offset to place the car in a lane
        syscall
        # Select a speed to move at    
        
    # Spawn new pickup 


    # Move cars down
    moveCars: 
        addi $s6, $s6, -1 # count down the timer
        # proceed with moving cars

    # Move pickup down


#===============================================================================
collisionCheck:


#===============================================================================
redraw:
# Check game over flag (if 0 jump to draw background)
# Draw game over screen

# If game not over, copy over from copy, with a brief sleep
li $v0, 32
li $a0, 500
syscall # 500 millisecond sleep
li $s0, 0
move $t8, $gp
START_LOOP_COPYBACK: beq $s0, 4096, END_LOOP_COPYBACK
                 lw $t9, copy($s0)
                 sw $t9, 0($t8) 
UPDATE_LOOP_COPYBACK: addi $s0, $s0, 4
		         addi $t8, $t8, 4
                 j START_LOOP_COPYBACK   
END_LOOP_COPYBACK: j inputProcess
#===============================================================================
drawRect:
    lw $t5, 0($sp) # Pop location to write to
    lw $t4 4($sp) # Pop colour from stack
    lw $t3 8($sp) # Pop width of rectangle from stack
    lw $t2 12($sp) # Pop height of rectangle from stack
    lw $t1 16($sp) # Pop y-coordinate of rectangle from stack
    lw $t0 20($sp) # Pop x-coordinate of top-left corner of rectangle
    addi $sp, $sp, 24 # Advance stack pointer

    # Calculate position of top-left corner     
    # Go to (x, 0)
    li $t6, 4
    mult $t6, $t0
    mflo $t6 # calculate 4x
    add	$t5, $t5, $t6 # go to $gp + 4x

    # Go (x, y)
    li $t6, 128
    mult $t6, $t1
    mflo $t6 # calculate 128y
    add	$t5, $t5, $t6 # go to $gp + 4x + 128y

    # The value(s) in t1 are no longer needed
    move $t1, $t5 # Keep a copy of $gp + 4x + 128y    
    
    li $t6, 0   # use t6 as counter for outer loop
    li $t7, 0   # use t7 as counter for inner loop

    # Nested for loop
    START_OUTER_DR: beq	$t6, $t2, END_OUTER_DR # if $t0 == $t1 then target
        START_INNER_DR: beq $t7, $t3, END_INNER_DR # if $t0 == $t1 then target
        UPDATE_INNER_DR:
            sw $t4, 0($t5)
            addi $t7, $t7, 1 
            addiu $t5, $t5, 4
            j START_INNER_DR
        END_INNER_DR: 
            li $t7, 0
            j UPDATE_OUTER_DR
    UPDATE_OUTER_DR:
            addi $t6, $t6, 1
            addi $t1, $t1, 128
            move $t5, $t1
            j START_OUTER_DR
    END_OUTER_DR:
            jr $ra
#===============================================================================