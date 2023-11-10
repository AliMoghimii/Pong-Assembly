title (exe) Graphics System Calls 

.model small 
.stack 64   

;--------------------------------------------------------------  Ali Mogihmi - St.ID : 96243085 
;--------------------------------------------------------------    
;use on DOSBOX for max performance
 
.DATA 
   
   ;----------- Ball Vars 
   
   ball_0x dw 160  ;base position x for ball used to restart
   ball_0y dw 100  ;base position y for ball used to restart
   
   ball_x dw 30 ;x coordinates of ball 
   ball_y dw 30 ;y coordinates of ball
   
   ball_vx dw 4 ;speed x of ball
   ball_vy dw 3 ;speed y of ball
                       
   ball_s dw 5  ;size of ball
   
   ;----------- Pad Vars  
   
   pad_x dw 310 ;x coordinates of pad 
   pad_y dw 30  ;y coordinates of pad
   
   pad_vy dw 7  ;speed y of pad
   
   pad_w dw 5   ;pad width  (cx) (x)
   pad_h dw 20  ;pad height (dx) (y)
   
   ;----------- Game Vars
   
   prev_frame db 0    ;previous frame based on pc time
   random_col db 0fH  ;current colour of ball   
   
   score db 0         ;player score
   temp db 0          ;temp var used for different purposes
  life db 3          
   
   ;----------- Screen Boundries
   
   screen_w dw 320  ;video mode w is 320
   screen_h dw 190  ;video mode h is 200 
                    
   ;variables for all 3 boundries
                    
   bounds1_x dw 10
   bounds1_y dw 27
   bounds1_w dw 293
   bounds1_h dw 3 
   
   bounds2_x dw 10
   bounds2_y dw 27
   bounds2_w dw 3
   bounds2_h dw 163 
   
   bounds3_x dw 10
   bounds3_y dw 190
   bounds3_w dw 293
   bounds3_h dw 3

;-------------------------------  
;-------------------------------  

.CODE
  
;############################################################################################ MAIN 
;main procedure used to call main functions and or to end program 

MAIN PROC FAR  
    
    mov ax , @DATA  
    mov ds , ax
    
    mov ax , 00H ;used to reset LED
    out 199 , ax 
       
    ;---------- CODE
    ;---------- 
    
    call SET_TEXT_MODE  ;used to set initial text (score)
     
    call SET_GRAPHICS_MODE ;used to render initial objects and  
    
    call UPDATE ;our game function
    
    Done:
    
    ;---------- END 
    ;----------
     
    mov ax , 4c00h
    int 21H
          
MAIN ENDP ;Ends program 

;############################################################################################  

;-------------------------------------------------------------------------------------------- UPDATE
;Updates screen frames and object for each frame based on pc time and time elapsed 

UPDATE PROC  
    
  ;get system time which ch = hour , cl = minute , dl = 1/100 seconds  
  
    Loop_Update:
       
        mov ah , 2cH
        int 21H 
        
        cmp dl , prev_frame ;still current frame
        je Loop_Update      ;
        
        mov prev_frame , dl ;update the previous frame variable
         
        ;--------------------------- \/ SECTION TO DO RENDERINGS \/
        
        call SET_GRAPHICS_MODE ;reset and clear screen each frame 
        
        call SET_TEXT_MODE     ;reset and clear texts each frame
        
        call LED               ;display score on LED display 
                               ;(DOSBOX doesnt support this function, use on emu8086)
        
        ;call RENDER_BOUNDS     ;rendering the boundry lines
                               ;(when using DOSBOX disable this proc to reduce jittering)
                               ;emu8086 doesnt support multiple pages so some visual bugs 
                               ;may appear  
           
        call TRANSFORM_BALL    ;move ball and check collisions
        
        call RENDER_BALL       ;render the ball for frame
        
        call TRANSFORM_PAD     ;move pad and check collisions
        
        call RENDER_PAD        ;render the ball for frame
        
        ;--------------------------- /\ SECTION TO DO RENDERINGS /\
        mov al , score 
        cmp ax , 30            ;needs this much score to win 
        jl Loop_Update         ;if above 30 score stop update loop 
         
    call SET_GRAPHICS_MODE     ;clear screen for a final time 
                               ;load ending (Win) message
    mov dl , 'W'
    mov ah , 02H  
    int 21H  
        
    mov dl , 'O'
    mov ah , 02H  
    int 21H 
        
    mov dl , 'N'
    mov ah , 02H  
    int 21H
        
    mov dl , '!'
    mov ah , 02H  
    int 21H  
        
    ret
    
