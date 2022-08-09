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

.text
.globl main

main:
# Initialize background as grey square 
sw $zero, -4($sp)
sw $zero, -8($sp)
li $s0, 32
sw $s0, -12($sp)
sw $s0, -16($sp)
li $s0, 0x808080
sw $s0, -20($sp)
addi $sp, $sp, -20

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
addi $sp, $sp, -20
jal drawRect

# Draw lane dividers
li $t9, 0
START_LOOP_LN: beq $t9, 32, END_LOOP_LN 
        # Tell drawRect to go to (7, ?) and (24, ?)
        li $s0, 7
		sw $s0, -4($sp)
        li $s0, 24
        sw $s0, -24($sp)

        # Go to (7, y) and (24, y)
		sw $t9, -8($sp)
        sw $t9, -28($sp)
        
        # Set height to 3
        li $s0, 3
	sw $s0, -12($sp)
        sw $s0, -32($sp)
		
        # Set width to 1
        li $s0, 1
        sw $s0, -16($sp)
        sw $s0, -36($sp)
		
        # Set colour to white 
        li $s0, 0xFFFFFF
        sw $s0, -20($sp)
        sw $s0, -40($sp)

		addi $sp, $sp, -40
		jal drawRect # draw nth lane divider between opposite traffic lanes
		jal drawRect # draw nth lane divider between same direction traffic lanes			
UPDATE_LOOP_LN:
	addi $t9, $t9, 4
	j START_LOOP_LN
END_LOOP_LN:


li $v0, 10
syscall

inputProcess:
# Check game over flag
	beq $s7, 0, HandleWASD
# If 1, only listen for [restart] key
	
	HandleWASD:
	

updateCar:

collisionCheck:

updateOther:

redraw:
# Check game over flag (if 0 jump to draw background)

# Draw game over screen
#jal inputProcess
    drawGO:
# Draw background
    drawBG:

drawRect:
    lw $t4 0($sp) # Pop colour from stack
    lw $t3 4($sp) # Pop width of rectangle from stack
    lw $t2 8($sp) # Pop height of rectangle from stack
    lw $t1 12($sp) # Pop y-coordinate of rectangle from stack
    lw $t0 16($sp) # Pop x-coordinate of top-left corner of rectangle
    addi $sp, $sp, 20 # Advance stack pointer

    # Calculate position of top-left corner 
    move $t5, $gp #$t5 = gp
    
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
