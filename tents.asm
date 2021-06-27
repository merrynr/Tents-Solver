# File:		tents.asm
# Description:  Program to solve tents puzzles algorithmically through 
# 		backtracking. The rules of the tents puzzle are:
#		1. Each tree has exactly one tent attached to it.
#		2. Each tent is attached to one tree (so there are as many 
#		   tents as there are trees).
#		3. The numbers across the bottom and down the side tell you 
#		   how many tents are in the respective column or row.
#		4. A tent can only be placed horizontally or vertically 
#		   adjacent to a tree.
#		5. Tents are never adjacent to each other, neither 
#		   vertically, horizontally, nor diagonally.
#		6. A tree might be next to two tents, but is only connected 
#		   to one.

# syscall codes
PRINT_INT =     1
PRINT_STRING =  4
READ_INT =      5
READ_STRING =	8
EXIT =          10
        .data
        .align 2

# constant params
board_size_min = 2
board_size_max = 12

direction_table:
	.word	N, W, E, S, NW, NE, SW, SE

board_size:
        .word   0
row_total:
        .word   0
row_sums:
        .space  12*4
col_sums:
        .space  12*4
row_sums_total:
	.word   0
col_sums_total:
	.word   0
trees_total:
	.word	0
trees_arr:
	.space	36*4

        #
        # string data
        #
        .align 0

row_sums_in:
        .space  13
col_sums_in:
        .space  13
board:
        .space  12*12+1

        #
        # the print constants for the code
        #
banner_msg:
        .asciiz "\n******************\n**     TENTS    **\n******************"

invld_msg1:
        .asciiz "\nInvalid board size, Tents terminating\n"
invld_msg2:
        .asciiz "\nIllegal sum value, Tents terminating\n"
invld_msg3:
        .asciiz "\nIllegal board character, Tents terminating\n"

init_msg:
        .asciiz "\nInitial Puzzle\n"
fin_msg:
        .asciiz "\nFinal Puzzle\n"
err_msg:
        .asciiz "\nImpossible Puzzle\n"

tree:
        .asciiz "T"
tent:
        .asciiz "A"
grass:
        .asciiz "."

bar:
        .asciiz "|"
dash:
        .asciiz "-"
plus:
        .asciiz "+"
space:
        .asciiz " "
new_line:
        .asciiz "\n"


	.text                   # this is program code
        .align  2               # instructions must be on word boundaries
        .globl  main            # main is a global label

#
# Name:         MAIN PROGRAM
#
# Description:  Main logic for the program.
#
#	This program reads in a tents-and-trees puzzle, and solves it by 
#	recursively trying every possible combination of tent placements.
#	If a valid solution is found, it will print out the final board with
#	the tent placements. Otherwise, it will state "impossible puzzle".

main:
	addi	$sp,$sp, -36	# allocate stack frame (on doubleword boundary)
	sw	$ra, 32($sp)	# store the ra & s reg's on the stack
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)	# board_size

	jal     print_banner		# print banner

# check_board_size
	li	$v0, READ_INT		# read board size from input
	syscall

	sw	$v0, board_size
	move	$s0, $v0
	jal	validate_board_size

	bne	$v0, $zero, check_row_sums
	li      $v0, PRINT_STRING	#invalid board_size
        la      $a0, invld_msg1
        syscall
	j	main_done
	
check_row_sums:
	la	$a0, row_sums_in
	addi	$a1, $s0, 2 	# read chars to read = board_size + 1
	li	$v0, READ_STRING	# read row/col sums from input
	syscall

	la      $a0, col_sums_in
	li      $v0, READ_STRING
	syscall
	
	la	$a0, row_sums_in	# convert row/col input -> integers
	la	$a1, row_sums		# Note: input MUST be numbers
	la	$a2, row_sums_total
	jal	validate_sums
	beq	$v0, $zero, _invalid_row_sums

	la	$a0, col_sums_in
	la	$a1, col_sums
	la	$a2, col_sums_total
	jal	validate_sums
	beq	$v0, $zero, _invalid_row_sums

	#lw	$t1, row_sums_total
	#lw      $t2, col_sums_total
	#bne	$t1, $t2, _invalid_row_sums
	j	check_board