UPDATE ENDP 

;-------------------------------------------------------------------------------------------- RESET
;used to reset ball position (obselete alternate mode for GameOver - refer to TRANSFORM_BALL)

RESET PROC 
    
    mov ax , ball_0x
    mov ball_x , ax 
    
    mov ax , ball_0y
    mov ball_y , ax 
     
    ret 
    
RESET ENDP

;-------------------------------------------------------------------------------------------- VIDEO_MODE
;used to clear screen and set the graphics mode back on - also used to color the bg  

SET_GRAPHICS_MODE PROC

    mov ah , 00H ;set the graphics mode
    mov al , 13H ;video mode is 13H 
    int 10H 
    
    ret  
        
SET_GRAPHICS_MODE ENDP   

;-------------------------------------------------------------------------------------------- TEXT_MODE   
;used to set the text boxes needed for texts in our program

SET_TEXT_MODE PROC

   ;-------------------------------------------------------Set Score Text (top right)
   ;-------------------------------------------------------
    
   mov al, score 
   
   ;aam will do the same as AH = AL / 10 and AL = AL mod 10 
   ;but will leave incorrect unpacked bcd values.
   ;so if our number has double digits like 21 it will be saved as 
   ;AH = 2 and AL = 1 in ascii format 
   
   aam 
    
   ;the codes are in ascii format so we add 48 or 30H to them to find
   ;the coresponding characters
    
   add ah , 48
   add al , 48 
   
   ;we use bx as a temp to store ax
   
   mov bx, ax
   mov dl, bh
    
   mov ah, 02H  
   int 21H    ;int 21H w/ AH 02H prints dl (digit 2 or prev AH in this matter)
   
   mov dl, bl 
   
   mov ah, 02H  
   int 21H    ;int 21H w/ AH 02H prints dl (digit 1 or prev AL in this matter)
   
   ;------------------------------------------------------Alternative ( BROKEN - DONT USE)
   
   ;mov dl , 11
   ;cmp dl , 0AH
   ;jge twoDigit
   
   ;mov dx , 00H
   ;mov dl , 11
   ;add dl , 48  
   ;mov ah , 2H  
   ;int 21H
   
   ;ret  
   
   ;twoDigit:
   
   ;mov dx , 10 ; first we use dx as number 10 in div then we restart it right after div
   ;mov ax , 00H 
   ;mov al , 11
   ; score%10 is in dx (dl) and score/10 is in 
   ;div dx
   ;mov dx , 00H
   ;mov dh , ah 
   ;dh is 2nd Digit , dl is first Digit (right to left : 2nd.1st)
   
   ;mov cl , dl
   ;mov dl , dh
      
   ;add dl , 48  
   ;mov ah , 2H  
   ;int 21H 
   
   ;mov dl , cl
   
   ;add dl , 48  
   ;mov ah , 2H  
   ;int 21H 
        
 
   
   ;-------------------------------------------------------\/ insert other text boxes here \/
   ;------------------------------------------------------- 
   
   ;-------------------------------------------------------
   ;-------------------------------------------------------/\ insert other text boxes here /\
   
   ret 
        
SET_TEXT_MODE ENDP   

;-------------------------------------------------------------------------------------------- SET SINGLE PIXEL 
;this is used just as a demo and test to print a single pixel (ONLY DEBUG)

