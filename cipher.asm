#Ece Goksu
#261138642

.data
 
command_list: .asciiz "Commands (encrypt, decrypt, quit): "
encrypt_command: .asciiz "Enter text to encrypt (upper case letters only): "
encrypted_text_display: .asciiz "Encrypted text: "
decrypt_command: .asciiz "Enter text to decrypt (upper case letters only): "
decrypted_text_display: .asciiz "Decrypted text: "
shift_key: .asciiz "Enter key (upper case letters only): " 
newline: .asciiz "\n"
text_buffer: .space 100        
key_buffer: .space 20           

.text

main:
    #Display command list
    la $a0, command_list
    li $v0, 4
    syscall

    #Read input
    li $v0, 12
    syscall
    move $t0, $v0
    
    la $a0, newline
    li $v0, 4
    syscall

    #Display command menu
    beq $t0, 'e', encrypt_menu   
    beq $t0, 'd', decrypt_menu   
    beq $t0, 'q', exit_program   
    j main

# Option A: Encrypt
encrypt_menu:
    #Get the text to encrypt
    la $a0, encrypt_command
    li $v0, 4
    syscall

    #Read the text to encrypt
    li $v0, 8
    la $a0, text_buffer
    li $a1, 100
    syscall

    #Get the shift key 
    la $a0, shift_key
    li $v0, 4
    syscall

    #Read the shift key
    li $v0, 8
    la $a0, key_buffer
    li $a1, 20
    syscall

    #Set $a0 to text_buffer and $a1 to key_buffer 
    la $a0, text_buffer        
    la $a1, key_buffer         
    jal Encryptext             

    #Display encrypted text
    la $a0, encrypted_text_display
    li $v0, 4
    syscall

    la $a0, text_buffer
    li $v0, 4
    syscall
    
    j main        

# Option B: Decrypt
decrypt_menu:
    #Get the text to decrypt
    la $a0, decrypt_command
    li $v0, 4
    syscall
    
    #Read the text to decrypt
    li $v0, 8                    
    la $a0, text_buffer
    li $a1, 100
    syscall
    
    # Get the shift key 
    la $a0, shift_key
    li $v0, 4
    syscall
    
    # Read the shift key
    li $v0, 8
    la $a0, key_buffer
    li $a1, 20
    syscall
    
    #Go to function implementation
    la $a0, text_buffer        
    la $a1, key_buffer         
    jal Decryptext            
    
    #Display decrypted text
    la $a0, decrypted_text_display
    li $v0, 4
    syscall
    
    la $a0, text_buffer          
    li $v0, 4
    syscall
    
    j main  

#Option D: Exit    
exit_program:
    li $v0, 10 
    syscall

#Encryptext logic implementation
Encryptext:
    #Point $t1 to text_buffer, $t2 to key_buffer
    move $t1, $a0 
    move $t2, $a1          
    
encrypt_loop:   
    #Load char in text_buffer until null terminator
    lb $t3, 0($t1)           
    beq $t3, 0, encrypt_end 

    #ASCII range for 'A' to 'Z'
    li $t4, 65              
    li $t5, 90               
    
    #Load key character and check for null terminator
    lb $t6, 0($t2)           
    beq $t6, 0, restart_key     
    beq $t6, 10, restart_key    

    #Calculate shift amount for the key
    sub $t6, $t6, $t4        

    #Leave nonletters as they are
    blt $t3, $t4, store_nonletter 
    bgt $t3, $t5, store_nonletter 
    
    #Apply shift to letters
    sub $t3, $t3, $t4        
    add $t3, $t3, $t6        

    #Wrap the char if necessary
    li $t7, 26               
    bge $t3, $t7, wrap 

    #Convert back to ASCII 
    add $t3, $t3, $t4        
    sb $t3, 0($t1)           

    j next_key_char            

#Store nonletter characters as they are
store_nonletter:
    sb $t3, 0($t1)           
    j next_key_char            

#Move to the next key character and wrap if necessary
next_key_char:
    addi $t2, $t2, 1         
    lb $t6, 0($t2)           
    bnez $t6, next_char      
    move $t2, $a1            

#Move to the next character in text_buffer	
next_char:
    addi $t1, $t1, 1         
    j encrypt_loop

#Wrap around by 26
wrap:
    sub $t3, $t3, $t7        
    add $t3, $t3, $t4        
    sb $t3, 0($t1)           
    j next_key_char            

#Reset key pointer if null terminator reached
restart_key:
    move $t2, $a1            
    j encrypt_loop           

#Return to caller
encrypt_end:
    jr $ra                   

#Decryptext logic implementation
Decryptext:

    #Point $t1 to text_buffer, $t2 to key_buffer
    move $t1, $a0 
    move $t2, $a1          
    
decrypt_loop:   

    #Load current char in text_buffer until null terminator
    lb $t3, 0($t1)           
    beq $t3, 0, decrypt_done 

    #ASCII range for 'A' to 'Z'
    li $t4, 65               
    li $t5, 90               
    
    #Load key character and check for null terminator
    lb $t6, 0($t2)           
    beq $t6, 0, restart_key_dec  
    beq $t6, 10, restart_key_dec 

    #Calculate negative shift amount for the key
    sub $t6, $t6, $t4       

    #Leave nonletters as they are
    blt $t3, $t4, store_nonletter_dec 
    bgt $t3, $t5, store_nonletter_dec
    
    #Apply negative shift to letters
    sub $t3, $t3, $t4        
    sub $t3, $t3, $t6        

    #Wrap the char if necessary 
    bltz $t3, wrap_negative  

    #Convert back to ASCII 
    add $t3, $t3, $t4        
    sb $t3, 0($t1)           

    j next_key_char_dec            

#Directly store nonletter characters as they are
store_nonletter_dec:
    sb $t3, 0($t1)           
    j next_key_char_dec            

#Move to the next key character and wrap if necessary
next_key_char_dec:
    addi $t2, $t2, 1        
    lb $t6, 0($t2)           
    bnez $t6, next_char_dec      
    move $t2, $a1           

#Move to the next character in text_buffer	
next_char_dec:
    addi $t1, $t1, 1         
    j decrypt_loop

#Wrap around if negative by adding 26
wrap_negative:
    addi $t3, $t3, 26        
    add $t3, $t3, $t4        
    sb $t3, 0($t1)           
    j next_key_char_dec            

#Reset key pointer if null terminator reached
restart_key_dec:
    move $t2, $a1            
    j decrypt_loop           

#Return to caller
decrypt_done:
    jr $ra  