_invalid_row_sums:
	li	$v0, PRINT_STRING
	la	$a0, invld_msg2
	syscall
	j	main_done

check_board:
	# read board with a for loop (i=0, i<board_size, i++
	# $t0 -> loop counter
	# $a0 -> address of read input buffer
	# $a1 -> max size to read
	# $t2 -> bool var
	move	$t0, $zero
	la	$a0, board
	addi	$a1, $s0, 2		# chars 2 read = board_size + 2 (\n\0)

_read_board:
	slt	$t2, $t0, $s0
	beq	$t2, $zero, _read_done

	li	$v0, READ_STRING	# read row/col sums from input
	syscall

	add	$a0, $a0, $s0		# move board addr to next row
	addi	$t0, $t0, 1		# increment loop counter
	j	_read_board

_read_done:
	jal	validate_board		# validate the board
	bne	$v0, $zero, do_puzzle

	li      $v0, PRINT_STRING
        la      $a0, invld_msg3
        syscall
        j       main_done

do_puzzle:
	la	$a0, init_msg
	jal	print_board
	
	# initialize puzzle solver memory/data structures
	jal	initialize_puzzle
	beq	$v0, $zero, _no_solution
	# run backtracking algorithm
	jal     solve_puzzle
	beq	$v0, $zero, _no_solution

	li	$v0, PRINT_STRING	# print the solved board
	la	$a0, fin_msg
	jal	print_board
	li      $v0, PRINT_STRING
	la      $a0, new_line
        syscall
	j	main_done

_no_solution:
	li	$v0, PRINT_STRING
	la	$a0, err_msg
	syscall
	la	$a0, new_line
	syscall

main_done:
	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
        lw      $s7, 28($sp)
        lw      $s6, 24($sp)
        lw      $s5, 20($sp)
        lw      $s4, 16($sp)
        lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp,$sp, 36	# clean up stack
        jr      $ra		# return from main and exit

#----------------------------------- Solver -----------------------------------
# 
# Name:		initialize_puzzle
#
# Description:	pre-processes/populates data structures needed to solve puzzle
#
# Arguments:	none
# Returns:	$v0 as 1 if valid or 0 if invalid (impossible puzzle)
#
initialize_puzzle:
	# $t0 -> loop counter
	# $t1 -> loop max value
	# $t2 -> bool var XXX
	# $t3 -> board address
	# $t4 -> entered ascii board char
	# $t5 -> "T"
	# $t6 -> address of trees array
	# $t7 -> count of total # of trees

	move	$t0, $zero
	lw	$t1, board_size
	mul	$t1, $t1, $t1
	la	$t3, board
	lb	$t5, tree
	la	$t6, trees_arr
	move	$t7, $zero
	move	$v0, $zero	# init result as false

init_puzzle_loop:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, init_puzzle_loop_done

	lb	$t4, 0($t3)

	bne	$t4, $t5, init_puzzle_loop_next # check if "T"
	sw	$t0, 0($t6)	# store index of tree
	addi	$t7, $t7, 1
	addi	$t6, $t6, 4	# increment addr (tree array)

init_puzzle_loop_next:
	addi	$t3, $t3, 1	# increment addr (board)
	addi	$t0, $t0, 1	# increment counter
	j	init_puzzle_loop

init_puzzle_loop_done:
	sw	$t7, trees_total
	lw      $t2, row_sums_total
	bne	$t7, $t2, init_puzzle_done
        li      $v0, 1          # set result = true

init_puzzle_done:
	jr	$ra

# 
# Name:         solve_puzzle
#
# Description:  wrapper function for recursive solve; setup variables
#
# Arguments:    none
# Returns:      $v0 as 1 if valid or 0 if invalid (what sub-function returns)
#
solve_puzzle:
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	move	$a0, $zero
	lw	$a1, trees_total
	la	$a2, board
	jal	solve

	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

