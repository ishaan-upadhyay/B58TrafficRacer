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
# - Displaying lives, spawning cars with random speeds, game over screen
# 
# Additional features that were implemented successfully 
# - Additional feature a/b/c (choose the ones that apply) 
#  - Live score bar
# Link to the video demo 
# - Insert YouTube/MyMedia/other URL here and make sure the video is accessible 
# https://youtu.be/A9yM6tllnnc
# Any additional information that the TA needs to know: 
# - Write here, if any 
#  
######################################################################  
.data
# pickup always occupies the 4th spot in both arrays
copy: .space 4096
speeds: .word -1, -1, -1, -1 # how many clock cycles will it take for the car to move
xpos: .word -1, -1, -1, -1 # x position of the cars/pickups
ypos: .word -1, -1, -1, -1 # y-position of the cars/pickups
count: .word 0 # count of the number of cars currently spawned
lanePositions: .word 1, 9, 18, 26
invincibilityStart: .word 0
colours: .word, 0x00ff21, 0x7f0037
pickupOnScreen: .word 0
pickupType: .word 0
.text
.globl main
#===============================================================================
main:
li $s3, 0 # flag for hard mode
li $s4, 3 # lives
li $s5, 0 # invincibility flag
li $s6, 0 # timer until next car spawns

# Initialize background as grey square
restart: 
li $s1, 1 # start at speed of 1    
li $s2, 26 # car will always stay at y level 25, x can vary between 0 and 27
li $s7, 0 # store current score (time-based)
sw $zero, count($zero)

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
START_LOOP_LN: 
        beq $t9, 32, END_LOOP_LN 
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

# Draw car back in at initial pos
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
    li $v0, 32
    li $a0, 10
    syscall # 50 millisecond sleep
    beq $t8, 1, keypress_happened
    beq $s4, 0, handleQ
    j collisionCheck
    # Check if we're out of lives, if game is not over check for WASD
	keypress_happened: bgtz $s4, handleWASD
# If 1, only listen for [restart] key
	handleQ:
            lw $t2, 4($t9)
            beq $t2, 0x71, main
            j inputProcess
	handleWASD:
            lw $t2, 4($t9)
            li $t8, 0 # Reset the keypress_happened flag to 0
            # Check what keypress is being handled
            beq $t2, 0x77, handleW
            beq $t2, 0x61, handleA
            beq $t2, 0x73, handleS
            beq $t2, 0x64, handleD
            # If none of these keys were pressed, jump to collision check
            j collisionCheck
            handleW: 
                # If speed is maximum already, update other cars, else increment then jump
                beq $s1, 3, collisionCheck
                addi $s1, $s1, 1
                j collisionCheck
            handleA:
                beq $s2, 0, sideCollision
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
                beq $s1, 1, collisionCheck
                addi $s1, $s1, -1 # reduce speed by 1
                j collisionCheck
            handleD:
                beq $s2, 27, sideCollision
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

collisionCheck:
    # Check for car collisions
    carCollision:
        lw $t9, count($zero)
        li $t8, 0
        li $t7, 0
        START_LOOP_COLL: beq $t8, $t9, END_LOOP_COLL
                         lw $s0, ypos($t7)
                         blt $s0, 20, UPDATE_LOOP_COLL # cars cannot have collided
                         # otherwise, check the x of this car against the x of our car
                         lw $s0, xpos($t7)
                         # if the xpos of the other car is within +/- 4 of our cars, we have a collision
                         li $t6, 0
                         sub $t6, $t6, $s2
                         add $s0, $s0, $t6
                         bgt $s0, 4, UPDATE_LOOP_COLL
                         blt, $s0, -4, UPDATE_LOOP_COLL
                         addi $s4, $s4, -1
                         beq $s4, 0, drawGameOver
                         j restart
        UPDATE_LOOP_COLL: addi $t8, $t8, 1
                          addi $t7, $t7, 4
        END_LOOP_COLL: 

    # Check for pickup collisions
    pickupCollision: j updateOther

    # Side collisions (determined by input process)
    sideCollision: addi $s4, $s4, -1
                   beq $s4, 0, drawGameOver
                   j restart