SET_PIXEL PROC
    
    mov ah , 0cH ;set to draw a pixel 
    mov al , 0fH ;set color of the pixel 
   
    mov cx , ball_x  ;coordinate X of pixel (column)
    mov dx , ball_y  ;coordinate Y of pixel (row) 
    
    int 10H  
    
    ret
    
SET_PIXEL ENDP  

;-------------------------------------------------------------------------------------------- DRAW SQUARE BALL 
;used to draw a square ball with the size of ball_s (refer to ball vars in DATA) (Line 011)

RENDER_BALL PROC 
     
    mov cx , ball_x  ;coordinate X of pixel (column)
    mov dx , ball_y  ;coordinate Y of pixel (row)
    
    ;----------
    loop_Render_Ball: 
          
        mov ah , 0cH ;set to draw a pixel       
        mov al , random_col ;set color of the pixel   
        int 10H 
        
        ;draw horizontal
        
        inc cx ;increase the X coordinate (draw to the right)  
        
        mov ax , cx
        sub ax , ball_x 
        cmp ax , ball_s         ;if cx - ball_x is higher than size stop and switch rows
        jng loop_Render_Ball
   
        ;draw vertical
        
        mov cx , ball_x ;revert to starter column  
        
        inc dx ;increas the row (draw down)
        
        mov ax , dx
        sub ax , ball_y
        cmp ax , ball_s         ;if dx - ball_y is higher than size stop and switch rows 
        jng loop_Render_Ball   

    ret 
      
RENDER_BALL ENDP 

;-------------------------------------------------------------------------------------------- RENDER THE BOUNDRIES
;renders the visual indicator of the walls around the game enviroment
;just a repeat of a single function for 3 times (3 walls)
 
RENDER_BOUNDS PROC 
    
    mov cx , bounds1_x  ;coordinate X of pixel (column)
    mov dx , bounds1_y  ;coordinate Y of pixel (row)
    
    ;----------
    loop_Render_Bound1: 
          
        mov ah , 0cH ;set to draw a pixel 
        mov al , 0fH ;set color of the pixel   
        int 10H 
        
        ;draw horizontal
        inc cx ;increase the X coordinate (draw to the right)  
        
        mov ax , cx
        sub ax , bounds1_x
        cmp ax , bounds1_w
        jng loop_Render_Bound1
         
        ;---------- 
        
        ;draw vertical
        mov cx , bounds1_x ;revert to starter column  
        
        inc dx
        
        mov ax , dx
        sub ax , bounds1_y
        cmp ax , bounds1_h 
        jng loop_Render_Bound1   
    ;----------
    
    mov cx , bounds2_x  ;coordinate X of pixel (column)
    mov dx , bounds2_y  ;coordinate Y of pixel (row)
    
    ;----------
    loop_Render_Bound2: 
          
        mov ah , 0cH ;set to draw a pixel 
        mov al , 0fH ;set color of the pixel   
        int 10H 
        
        ;draw horizontal
        inc cx ;increase the X coordinate (draw to the right)  
        
        mov ax , cx
        sub ax , bounds2_x
        cmp ax , bounds2_w 
        jng loop_Render_Bound2
         
        ;---------- 
        
        ;draw vertical
        mov cx , bounds2_x ;revert to starter column  
        
        inc dx
        
        mov ax , dx
        sub ax , bounds2_y
        cmp ax , bounds2_h  
        jng loop_Render_Bound2   
    ;----------  
    
    mov cx , bounds3_x  ;coordinate X of pixel (column)
    mov dx , bounds3_y  ;coordinate Y of pixel (row)
    
    ;----------
    loop_Render_Bound3: 
          
        mov ah , 0cH ;set to draw a pixel 
        mov al , 0fH ;set color of the pixel   
        int 10H 
        
        ;draw horizontal
        inc cx ;increase the X coordinate (draw to the right)  
        
        mov ax , cx
        sub ax , bounds3_x
        cmp ax , bounds3_w 
        jng loop_Render_Bound3
         
        ;---------- 
        
        ;draw vertical
        mov cx , bounds3_x ;revert to starter column  
        
        inc dx
        
        mov ax , dx
        sub ax , bounds3_y
        cmp ax , bounds3_h  
        jng loop_Render_Bound3
    
    ret 
      