# 
# Name: 	solve
#
# Description:	primary recursive backtracking algorithm used to solve tents &
#		trees puzzle
#
# Arguments:	$a0 -> index of current tree in tree_arr
#		$a1 -> total # of trees
#		$a2 -> address of current board location
# Returns:	$v0 as 1 if valid or 0 if invalid (impossible puzzle)
#
solve:
	addi	$sp, $sp, -36
	sw	$ra, 32($sp)	# NOTE: s7 is EXTREMELY IMPORTANT
	sw	$s7, 28($sp)	# $s7 -> loop counter aka directions (N,W,E,S)
	sw	$s6, 24($sp)	# $s6 -> position of adjacent square
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)	
	sw	$s3, 12($sp)	# $s3 -> position of current tree
	sw	$s2, 8($sp)	# $s2 -> $a2; address of current board location
	sw	$s1, 4($sp)	# $s1 -> $a1; total # of trees
	sw	$s0, 0($sp)	# $s0 -> $a0; index of current tree

	move	$s0, $a0
	move	$s1, $a1
	move	$s2, $a2

# base case: if no tents left to place, return true(1)
	slt	$t1, $s0, $s1
	bne	$t1, $zero, solve_recur
	li	$v0, 1
	j	solve_done

#recursive cases:
solve_recur:
	# $t1 -> bool var/temp
        # $t2 -> bool var/temp

	la	$t1, trees_arr
	li	$t2, 4
	mul	$t2, $t2, $s0	# displacement=4*tree_index
	add	$t1, $t1, $t2
	lw	$s3, 0($t1)	# get the position of current tree

	move	$s7, $zero	# init loop counter (N,W,E,S)

solve_loop:
	slti	$t2, $s7, 4
	beq	$t2, $zero, solve_loop_done

	# get a position next to current tree
	move	$a0, $s7	# pass-in (N,W,E,S)
	move	$a1, $s3	# pass-in position of tree
	jal	calculate_position
	move	$s6, $v0
	slti	$t1, $s6, 0
	bne	$t1, $zero, solve_loop_next

	# check if generated position is a grass
	move	$a0, $s6
	jal	verify_grass
	beq     $v0, $zero, solve_loop_next

	# check if generated position is not next to another tent
	move    $a0, $s6
	jal	verify_neighbors
	beq     $v0, $zero, solve_loop_next

	# check if total number of tents doesn't exceed rol/col sum
	move	$a0, $s6
	jal	verify_sums
	beq	$v0, $zero, solve_loop_next

	lb	$t1, tent	# if ok, place tent
	la      $t2, board
	add	$t2, $t2, $s6	# addr of position to put tent
	sb	$t1, 0($t2)

# $a0 -> index of current tree in tree_arr
# $a1 -> total # of trees
# $a2 -> address of current board location
	# call solve to recurse through next tree
	addi	$s0, $s0, 1	# increment tree index (move on to next tree)

	move	$a0, $s0
	move	$a1, $s1
	move    $a2, $s2
	jal	solve
	beq	$v0, $zero, solve_loop_backtrack
	
	li	$v0, 1 # solution found: set result true and return
	j	solve_done
	
	
solve_loop_backtrack:
	lb	$t1, grass	# if failed, remove tent
	la	$t2, board
	add	$t2, $t2, $s6   # addr of position to remove tent (put grass)
	sb	$t1, 0($t2)
	addi	$s0, -1

solve_loop_next:
	addi    $s7, $s7, 1     # increment counter
        j       solve_loop

solve_loop_done:
	# if all else fails and nothing worked, return false
	move	$v0, $zero

solve_done:
	lw	$ra, 32($sp)
	lw	$s7, 28($sp)
	lw	$s6, 24($sp)
	lw	$s5, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, 36
	jr	$ra