updateOther:
# Generate time until spawning the next car or pickup
# Pick between 2 upper bounds for easy and hard mode    
    bgtz $s6, decreaseTimer # if our timer hasn't hit 0 yet, continue to move cars
    beq $s6, 0, spawnCar # if our timer has finally hit 0, spawn a new car
    # Spawn new car (max 3 on screen anytime)
    spawnCar:
        li $s0, 0
        li $s6, 0
        lw $t9, count($zero)

        beq $t9, 3, moveCars # there are already 3 cars on the screen, continue moving them
        addi $t9, $t9, 1
        sw $t9, count($zero)

        # Pick a lane to spawn into
        li $v0, 42
        li $a0, 2
        li $a1, 4 # generate a number between 0 and 3 to use as an offset to place the car in a lane
        syscall
        
        li $s0, 4
        mult $t9, $s0
        mflo $s0
        addi $s0, $s0, -4
        
        beq $a0, 0, laneOne
        beq $a0, 1, laneTwo
        beq $a0, 2, laneThree
        beq $a0, 3, laneFour
                
        # Lanes switch
        laneOne:
            li $t8, 1
            sw $t8, xpos($s0)
            li $a3, 6
            j getSpeed
        laneTwo:
            li $t8, 9
            sw $t8, xpos($s0)
            li $a3, 6
            j getSpeed
        # Want lower clock cycle max for left side
        laneThree:
            li $t8, 18
            sw $t8, xpos($s0)
            li $a3, 8
            j getSpeed
        laneFour:
            li $t8, 26
            sw $t8, xpos($s0)
            li $a3, 8
            j getSpeed
        # Select a speed to move at (cars in lanes 1 and 2 should be faster)    
        getSpeed:
            li $a0, -6
            sw $a0, ypos($s0) # store initial y position
            li $v0, 42
            li $a0, 0
            li $a1, 4 # generate from 0 to 3 clock cycles and increment
            syscall

            add $a0, $a0, $a3 # adjust by appropriate amount according to lane

            # Check if we need to use some other speed
            lw $t9, count
            addi $t9, $t9, -1
            li $t1, 0
            li $t2, 0
            START_LOOP_SPEED: beq $t1, $t9, END_LOOP_SPEED
                              lw $t0, xpos($t2)
                              bne $t8, $t0, UPDATE_LOOP_SPEED
                              lw $a0, speeds($t2)
                              j END_LOOP_SPEED
            UPDATE_LOOP_SPEED: addi $t1, $1, 1
                               addi $t2, $t2, 4
            END_LOOP_SPEED: sw $a0, speeds($s0)

        # Set timer until next car
        li $t9, -25
        mult $s3, $t9
        mflo $t9
        
        addi $t9, $t9, 101 # on easy, upper limit for spawn timer should be 1750 ms, hard upper should be 1250 ms
        move $a1, $t9
        syscall # generate a random number in the appropriate range
        move $s6, $a0 # grab this number
        beq $s3, 1, hardModeSpawnMin
            addi $s6, $s6, 75 # make sure the timer doesn't try to immediately spawn
            j decreaseTimer # 750ms lower bound on easy
        hardModeSpawnMin: addi $s6, $s6, 50 # 500ms lower bound on hard
    
    decreaseTimer: addi $s6, $s6, -1
    # Move cars down
    moveCars: 
        # Proceed with moving cars
        lw $t9, count($zero) # get the number of cars which have to be updated
        li $t8, 0
        li $a2, 0
        li $a1, 0
        START_LOOP_MOVE: beq $t8, $t9, END_LOOP_MOVE
                         lw $t6, speeds($a2) # speed at position t8 in array
                         sub $t6, $t6, $s1
                         div $s7, $t6
                         mfhi $t6 # check if score % speed is 0
                         bne $t6, $zero, UPDATE_LOOP_MOVE
                         
                         lw $t6, ypos($a2)
                         move $s0, $t6
                         addi $t6, $t6, 1

                         sw $t6, ypos($a2) # store an incremented y
                         li $a3, 0
                         sw $t6, -8($sp) # push y to draw car at to stack
                         

                         blez $t6, carAtTop 
                         bgt $t6, 26, carAtBottom
                     
                         li $t6, 6
                         sw $t6, -12($sp)
                         j commonCarProps

                         carAtTop:
                            sw $zero, -8($sp) # always draw from (x, 0)
                            addi $t6, $t6, 6 # [-5, -4, -3, -2, -1] to [1, 2, 3, 4, 5]
                            sw $t6, -12($sp)
                            li $a3, 1
                            j commonCarProps
                         
                         carAtBottom:  
                            li $t5, 32
                            sub	$t6, $t5, $t6 # [27, 28, 29, 30, 31] to [5, 4, 3, 2, 1]
                            sw $t6, -12($sp)

                        commonCarProps:
                                    lw $t6, xpos($a2)
                                    sw $t6, -4($sp)    # x unchanged for same car

                                    li $t6, 5
                                    sw $t6, -16($sp)    

                                    li $t6, 0xffd800
                                    sw $t6, -20($sp)

                                    la $t6, copy
                                    sw $t6, -24($sp)
                                    addi $sp, $sp, -24
                                    jal drawRect
                                    j grayRectBehind
                        
                        grayRectBehind: 
                            beq $a3, 1, UPDATE_LOOP_MOVE # if we're at the top, no need to draw gray rect, go to next car
                            sw $s0, -8($sp)

                            li $t6, 1
                            sw $t6, -12($sp)

                            li $t6, 0x808080
                            sw $t6, -20($sp)

                            addi $sp, $sp, -24
                            jal drawRect  
        UPDATE_LOOP_MOVE: 
                          addi $a2, $a2, 4
                          addi $t8, $t8, 1
                          j START_LOOP_MOVE

        END_LOOP_MOVE: lw $t9, count($zero) # get the number of cars which have to be checked for removal
                    li $t8, 0
                    li $a2, 0
                    START_LOOP_REMOVE: bgt $t8, $t9, END_LOOP_REMOVE
                                       lw $s0, ypos($a2)
                                       bne $s0, 32, UPDATE_LOOP_REMOVE
                                       # Cases:
						               beq $a2, 4, car3tocar2
						               beq $a2, 8, decrease 
                        car2tocar1:
                           # Copy information from car 2 to car 1
						   # Copy information from car 3 to car 2 
						   lw $s0, speeds+4
						   sw $s0, speeds($zero)
							
						   lw $s0, xpos+4
						   sw $s0, xpos($zero)
							
						   lw $s0, ypos+4
						   sw $s0, ypos($zero)						
                        car3tocar2:
						   # Copy information from car 3 to car 2
						   	lw $s0, speeds+8
							sw $s0, speeds+4
							
							lw $s0, xpos+8
							sw $s0, xpos+4
							
							lw $s0, ypos+8
							sw $s0, ypos+4
                            # All cases require count to be decreased                           
                         decrease:  addi $t9, $t9, -1
						   sw $t9, count($zero)
                           li $a2, 0
                           li $t8, 0

                           # renove from occupied lanes
                           bgt $t9, 1, UPDATE_LOOP_REMOVE
                           lw $s0, xpos($zero)
                           sw $s0, -4($sp)

                            li $s0, 31
                            sw $s0, -8($sp)

                            li $s0, 1
                            sw $s0, -12($sp)

                            li $s0, 5
                            sw $s0, -16($sp)

                            li $s0, 0x808080
                            sw $s0, -20($sp)

                            la $s0, copy
                            sw $s0, -24($sp)
                            addi $sp, $sp, -24
                            jal drawRect

                    UPDATE_LOOP_REMOVE: addi $t8, $t8, 1
                                        addi $a2, $a2, 4
                                        j START_LOOP_REMOVE
                    END_LOOP_REMOVE: 