RENDER_BOUNDS ENDP 

;-------------------------------------------------------------------------------------------- RENDER PAD
;used to render the pad which is used to bounce the ball

RENDER_PAD PROC 
    
    mov cx , pad_x  ;coordinate X of pixel (column)
    mov dx , pad_y  ;coordinate Y of pixel (row)
    
    ;----------
    loop_Render_Pad: 
          
        mov ah , 0cH ;set to draw a pixel 
        mov al , 01H ;set color of the pixel   
        int 10H 
        
        ;draw horizontal
        inc cx ;increase the X coordinate (draw to the right)  
        
        mov ax , cx
        sub ax , pad_x 
        cmp ax , pad_w ;if cx - padx is higher than the pad width stop and switch rows
        jng loop_Render_Pad
         
        ;---------- 
        
        ;draw vertical
        mov cx , pad_x ;revert to starter column  
        
        inc dx
        
        mov ax , dx
        sub ax , pad_y
        cmp ax , pad_h ;if dx - pady is higher than the pad height stop and switch rows 
        jng loop_Render_Pad   

    
    ret 
      
RENDER_PAD ENDP     

;-------------------------------------------------------------------------------------------- MOVE BALL & COLLISIONS

TRANSFORM_BALL PROC
    
    mov ax , ball_vx ;add the x speed to the ball (neg or pos)
    add ball_x , ax 
    
   ;------------------------------------------------check collision with borders
   ;------------------------------------------------
    
    ;ball_x < 0 therefore collides with 0,Y (going left)  
    
    cmp ball_x , 12
    jl Neg_x 
    
    ;ball_x > screen_w therefore collides with screen_w,Y (going right) 
    
    mov ax , screen_w 
    sub ax , ball_s
    cmp ball_x , ax
    jg Reset_pos
    ;jg GameOver    
    
   ;---------------- 
   
    mov ax , ball_vy ;add the y speed to the ball (neg or pos)
    add ball_y , ax  

    ;ball_y < 0 therefore collides with X,0 (going up) 
    
    cmp ball_y , 27
    jl Neg_y 
    

    ;ball_y > screen_h therefore collides with X,screen_h (going down)  
     
    mov ax , screen_h
    sub ax , ball_s
    cmp ball_y , ax
    jg Neg_y  

   ;------------------------------------------------check collisions with pad
   ;------------------------------------------------ 
   ;AABB rule sudo-code : 
   ;ball_x + ball_s > pad_x && ball_x < pad_x + pad_w && ball_y + ball_s > pad_y && ball_y < pad_y + pad_h
    
    mov ax , ball_x
    add ax , ball_s
    cmp ax, pad_x
    jng No_Collision
    
    ;------------- 
    
    mov ax , pad_x
    add ax , pad_w
    cmp ball_x , ax
    jnl No_Collision
    
    ;-------------
    
    mov ax , ball_y
    add ax , ball_s
    cmp ax , pad_y 
    jng No_Collision
    
    ;-------------
    
    mov ax , pad_y
    add ax , pad_h
    cmp ball_y , ax 
    jnl No_Collision
    
    ;-------------
    
    add score , 1
    jmp Neg_x  
    
    ;---------------
    
    No_Collision: ;if one of the ifs above is false  then we quit the proc
        ret    
         
   ;----------------   
     GameOver:    ;if ball crosses right side boundry
     
        call SET_GRAPHICS_MODE 
     
        mov dl , 'G'
        mov ah , 2H  
        int 21H  
        
        mov dl , 'A'
        mov ah , 2H  
        int 21H 
        
        mov dl , 'M'
        mov ah , 2H  
        int 21H
        
        mov dl , 'E'
        mov ah , 2H  
        int 21H
        
        mov dl , ' '
        mov ah , 2H  
        int 21H  
        
        mov dl , 'O'
        mov ah , 2H  
        int 21H 
        
        mov dl , 'V'
        mov ah , 2H  
        int 21H
        
        mov dl , 'E'
        mov ah , 2H  
        int 21H 
        
        mov dl , 'R'
        mov ah , 2H  
        int 21H
        
        jmp Done:
   
   ;each bounce calls random color set
        
   ;---------------- ;Alternative for GameOver (with implementing life system)
    Reset_pos:
        call RANDOM 
        call RESET 
        
       sub life , 1
       cmp life , 0
        je GameOver 
        
        ret
   ;---------------- ;used to multiply the x speed of the ball by -1    
    Neg_x:
        call RANDOM 
        neg ball_vx 
        ret
   ;---------------  ;used to multiply the y speed of the ball by -1 
    Neg_y: 
        call RANDOM 
        neg ball_vy 
        ret
   ;---------------  
    
