;****************** main.s ***************
; Brief description of the program:

; 		PF0	-->	SW2
;		PF1	-->	Red LED
;		PF2	-->	Blue LED
;		PF3	--> Green LED
;		PF4	--> SW1


	THUMB
		
; Base address for Port F Data Register = 0x4002.5000

; *********************************************************************
; ************************* EQU DIRECTIVES ****************************
; *********************************************************************

; Port E Data registers
GPIO_PORTE_DATA_R  	EQU 0x400243FC	; to read/write all bits on Port E
GPIO_PORTE_DATA_OUT	EQU	0x40024004	; Port E output bit(s)

; Port F Data registers
GPIO_PORTF_DATA_R  	EQU 0x400253FC	; to read all bits on Port F
GPIO_PORTF_DATA_SWS	EQU	0x40025044	; to read both switches on Port F, bits 0 & 4
GPIO_PORTF_DATA_OUT	EQU	0x40025038	; Port F data bits 1-3
	
; SysTick Timer addresses
NVIC_ST_CTRL_R 		EQU 0xE000E010	; SysTick Control and Status Register (STCTRL)
NVIC_ST_RELOAD_R	EQU 0xE000E014	; SysTick Reload Value register (STRELOAD)
NVIC_ST_CURRENT_R	EQU 0xE000E018	; SysTick Current Value Register (STCURRENT)

; Define frequencies for each note
FS7_FREQ    EQU 12800
C7_FREQ     EQU 18400
C8_FREQ     EQU 8800
B6_FREQ     EQU 20000
A6_FREQ     EQU 22727
	
; Define note durations for each tone
FS7_LEN    EQU 200
C7_LEN     EQU 2500
C8_LEN     EQU 4186
B6_LEN     EQU 1976
A6_LEN     EQU 1760

; Define LED masks for each note
FS7_LED     EQU 2_00010  ; Red LED
C7_LED      EQU 2_00100  ; Blue LED
C8_LED      EQU 2_01000  ; Green LED
B6_LED      EQU 2_00100  ; Blue LED
A6_LED      EQU 2_00010  ; Red LED
	  
; *********************************************************************
; ************************* ROM CONSTANTS AREA ************************
; *********************************************************************
; Constants and code area starts at address 0x0000.0000
	AREA    MyConstants, DATA, READONLY, ALIGN=2		; Flash EEPROM

		 
		 
; *********************************************************************
; ************************* RAM VARIABLES AREA ************************
; *********************************************************************
; SRAM variables area starts at address 0x2000.0000
	AREA    MyVariables, DATA, READWRITE, ALIGN=2		; SRAM

; *********************************************************************
; *************************** CODE AREA IN ROM ************************
; *********************************************************************
	AREA    |.text|, CODE, READONLY, ALIGN=2		; Flash ROM


	EXPORT  Start
	IMPORT	SysClock80MHz_Config
	IMPORT	SysTick_Config
	IMPORT	SysTick_Wait
	IMPORT	PortF_Config
	IMPORT	PortE_Config
		



; MAIN PROGRAM ****************************
;	Port F has 5 pins.
; 		PF0	-->	SW2
;		PF1	-->	Red LED
;		PF2	-->	Blue LED
;		PF3	--> Green LED
;		PF4	--> SW1

;The alarm:
;Connect the buzzer to port E0
;FS7 - C7 alternates for 3 seconds
;B6-A6 to C8 alternating at a faster rate


;FS7 2960 (RED) --> 0.00016891891 / 12.5 ns = 12800
;C7 2093 (BLUE) --> 0.00023889154 / 12.5 ns = 18400

;C8 4186 (RED) --> 0.00011944577 / 12.5 ns = 8800
;B6 1976 (GREEN) --> 0.00025303643 / 12.5 ns = 20000
;A6 1760 (BLUE) -->  0.0002840909 / 12.5 ns = 22727.272
		
Start
	BL	SysClock80MHz_Config
	BL	SysTick_Config
	BL	PortE_Config
	BL	PortF_Config
	
loop
;*********** Check SW2 **************
check_SW2
	; read switch values
	LDR	R1, =GPIO_PORTF_DATA_SWS		
	LDR	R0, [R1]						
	
	; check SW2
	LSRS R0, #1
	BCS.W	continue_loop
	
	; play tune*************************
	; Play FS7
	MOV R7, #FS7_LEN          ; Set amount of time to play tone
	BL play_FS7
	
	; Play C7
	MOV R7, #C7_LEN          ; Set amount of time to play tone
	BL play_C7
	
	