#===============================================================================
redraw:
# Check game over flag (if 0 jump to draw background)
# Draw game over screen
addi $s7, $s7, 1
blt $s7, 3200, scoreBars
li $s3, 1 # set hard mode enabled after 30 sec

scoreBars: 
# health bar top left corner
sw $zero, -4($sp)
sw $zero, -8($sp)

li $s0, 1
sw $s0, -12($sp)

sw $s4, -16($sp)

li $s0, 0xff00dc
sw $s0, -20($sp)

la $s0, copy
sw $s0, -24($sp)
addi $sp, $sp, -24
jal drawRect

# draw live score bar bottom left
sw $zero, -4($sp) # x = 0

li $s0, 31 # y = 31
sw $s0, -8($sp)

li $s0, 1 # height of 1
sw $s0, -12($sp)

# check if current score divisible by 100 
li $s0, 100
div $s7, $s0

beq $s3, 1, maxEasyBar
    mflo $s0
    sw $s0, -16($sp)
    
    lw $s0, colours+0
    sw $s0, -20($sp)
    j commonBar

maxEasyBar: 
    sw $zero, -4($sp) # x = 0
    
    li $s0, 31 # y = 31
    sw $s0, -8($sp)

    li $s0, 1 # height of 1
    sw $s0, -12($sp)

    li $s0, 32
    sw $s0, -16($sp)

    lw $s0, colours+4
    sw $s0, -20($sp)    

    la $s0, copy
    sw $s0, -24($sp)

    addi $sp, $sp, -24
    jal drawRect