# 
# Name: 	calculate_position
#
# Description:  Solve Helper Function - calculates the position of an adjacent
#		square from given square and direction
#
# Arguments:	$a0 -> direction from the given square
#               $a1 -> position of current board location (square)
# Returns:      $v0 -> position of the adjacent square or -1 if invalid
#
calculate_position:
	li	$v0, -1 		# default invalid position = -1
	lw	$t3, board_size

	div	$t4, $a1, $t3		# row
	rem	$t5, $a1, $t3		# column
	addi	$t6, $t3, -1		# max row/col

	slti	$t0, $a0, 0
	bne	$t0, $zero, calc_pos_done
	li	$t1, 7
	slt	$t0, $t1, $a0
	bne	$t0, $zero, calc_pos_done

	la	$t0, direction_table	# load addr of jump table
	mul	$t1, $a0, 4
	add	$t0, $t0, $t1
	lw	$t2, 0($t0)
	jr	$t2

N:
	beq	$t4, $zero, calc_pos_done
	sub	$v0, $a1, $t3		# calc pos & pass as arg to validate
	j	calc_pos_done
W:
	beq     $t5, $zero, calc_pos_done
	addi	$v0, $a1, -1
	j	calc_pos_done
E:
	beq	$t5, $t6, calc_pos_done
	addi	$v0, $a1, 1
	j	calc_pos_done
S:
	beq	$t4, $t6, calc_pos_done
	add	$v0, $a1, $t3
	j	calc_pos_done
NW:
	beq	$t4, $t6, calc_pos_done
	beq	$t5, $zero, calc_pos_done
	sub     $v0, $a1, $t3
	addi    $v0, $v0, -1
	j       calc_pos_done
NE:
	beq     $t4, $zero, calc_pos_done
	beq     $t5, $t6, calc_pos_done
	sub     $v0, $a1, $t3
	addi    $v0, $v0, 1
	j       calc_pos_done
SW:
	beq	$t4, $t6, calc_pos_done
	beq	$t5, $zero, calc_pos_done
	add     $v0, $a1, $t3
	addi    $v0, $v0, -1
	j       calc_pos_done
SE:
	beq	$t4, $t6, calc_pos_done
	beq	$t5, $t6, calc_pos_done
	add	$v0, $a1, $t3
	addi	$v0, $v0, 1

calc_pos_done:
	jr	$ra

# 
# Name:         verify_grass
#
# Description:  Solver Helper Function - checks if the position specified is
#               a "." or grass square
#
# Arguments:    $a0 -> postion of given square
# Returns:      $v0 -> 1 if grass or 0 if not
#
verify_grass:
	# $t0 -> addr of board
        # $t1 -> ascii value on given square
	# $t2 -> "." grass

	move	$v0, $zero

	lb	$t2, grass
	la	$t0, board
	add	$t0, $t0, $a0
	lb	$t1, 0($t0)
	
	bne	$t1, $t2, ver_grass_done
	li	$v0, 1

ver_grass_done:
	jr	$ra

# 
# Name:         verify_neighbors
#
# Description:  Solver Helper Function - checks if there are no tents next to
#		the position specifed
#
# Arguments:    $a0 -> postion of given square
# Returns:      $v0 -> 1 if valid (no tents) or 0 if invalid (a tent exists)
#	
verify_neighbors:
	# calculate_position
	# Args:    $a0 -> direction from the given square
	# 	   $a1 -> position of current board location (square)
	# Ret:     $v0 -> position of the adjacent square or -1 if invalid

	addi    $sp,$sp, -24
	sw	$ra, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp) 

	# $s0 -> loop counter
	# $s1 -> $a0 aka postion of given square
	# $s2 -> address of board
	# $s3 -> "A" ascii for tent
	# $s4 -> return value of function (will pass to $v0)

	# $t0 -> address of current board location
	# $t1 -> bool/temp & ascii value var
	# $t2 -> bool/temp var

	move    $s0, $zero	# init loop counter
	move	$s1, $a0
	la	$s2, board
	lb	$s3, tent
	li	$s4, 1

ver_neighbors_loop:
	slti	$t2, $s0, 8	# for each direction (N,W,E,S,NW,NE,SW,SE)
	beq	$t2, $zero, ver_neighbors_done

	move	$a0, $s0
	move	$a1, $s1
	jal	calculate_position	# calculate adjacent position
	slti	$t1, $v0, 0
	bne	$t1, $zero, ver_neighbors_loop_next

        add	$t0, $s2, $v0
        lb	$t1, 0($t0)
	beq	$t1, $s3, ver_neighbors_invalid