TRANSFORM_BALL ENDP 
 
;-------------------------------------------------------------------------------------------- MOVE PAD & COLLISIONS

TRANSFORM_PAD PROC 
     
     ;check if key is being pressed
     mov ah , 01H 
     int 16H 
     jz No_key ;if no key is being pressed we return the proc
        
    ;----------
     
     ;check the specific key  
     mov ah , 00H
     int 16H 

     cmp al , 'w' ;when the key is euqal to w
     je MoveUp_pad
     cmp al , 'W' ;when the key is euqal to W
     je MoveUp_pad  
     
     cmp al , 's' ;when the key is euqal to s
     je MoveDown_pad
     cmp al , 'S' ;when the key is euqal to S
     je MoveDown_pad 
     
     ;---------- 
       
     MoveUp_pad: ;move pad up if W is pressed
     
         mov ax , pad_vy
         sub pad_y , ax
         
         cmp pad_y , 27    ;if the pad reached the upper limit
         jl DontMoveUp_Pad
         
         ret 
         
     DontMoveUp_Pad:       ;dont allow pad to move further upwards
     
         mov pad_y , 27  
         
         ret    
     
     ;---------- 
     
     MoveDown_pad: ;move pad down if S is pressed
     
         mov ax , pad_vy
         add pad_y , ax
         
         mov ax , screen_h 
         sub ax , pad_h
         cmp pad_y , ax       ;if the pad reached the bottom limit
         jg DontMoveDown_Pad
         
         ret 
         
     DontMoveDown_Pad:        ;dont allow pad to move further downwards
     
         mov ax , screen_h 
         sub ax , pad_h
         mov pad_y , ax 
         
         ret      
         
     ;---------- 
     
     No_Key: 
       
         ret
     
TRANSFORM_PAD ENDP
    
ret 

;-------------------------------------------------------------------------------------------- LED Display : just for test 

LED PROC
    
   #start=led_display.exe#  ;boot up LED display
   
   mov al, score
   mov ah , 00H
   out 199, ax ;print out score on LED
   
   ret 
     
LED ENDP     

;-------------------------------------------------------------------------------------------- RANDOM BETWEEN 0 and 9 SOURCE : STACKOVERFLOW

RANDOM PROC
    
   mov ah, 00H  ; interrupts to get system time        
   int 1aH      ; CX:DX now hold number of clock ticks since midnight      

   mov ax , dx
   xor dx , dx
   mov cx , 10    
   div cx       ; here dx contains the remainder of the division - from 0 to 9

   add dl , 01H
   mov random_col , dl 
      
   ret 
     
RANDOM ENDP



;-------------------------------------------------------------------------------------------- Unused Lines
;include in main for single pixles ;call SET_PIXEL 