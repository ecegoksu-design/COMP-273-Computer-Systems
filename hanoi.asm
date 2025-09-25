############ COMP 273, Fall 2024, Assignment 4, Tower of Hanoi ###########
# Student ID: 261138642
# Name: Ece Goksu

.data
AlgorithmType:  .word 0    # Which Algorithm to run!
			   # 0 Recursive
			   # 1 Non-recursive
			   
StepString:     .asciiz "Step "
StepNumber:   .word 1
MoveDiskString: .asciiz ": move disk "
FromString:     .asciiz " from "
ToString:       .asciiz " to "
NewLine:        .asciiz "\n"

.align 2
StackA: .space 80
.align 2
StackB: .space 80
.align 2
StackC: .space 80


.text
# There are some helper functions for IO at the end of this file, which might be helpful for you.
# Feel free to write additional functions as necessary to the TO DO block just before the helper functions.

main:
    # read the integer n from the standard input
    jal readInt
    
    # now $v0 contains the number of disk n
    # pass disk number into $a0
    move $a0, $v0          

    # check for which algorithm is set to use: Recursive or non-recursive.
    la $t0, AlgorithmType
    lw $t0, ($t0)
    beq $t0, 0 TOH_Recursive   
    beq $t0, 1 TOH_Nonrecursive 
    li $v0, 10                 # exit if the algorithm number is out of range
    syscall

TOH_Recursive:
# Use a recursive algorithm described in the assignment document to print the solution steps. Make sure you follow the output format.
# Set the first breakpoint to measure cache performance and instruction count for the recursive method at the first instruction of this label

    # Source rod 
    li $a1, 65  
    # Auxiliary rod      
    li $a2, 66 
    # Target rod        
    li $a3, 67         

    # Call recursive implementation
    jal RecursiveImplementation

    # Set the second breakpoint to measure cache performance and instruction count for the recursive method at the following line

    # exit the program
    li $v0, 10
    syscall

RecursiveImplementation:
    # Allocate space on stack
    addi $sp, $sp, -24
    
    # Push ragisters on stack
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $a0, 20($sp)

    # Copy n to $s0
    add $s0, $a0, $zero 
    # Copy source rod to $s1     
    add $s1, $a1, $zero 
    # Copy auxilary rod to $s2      
    add $s2, $a2, $zero   
    # Copy target rod to $s2  
    add $s3, $a3, $zero      

    # Base case: n == 1
    li $t1, 1
    beq $s0, $t1, BaseCase  

    # n = n - 1
    addi $a0, $s0, -1        
    move $a1, $s1    
    # Aux = Target        
    move $a2, $s3            
    # Target = Aux
    move $a3, $s2
    # Move n - 1 from source to aux   
    jal RecursiveImplementation  
    
    # Print n'th disk move from source to target
    lw $a0, 20($sp)  
    move $a1, $s1    
    move $a2, $s3    
    jal printMove    
    
    # Move n-1 disks from aux to target
    # n = n = 1
    addi $a0, $s0, -1    
    # Aux = Source    
    move $a1, $s2            
    # Source = Aux
    move $a2, $s1            
    move $a3, $s3            
    jal RecursiveImplementation 
    
    # Pop registers from stack
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $a0, 20($sp)
    
    addi $sp, $sp, 24        
    jr $ra      
    
BaseCase:
    # Base case: Move a single disk from A to C
    move $a0, $s0     
    move $a1, $s1     
    move $a2, $s3     
    jal printMove     

    # Pop registers from stack
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $a0, 20($sp)  

    addi $sp, $sp, 24        
    jr $ra                         
    
TOH_Nonrecursive:
    la $a1, StackA    
    la $a2, StackB    
    la $a3, StackC    
    
    # Initialize rod A with disks
    li $t5, 20              
InitializeDisks:
    # Save disk on rod A, adjust pointer, decrease disk number 
    sw $t5, 0($a1)         
    addi $a1, $a1, 4       
    addi $t5, $t5, -1      
    # Keep adding disks until n = 15 (20 for safety)
    bgtz $t5, InitializeDisks
    addi $a1, $a1, -4  
        
    li $t6, 65             
    li $t7, 66             
    li $t8, 67             
   
     # Determine if n is even 
    andi $t5, $a0, 1       
    beqz $t5, SwapRods 
        
InitializeMoves:
    # Initialize step number required with 1
    li $t9, 1      
    # Move n into $t0        
    move $t0, $a0          
    
CalculateMoves:
    # Shift left for 2^n
    sll $t9, $t9, 1        
    # n = n - 1  
    addi $t0, $t0, -1
    # Do while n != 0
    bgtz $t0, CalculateMoves
    # 2^n - 1
    addi $t9, $t9, -1      
   
     # Initialize step counter
    li $t0, 1
    j MainLoop  
               
SwapRods:
    # Swap B and C
    move $t4, $a2          
    move $a2, $a3          
    move $a3, $t4          
    j InitializeMoves 
         