ver_neighbors_loop_next:
	addi	$s0, $s0, 1     # increment counter
	j	ver_neighbors_loop

ver_neighbors_invalid:
	move	$s4, $zero

ver_neighbors_done:
	move	$v0, $s4

	lw	$ra, 20($sp)
	lw	$s4, 16($sp)
	lw	$s3, 12($sp)
	lw	$s2, 8($sp)
	lw	$s1, 4($sp)
	lw	$s0, 0($sp)
	addi    $sp, $sp, 24
	jr	$ra

# 
# Name:		verify_sums
#
# Description:  Solver Helper Function - checks if total number of tents
#		in row/col does not exceed sums
#
# Arguments:    $a0 -> postion of given square
# Returns:      $v0 -> 1 if valid (under sum) or 0 if invalid (equal/over sum)
#
verify_sums:
	# $t0 -> loop counter
	# $t1 -> board_size (how many times to loop)
	# $t2 -> row/col
	# $t3 -> first position in row/col
	# $t4 -> address of first position in row/col
	# $t5 -> row/col sum
	# $t6 -> tent counter
	# $t7 -> temp/used for calculations
	# $t8 -> temp/used for calculations
	# $t9 -> "A" ascii for tent

# check row sum
	move	$v0, $zero	# initialize return value

	lw	$t1, board_size
	lb	$t9, tent

	div	$t2, $a0, $t1	# row
	mul	$t3, $t2, $t1	# first position in row
	la	$t4, board
	add	$t4, $t4, $t3	# address of first position in row
	la	$t5, row_sums
	mul	$t7, $t2, 4
	add	$t5, $t5, $t7
	lw	$t5, 0($t5)	# row sum

	move    $t0, $zero      # loop counter
	move	$t6, $zero	# tent counter
	
ver_sums_row_loop:
	slt	$t8, $t0, $t1
	beq	$t8, $zero, ver_sums_row_loop_done

	lb	$t7, 0($t4)
	bne	$t7, $t9, ver_sums_row_loop_next
	add	$t6, $t6, 1	# if tent, increment tent count

ver_sums_row_loop_next:
	addi	$t4, $t4, 1	# increment addr, next square
	addi	$t0, $t0, 1	# increment loop counter
	j	ver_sums_row_loop

ver_sums_row_loop_done:
	slt	$t8, $t6, $t5	# check if tent count < row sum
	beq	$t8, $zero, ver_sums_done

# check column sum
	rem	$t2, $a0, $t1	# col
	move	$t3, $t2	# first position in col
	la	$t4, board
	add	$t4, $t4, $t3	# address of first position in col
	la	$t5, col_sums
	mul	$t7, $t2, 4
	add	$t5, $t5, $t7
	lw	$t5, 0($t5)	# col sum

	move	$t0, $zero	# loop counter
	move	$t6, $zero	# tent counter

ver_sums_col_loop:
	slt	$t8, $t0, $t1
	beq	$t8, $zero, ver_sums_col_loop_done

	lb	$t7, 0($t4)
	bne	$t7, $t9, ver_sums_col_loop_next
	add	$t6, $t6, 1	# if tent, increment tent count	

ver_sums_col_loop_next:
	add	$t4, $t4, $t1	# increment addr, next square
	addi	$t0, $t0, 1	# increment loop counter
	j	ver_sums_col_loop

ver_sums_col_loop_done:
	slt	$t8, $t6, $t5	# check if tent count < col sum
	beq	$t8, $zero, ver_sums_done

	li	$v0, 1

ver_sums_done:
	jr	$ra

#---------------------------- Input Validation --------------------------------

# 
# Name:         validate_board_size
#
# Description:  checks if board_size is between 2 and 12
#
# Arguments:    none
# Returns:      $v0 as 1 if valid or 0 if invalid
#
validate_board_size:
	move	$v0, $zero			#initialize false

	lw	$t1, board_size
	slti	$t0, $t1, board_size_min
	bne	$t0, $zero, board_size_done

	li	$t2, board_size_max
	slt	$t0, $t2, $t1
	bne	$t0, $zero, board_size_done

	li	$v0, 1				#set result true