play_FS7	
    PUSH {LR}

	; Turn on the LED corresponding to the played tone
    LDR R1, =GPIO_PORTF_DATA_OUT      ; Load address of Port F LEDs
    MOV R6, #FS7_LED					; set LED for FS7
	STR R6, [R1]
	
	; sound wave goes HI
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #1
	STR	R0, [R1]
	; run SysTick timer
	MOV R0, #FS7_FREQ		; Set frequency
	BL	SysTick_Wait
	
	; sound wave goes LO
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #0
	STR	R0, [R1]	
	; run SysTick timer
	MOV R0, #FS7_FREQ		; Set frequency
	BL	SysTick_Wait
	
	SUBS R7, #1
	BNE	play_FS7
	
	LDR R1, =GPIO_PORTF_DATA_OUT      ; Load address of Port F LEDs
    MOV R6, #2_00000                    ; Clear LED
	STR R6, [R1]
	
	POP {PC}
	BX LR
	
play_C7	
	; Turn on the LED corresponding to the played tone
    LDR R1, =GPIO_PORTF_DATA_OUT      
    MOV R6, #C7_LED					
	STR R6, [R1]
	
	; sound wave goes HI
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #1
	STR	R0, [R1]
	; run SysTick timer
	MOV R0, #C7_FREQ		; Set frequency
	BL	SysTick_Wait
	
	; sound wave goes LO
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #0
	STR	R0, [R1]	
	; run SysTick timer
	MOV R0, #C7_FREQ		; Set frequency
	BL	SysTick_Wait
	
	SUBS R7, #1
	BNE	play_C7
	
	LDR R1, =GPIO_PORTF_DATA_OUT   
    MOV R6, #2_00000                    ; Clear LED
	STR R6, [R1]
	
	BX LR
	
play_C8
	; Turn on the LED corresponding to the played tone
    LDR R1, =GPIO_PORTF_DATA_OUT      
    MOV R6, #C8_LED					
	STR R6, [R1]
	
	; sound wave goes HI
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #1
	STR	R0, [R1]
	; run SysTick timer
	MOV R0, #C8_FREQ		; Set frequency
	BL	SysTick_Wait
	
	; sound wave goes LO
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #0
	STR	R0, [R1]	
	; run SysTick timer
	MOV R0, #C8_FREQ		; Set frequency
	BL	SysTick_Wait
	
	SUBS R7, #1
	BNE	play_C8
	
	LDR R1, =GPIO_PORTF_DATA_OUT   
    MOV R6, #2_00000                    ; Clear LED
	STR R6, [R1]
	
	BX LR
	
play_B6
	; Turn on the LED corresponding to the played tone
    LDR R1, =GPIO_PORTF_DATA_OUT      
    MOV R6, #B6_LED					
	STR R6, [R1]
	
	; sound wave goes HI
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #1
	STR	R0, [R1]
	; run SysTick timer
	MOV R0, #B6_FREQ		; Set frequency
	BL	SysTick_Wait
	
	; sound wave goes LO
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #0
	STR	R0, [R1]	
	; run SysTick timer
	MOV R0, #B6_FREQ		; Set frequency
	BL	SysTick_Wait
	
	SUBS R7, #1
	BNE	play_B6
	
	LDR R1, =GPIO_PORTF_DATA_OUT   
    MOV R6, #2_00000                    ; Clear LED
	STR R6, [R1]
	
	BX LR
	
play_A6
	; Turn on the LED corresponding to the played tone
    LDR R1, =GPIO_PORTF_DATA_OUT      
    MOV R6, #A6_LED					
	STR R6, [R1]
	
	; sound wave goes HI
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #1
	STR	R0, [R1]
	; run SysTick timer
	MOV R0, #A6_FREQ		; Set frequency
	BL	SysTick_Wait
	
	; sound wave goes LO
	LDR	R1, =GPIO_PORTE_DATA_OUT
	MOV	R0, #0
	STR	R0, [R1]	
	; run SysTick timer
	MOV R0, #A6_FREQ		; Set frequency
	BL	SysTick_Wait
	
	SUBS R7, #1
	BNE	play_A6
	
	LDR R1, =GPIO_PORTF_DATA_OUT   
    MOV R6, #2_00000                    ; Clear LED
	STR R6, [R1]
	
	BX LR
	
continue_loop
    ; Continue looping
    B loop




	NOP

	ALIGN        ; make sure the end of this section is aligned
	END          ; end of file