MainLoop:
    # Exit when current step == n
    bgt $t0, $t9, Exit     

    # Mod 3
    rem $t1, $t0, 3        
    beq $t1, 1, Remainder1
    beq $t1, 2, Remainder2
    j Remainder3

# Move between Source and Target
Remainder1:  
    lw $t2, 0($a1)         
    lw $t3, 0($a3)         
    beqz $t2, TargettoSource
    beqz $t3, SourcetoTarget
    blt $t2, $t3, SourcetoTarget
    j TargettoSource

# Move between Source and Aux
Remainder2:  
    lw $t2, 0($a1)         
    lw $t3, 0($a2)         
    beqz $t2, AuxtoSource
    beqz $t3, SourcetoAux
    blt $t2, $t3, SourcetoAux
    j AuxtoSource

# Move between Aux and Target
Remainder3:  
    lw $t2, 0($a2)         
    lw $t3, 0($a3)         
    beqz $t2, TargettoAux
    beqz $t3, AuxtoTarget
    blt $t2, $t3, AuxtoTarget
    j TargettoAux

SourcetoTarget:
    lw $t4, 0($a1)         
    sw $zero, 0($a1)       
    addi $a1, $a1, -4      
    addi $a3, $a3, 4       
    sw $t4, 0($a3)         
    li $t6, 65             
    li $t7, 67             
    j PrintNonrecursive

TargettoSource:
    lw $t4, 0($a3)
    sw $zero, 0($a3)
    addi $a3, $a3, -4
    addi $a1, $a1, 4
    sw $t4, 0($a1)
    li $t6, 67
    li $t7, 65
    j PrintNonrecursive

SourcetoAux:
    lw $t4, 0($a1)
    sw $zero, 0($a1)
    addi $a1, $a1, -4
    addi $a2, $a2, 4
    sw $t4, 0($a2)
    li $t6, 65
    li $t7, 66
    j PrintNonrecursive

AuxtoSource:
    lw $t4, 0($a2)
    sw $zero, 0($a2)
    addi $a2, $a2, -4
    addi $a1, $a1, 4
    sw $t4, 0($a1)
    li $t6, 66
    li $t7, 65
    j PrintNonrecursive

AuxtoTarget:
    lw $t4, 0($a2)
    sw $zero, 0($a2)
    addi $a2, $a2, -4
    addi $a3, $a3, 4
    sw $t4, 0($a3)
    li $t6, 66
    li $t7, 67
    j PrintNonrecursive

TargettoAux:
    lw $t4, 0($a3)
    sw $zero, 0($a3)
    addi $a3, $a3, -4
    addi $a2, $a2, 4
    sw $t4, 0($a2)
    li $t6, 67
    li $t7, 66
    j PrintNonrecursive

    # Set the second breakpoint to measure cache performance and instruction count for the non-recursive method at the following line

Exit:
    li $v0, 10          # exit program
    syscall
    
########### Helper Functions ###########
printMove: 

    # Print Step
    li $v0, 4
    la $a0, StepString
    syscall                  

    # Print step number
    lw $t2, StepNumber
    move $a0, $t2
    li $v0, 1
    syscall                 

    # Increment step number
    addi $t2, $t2, 1
    sw $t2, StepNumber

    # Print move disk
    la $a0, MoveDiskString
    li $v0, 4
    syscall

    # Print disk number
    lw $a0, 20($sp)  
    li $v0, 1
    syscall

    # Print from
    la $a0, FromString
    li $v0, 4
    syscall

    # Print source rod
    move $a0, $s1
    li $v0, 11
    syscall

    # Print to
    la $a0, ToString
    li $v0, 4
    syscall

    # Print target rod
    move $a0, $s3
    li $v0, 11
    syscall

    # Print newline
    la $a0, NewLine
    li $v0, 4
    syscall     
       
    jr $ra   
    
PrintNonrecursive:
    # Print Step
    li $v0, 4
    la $a0, StepString
    syscall

    # Print step number
    lw $a0, StepNumber
    li $v0, 1
    syscall

    # Increment step number
    addi $a0, $a0, 1
    sw $a0, StepNumber

    # Print move disk
    li $v0, 4
    la $a0, MoveDiskString
    syscall
    
    # Print disk number
    move $a0, $t4          
    li $v0, 1
    syscall

    # Print from
    li $v0, 4
    la $a0, FromString
    syscall

    # Print source rod
    move $a0, $t6          
    li $v0, 11
    syscall

    # Print to
    li $v0, 4
    la $a0, ToString
    syscall

    # Print target rod
    move $a0, $t7          
    li $v0, 11
    syscall

    # Print newline
    li $v0, 4
    la $a0, NewLine
    syscall

    # Increment current step 
    addi $t0, $t0, 1
    j MainLoop
    
# read an integer
# int readInt()
readInt:
    li $v0, 5
    syscall
    jr $ra

# print an integer
# printInt(int n)
printInt:
    li $v0, 1
    syscall
    jr $ra

# print a character
# printChar(char c)
printChar:
    li $v0, 11
    syscall
    jr $ra

# print a null-ended string
# printStr(char *s)
printStr:
    li $v0, 4
    syscall
    jr $ra
