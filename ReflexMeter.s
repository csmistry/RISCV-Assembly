##################################################
## Name:    Reflex Meter with Infinite Counter	##
## Purpose:	Reaction Time Measurement	##
## Author: Chintan Mistry & Nitish Vobbalareddy ##
##################################################

# Start of the data section
.data			
.align 4						# To make sure we start with 4 bytes aligned address 
SEED:
	.word 0x1234				# Put any non zero seed
	
# The main function must be initialized in that manner in order to compile properly on the board
.text
.globl	main
main:
	# Put your initializations here
	li s1, 0x7ff60000 			# assigns s1 with the LED base address (Could be replaced with lui s1, 0x7ff60)
	li s2, 0x7ff70000 			# assigns s2 with the push buttons base address (Could be replaced with lui s2, 0x7ff70)				
	li s7, 0x00					#s7 holds 8 bit value to be displayed on LEDS (initially zero)
	li s3, 0x100				#s3 holds the max value for the infinite counter
	li s4, 0x4E20				#lower bound on time delay
	li s5, 0x186A1				#Upper bound on time delay	(100001 due to bge)
	li a7, 15					#represents button state when none are pressed
	li s9, 14					#Represents button state when PB0 is pressed
	li s10, 13					#Represents button state when PB1 is pressed
	li s8, 11					#Used 

	j Infinite_Counter
	


	
	
# End of main function		
		



# Subroutines			

DELAY:
#Total delay is a0*0.1ms
	mv t5, a0										#outer loop iterates a0 times
	outer_loop:
	li a3, 1250										# 0.1ms delay value (25 MHz x 0.0001(one 10th of ms) = 2500 --> 2 instructions per loop thus 1250 
		inner_loop:									#innner loop does 0.1ms delay 
			addi a3, a3, -1	
			bne a3, zero, inner_loop
		addi t5, t5, -1
		bne t5, zero, outer_loop
	jr ra 




Reflex_Meter:
	jal LED_OFF							#Turn all LEDS OFF
						
    scale_loop:							
    	jal RANDOM_NUM		
        slli a0, a0, 1					#scale random num by factor of 2	
		bge a0, s5, scale_loop			#Keep calling RANDOM_NUM until it generates a value within 20000 100000
		blt a0, s4, scale_loop			#Keep calling RANDOM_NUM until it generates a value within 20000 100000

	jal DELAY							#Delay for ScaledNumber*0.1ms
	li s7, 0x01							#turn first LED ON
	jal LED_ON		
	li s6, 0							#initialize reaction time counter
	wait_loop:
		li a0, 1						#Delay 0.1ms
		jal DELAY
		addi s6, s6, 1					#increment reflex counter
		lw t5, 0(s2)					#check if button 0 was pressed											
		beq t5, a7, wait_loop			#continue incrementing and checking until button 0 is pressed
										#a7 contains 15 which represents all buttons off
		j DISPLAY_NUM



#Display each byte of 32-bit word
DISPLAY_NUM:

	li s7, 0x00					#8 bit LED value		
	li t6, 0xff					#8 bits all true used to get individual bytes	
	addi a5, s6, 0				#Temporary counter value which will get shifted during displaying	
	
	#1st byte
	and s7, a5, t6				#get first byte
	jal LED_ON					#display current byte in s7 on the LEDS
	li a1, 20000				#wait 2 seconds
	first_byte:
		li a0, 1				#0.1ms delay
		jal DELAY			
		lw t5, 0(s2)			#load current button states										
		beq t5, s10, EXIT   	#check if button 1 was pressed, if it is EXIT (S10 == 13)
		addi a1 , a1, -1		#Decrement outerloop iteration
		bne a1, zero, first_byte
	srli a5, a5, 8				#shift right to get the next byte (8 bits == 1 byte)

## The below statements are the same as above but for the remaining bytes ##

	#2nd byte
	and s7, a5, t6			
	jal LED_ON				
	li a1, 20000
	second_byte:
		li a0, 1
		jal DELAY			
		lw t5, 0(s2)													
		beq t5, s10, EXIT
		addi a1 , a1, -1
		bne a1, zero, second_byte
	srli a5, a5, 8			

	#3rd byte
	and s7, a5, t6			
	jal LED_ON				
	li a1, 20000
	third_byte:
		li a0, 1
		jal DELAY			
		lw t5, 0(s2)												
		beq t5, s10, EXIT
		addi a1 , a1, -1
		bne a1, zero, third_byte
	srli a5, a5, 8			

	#4th byte
	and s7, a5, t6			
	jal LED_ON				
	li a1, 50000				#hold last byte for 5 seconds
	fourth_byte:
		li a0, 1
		jal DELAY			
		lw t5, 0(s2)												
		beq t5, s10, EXIT
		addi a1 , a1, -1
		bne a1, zero, fourth_byte
	srli a5, a5, 8			
	
	j DISPLAY_NUM				#Continue displaying the bytes 

	EXIT:	
		j Reflex_Meter					#return back to main to restart the reflex meter	




Infinite_Counter:
	li s7, 0x00					#initially all LEDS OFF
	li s3, 0x100				#max iteration value for infinite counter ==> 256 (used so we can display 255)	
	loop:
		jal LED_ON				#Turn on LEDS correscponding to value in s7
		li a0, 1000				#0.0001* 1000 = 0.1 s delay
		jal DELAY
		lw t5, 0(s2)
		beq t5, s8, START_REFLEX
		addi s7, s7, 1			#Increment s7 on each 0.1s 
		bne s7, s3, loop
	li s7, 0x00
	j loop

	START_REFLEX:
		j Reflex_Meter



RANDOM_NUM:
	# This is a pseudorandom number generator. (the random number is saved at a0)
	addi sp, sp, -4				# push ra to the stack
	sw ra, 0(sp)
	la gp, SEED				# load address of the random number in memory
	
	lw t0, 0(gp)				# load the seed or the last previously generated number from the data memory to t0
	li t1, 0x8000
	and t2, t0, t1				# mask bit 16 from the seed
	li t1, 0x2000
	and t3, t0, t1				# mask bit 14 from the seed
	slli t3, t3, 2				# allign bit 14 to be at the position of bit 16
	xor t2, t2, t3				# xor bit 14 with bit 16
	li t1, 0x1000		
	and t3, t0, t1				# mask bit 13 from the seed
	slli t3, t3, 3				# allign bit 13 to be at the position of bit 16
	xor t2, t2, t3				# xor bit 13 with bit 14 and bit 16
	andi t3, t0, 0x400				# mask bit 11 from the seed
	slli t3, t3, 5				# allign bit 14 to be at the position of bit 16
	xor t2, t2, t3				# xor bit 11 with bit 13, bit 14 and bit 16
	srli t2, t2, 15				# shift the xoe result to the right to be the LSB
	slli t0, t0, 1				# shift the seed to the left by 1
	or t0, t0, t2				# add the XOR result to the shifted seed 
	li t1, 0xFFFF				
	and t0, t0, t1				# clean the upper 16 bits to stay 0
	sw t0, 0(gp)				# store the generated number to the data memory to be the new seed
	mv a0, t0					# copy t0 to a0 as a0 is always the return value of any function
	
	lw ra, 0(sp)				# pop ra from the stack
	addi sp, sp, 4
	jr ra

LED_ON:
	#Turn LED on
    sw s7, 0(s1)
	jr ra

LED_OFF:
	#Turn LED off
    sw zero, 0(s1)
	jr ra