board_size_done:
	jr	$ra

# 
# Name: 	validate_sums
#
# Description:	checks if row/col sums are between 0 and (n+1)/2 inclusive
#		while converting string of ascii row/col sums -> array of int
# Arguments:	$a0 as address of ascii string
#		$a1 as address of int array
#		$a2 as address of sum_total
# Returns:	$v0 as 1 if valid or 0 if invalid
#
validate_sums:
	# $t0 -> counter
	# $t1 -> row/col sum total
	# $t2 -> obtained number from ascii string
	# $t3 -> max sum total or (n+1)/2
	# $t4 -> temp/validation variable

	lw	$t0, board_size	# init loop counter
	move	$t1, $zero	# init row/col sum total
	move	$v0, $zero	# init result as false

	lw	$t3, board_size # calculate (n+1)/2
	addi	$t3, $t3, 1
	li	$t4, 2
	div	$t3, $t3, $t4

val_sums_loop:
	beq	$t0, $zero, val_sums_loop_done

	lb	$t2, 0($a0)
	addi	$t2, $t2, -48	# convert ascii# to int

	slt     $t4, $t2, $zero
	bne	$t4, $zero, val_sums_done	# check if total < 0

	slt	$t4, $t3, $t2		# check if total > (n+1)/2
	bne	$t4, $zero, val_sums_done

	sw	$t2, 0($a1)	# process ascii to int & save
	add	$t1, $t1, $t2	# sum running total

	addi	$a0, $a0, 1
	addi	$a1, $a1, 4

	addi	$t0, $t0, -1	# decrease number of numbers left
	j	val_sums_loop

val_sums_loop_done:
	li      $v0, 1		# set result = true
	sw	$t1, 0($a2)	# save sum total in mem

val_sums_done:
	jr      $ra

# 
# Name:         validate_board
#
# Description:  checks to ensure board contains only "." grass and "T" trees
# Arguments:	none
# Returns:      $v0 as 1 if valid or 0 if invalid
#
validate_board:
	# $t0 -> loop counter
	# $t1 -> loop max value
	# $t2 -> bool var XXX
	# $t3 -> board address
	# $t4 -> entered ascii board char
	# $t5 -> "."
	# $t6 -> "T"

	move	$t0, $zero
	lw	$t1, board_size
	mul	$t1, $t1, $t1
	la	$t3, board
	lb	$t5, grass
        lb      $t6, tree
	move    $v0, $zero      # init result as false

val_board_loop:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, val_board_loop_done

	lb	$t4, 0($t3)

	beq	$t4, $t5, val_board_loop_passed	# check if "."
	beq	$t4, $t6, val_board_loop_passed	# check if "T"
	j	val_board_done

val_board_loop_passed:
	addi	$t3, $t3, 1	# increment addr
	addi	$t0, $t0, 1	# increment counter
	j	val_board_loop

val_board_loop_done:
	li	$v0, 1		# set result = true

val_board_done:
	jr      $ra

#---------------------------- Output Functions --------------------------------

# 
# Name:         print_banner
#
# Description:  prints the tents banner
#
# Arguments:    none
# Returns:      none
#
print_banner:
	li	$v0, PRINT_STRING
	la	$a0, banner_msg
	syscall 		# print "banner"
	#li	$v0, PRINT_STRING
	la	$a0, new_line
	syscall 		# print "\n"

	jr	$ra

# 
# Name:         print_board
#
# Description:  prints the puzzle board stored in "board"
#
# Arguments:    $a0 -> title message of board
# Returns:      none
#
print_board:
	addi	$sp, $sp, -8	# allocate stack frame
	sw	$ra, 4($sp) 	# store the ra & s reg's on the stack
	sw	$s0, 0($sp)

	li      $v0, PRINT_STRING
        syscall 		# print arg message
        #li      $v0, PRINT_STRING
        la      $a0, new_line
        syscall
	
	jal	print_board_helper

	# print-row loop
	# $t0 -> loop counter (row)
	# $s0 -> board_size
	# $t2 -> bool var/temp (for slt)
	# $t3 -> address of row_sums
	# $t4 -> address of board
	# $t5 -> ascii for grass "."
	# $t6 -> ascii for tree "T"

	move	$t0, $zero
	lw	$s0, board_size
	la	$t3, row_sums
	la	$t4, board
	lb	$t5, grass
	lb	$t6, tree