commonBar: la $s0, copy
sw $s0, -24($sp)
addi $sp, $sp, -24
jal drawRect
j copyRedraw

drawGameOver:
    sw $zero, -4($sp) 
    sw $zero, -8($sp)
    
    li $s0, 32
    sw $s0, -12($sp)

    li $s0, 32 
    sw $s0, -16($sp)

    li $s0, 0x000000
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)

    addi $sp, $sp, -24
    jal drawRect

    li $s0, 6
    sw $s0, -4($sp) 

    li, $s0, 12
    sw $s0, -8($sp)
    
    li $s0, 3
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 7
    sw $s0, -4($sp) 

    li, $s0, 12
    sw $s0, -8($sp)
    
    li $s0, 1
    sw $s0, -12($sp)

    li $s0, 3
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 9
    sw $s0, -4($sp) 

    li, $s0, 13
    sw $s0, -8($sp)
    
    li $s0, 5
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 7
    sw $s0, -4($sp) 

    li, $s0, 14
    sw $s0, -8($sp)
    
    li $s0, 1
    sw $s0, -12($sp)

    li $s0, 2
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 11
    sw $s0, -4($sp) 

    li, $s0, 12
    sw $s0, -8($sp)
    
    li $s0, 3
    sw $s0, -12($sp)

    li $s0, 3
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 12
    sw $s0, -4($sp) 

    li, $s0, 13
    sw $s0, -8($sp)
    
    li $s0, 1
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0x000000
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 15
    sw $s0, -4($sp) 

    li, $s0, 12
    sw $s0, -8($sp)
    
    li $s0, 1
    sw $s0, -12($sp)

    li $s0, 5
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 15
    sw $s0, -4($sp) 

    li, $s0, 13
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 17
    sw $s0, -4($sp) 

    li, $s0, 13
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 19
    sw $s0, -4($sp) 

    li, $s0, 13
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 21
    sw $s0, -4($sp) 

    li, $s0, 12
    sw $s0, -8($sp)
    
    li $s0, 4
    sw $s0, -12($sp)

    li $s0, 4
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 22
    sw $s0, -4($sp) 

    li, $s0, 13
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 3
    sw $s0, -16($sp)

    li $s0, 0x000000
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 6
    sw $s0, -4($sp) 

    li, $s0, 19
    sw $s0, -8($sp)
    
    li $s0, 4
    sw $s0, -12($sp)

    li $s0, 4
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 7
    sw $s0, -4($sp) 

    li, $s0, 20
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 2
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 11
    sw $s0, -4($sp) 

    li, $s0, 19
    sw $s0, -8($sp)
    
    li $s0, 4
    sw $s0, -12($sp)

    li $s0, 3
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 12
    sw $s0, -4($sp) 

    li, $s0, 19
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 15
    sw $s0, -4($sp) 

    li, $s0, 19
    sw $s0, -8($sp)
    
    li $s0, 4
    sw $s0, -12($sp)

    li $s0, 4
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 16
    sw $s0, -4($sp) 

    li, $s0, 20
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 3
    sw $s0, -16($sp)

    li $s0, 0x000000
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 16
    sw $s0, -4($sp) 

    li, $s0, 20
    sw $s0, -8($sp)
    
    li $s0, 2
    sw $s0, -12($sp)

    li $s0, 3
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 20
    sw $s0, -4($sp) 

    li, $s0, 19
    sw $s0, -8($sp)
    
    li $s0, 4
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

    li $s0, 21
    sw $s0, -4($sp) 

    li, $s0, 19
    sw $s0, -8($sp)
    
    li $s0, 4
    sw $s0, -12($sp)

    li $s0, 1
    sw $s0, -16($sp)

    li $s0, 0xFFFFFF
    sw $s0, -20($sp)

    la $s0, copy
    sw $s0, -24($sp)
    addi $sp, $sp, -24
    jal drawRect

# If game not over, copy over from copy
copyRedraw: li $s0, 0
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
