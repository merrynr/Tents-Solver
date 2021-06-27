# Tents & Trees Solver

Program to solve tents puzzles algorithmically through backtracking. 

#### Editor Note: The purpose of this project was to get more familiar with MIPS assembly. I originally completed it on RIT's lab machines since it already had the MIPS build + sim environment and libraries configured. Afterwards, it was saved in google drive at https://drive.google.com/drive/folders/1TllzOl0YzP_ZPtVYa6mAyImN91i3Sjqa, before being imported here. 

## Game Rules

In general, the rules of a tents and trees puzzle are:
1. Each tree has exactly one tent attached to it.
2. Each tent is attached to one tree (so there are as many tents as there are trees).
3. The numbers across the bottom and down the side tell you how many tents are in the respective column or row.
4. A tent can only be placed horizontally or vertically adjacent to a tree.
5. Tents are never adjacent to each other, neither vertically, horizontally, nor diagonally.
6. A tree might be next to two tents, but is only connected to one.

## Prerequisites

- MIPS
- gmakemake
- rsim (unless running natively)


## Compiling
run the command `make`


## Running
With rsim:
1. Find your rsim directory and run `tents.out`. For example, `/home/fac/wrc/bin/rsim tents.out`
2. Type in your tents and trees puzzle as follows:
	line 1: the number of rows and columns
	lines 2 and 3: the number of tents that should be in each row and column respectively
	line 4+: the initial puzzle, representing trees as 'T' and free aquares as '.'
	See included test files for examples. 

Note: There is a maximum limit to solvable puzzle size, due to program reserved memory space.
The final puzzle should be outputted with 'A's where the tents should go if puzzle is ok.

## Test Files Intended Output:
test4 = invalid puzzle
test5 = impossible puzzle
test12 = 
+-------------------------+
| . . . T . . . . A T T A | 2
| T A . A . T A . . . . . | 3
| T . . . . . . . T A T A | 2
| A . . T A . . . T . . . | 2
| . . . T . . . . A . . . | 1
| T A . A . A . . . . . A | 4
| . . . . . T T A . A T T | 2
| . A T . A . T . . . . A | 3
| . . T . T . A . . A . T | 2
| . . A . . . . T . T . T | 1
| . . . . T A . A . . . A | 3
| A T A T . . . . . A T . | 3
+-------------------------+
  2 3 2 2 2 2 2 2 2 4 0 5