prt_board_loop1:
	slt	$t2, $t0, $s0
	beq	$t2, $zero, prt_board_loop1_done

	li	$v0, PRINT_STRING
	la	$a0, bar
	syscall
	#li	$v0, PRINT_STRING
	la	$a0, space
	syscall

	# print-col loop
	# $t7 -> loop counter (col)
	# $t8 -> board character (ascii)
	move	$t7, $zero

prt_board_loop1_inner:
	slt	$t2, $t7, $s0
	beq	$t2, $zero, prt_board_loop1_inner_done

	lb	$t8, 0($t4)

	la	$a0, grass
	beq	$t8, $t5, prt_board_char	# char is grass?
	la	$a0, tree
	beq	$t8, $t6, prt_board_char	# char is tree?
	la	$a0, tent

prt_board_char:
	li	$v0, PRINT_STRING
	syscall
	la	$a0, space
	syscall

	addi    $t7, $t7, 1     # increment loop counter (row)
        addi    $t4, $t4, 1     # increment row_sums addr
	j	prt_board_loop1_inner

prt_board_loop1_inner_done:
	li	$v0, PRINT_STRING
	la	$a0, bar
	syscall
	#li	$v0, PRINT_STRING
	la	$a0, space
	syscall
	li	$v0, PRINT_INT	# print row-sum
	lw	$a0, 0($t3)
	syscall
	li	$v0, PRINT_STRING
	la	$a0, new_line
	syscall

	addi	$t0, $t0, 1	# increment loop counter (row)
	addi	$t3, $t3, 4	# increment row_sums addr
	j	prt_board_loop1

prt_board_loop1_done:
	jal     print_board_helper

	# print-col-sums loop
	# $t0 -> loop counter
	# $t2 -> bool var/temp (for slt)
	# $t3 -> address of row_sums
	move	$t0, $zero
	la	$t3, col_sums

	li	$v0, PRINT_STRING
	la	$a0, space
	syscall

prt_board_loop2:
	slt	$t2, $t0, $s0
	beq	$t2, $zero, prt_board_loop2_done

	li	$v0, PRINT_STRING
	la	$a0, space
	syscall
	li	$v0, PRINT_INT
	lw	$a0, 0($t3)
	syscall

	addi	$t0, $t0, 1	# increment loop2 counter
	addi	$t3, $t3, 4	# increment col_sums addr
	j	prt_board_loop2

prt_board_loop2_done:
	li      $v0, PRINT_STRING
	la	$a0, new_line
	syscall

	lw	$ra, 4($sp)
	lw	$s0, 0($sp)
	addi	$sp, $sp, 8
	jr      $ra

# 
# Name:         print_board_helper
#
# Description:  print helper: prints the top/bottom edge of board
#
# Arguments:    none
# Returns:      none
#
print_board_helper:
	li	$v0, PRINT_STRING
	la	$a0, plus
	syscall

	# $t0 -> loop counter
	# $t1 -> loop max val
	# $t2 -> bool var
	move	$t0, $zero
	lw	$t1, board_size
	li	$t2, 2
	mul	$t1, $t1, $t2
	addi	$t1, $t1, 1	# loop 2*board_size+1 times

prt_board_helper_loop:
	slt	$t2, $t0, $t1
	beq	$t2, $zero, prt_board_helper_loop_done

	li      $v0, PRINT_STRING
        la      $a0, dash
        syscall

	addi	$t0, $t0, 1
	j	prt_board_helper_loop

prt_board_helper_loop_done:
	li	$v0, PRINT_STRING
	la	$a0, plus
        syscall
	#li	$v0, PRINT_STRING
	la	$a0, new_line
        syscall

	jr      $ra
