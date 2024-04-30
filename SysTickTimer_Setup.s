;****************** SysTickTimer_Setup.s ***************
; Program written by: Dr. D
; Date Created: 4/8/21
; Last Modified: 4/8/21
; Brief description of the program: Code to configure the System Clock
;	
  

 ; ********************************************************************
 ; ********************* EQU Label Definitions ************************
 ; ********************************************************************

; SysTick Timer addresses
NVIC_ST_CTRL_R 		EQU 0xE000E010	; SysTick Control and Status Register (STCTRL)
NVIC_ST_RELOAD_R	EQU 0xE000E014	; SysTick Reload Value register (STRELOAD)
NVIC_ST_CURRENT_R	EQU 0xE000E018	; SysTick Current Value Register (STCURRENT)
;DELAY				EQU 400000		; 400,000 ticks = 5ms at 80MHz


	THUMB
	
		  
; *********************************************************************
; *************************** CODE AREA IN ROM ************************
; *********************************************************************
	AREA    MySysTickConfig, CODE, READONLY, ALIGN=2		; Flash ROM
		    
	ALIGN
		  

	EXPORT	SysTick_Config

SysTick_Config
; Step 1: clear the SysTick enable bit to turn off during initialization
	LDR R1, =NVIC_ST_CTRL_R
	LDR	R0, [R1]
	BIC R0, #1
	STR R0, [R1]
	
; Step 2: reload the counter start value
	LDR R1, =NVIC_ST_RELOAD_R
	LDR R0, =0x00FFFFFF	; maximum reload value 0x00FF.FFFF = 16,777,215
	STR R0, [R1]
	
; Step 3: write to current value register to clear the counter
	LDR R1, =NVIC_ST_CURRENT_R
	MOV R0, #0
	STR R0, [R1]
	
; Step 4: write the desired clock mode (core clock) to the control register
	LDR R1, =NVIC_ST_CTRL_R
	LDR	R0, [R1]
	ORR R0, #0x05	; ENABLE and CLK_SRC bits set
	STR R0, [R1]
	BX 	LR
	
		
	ALIGN      ; make sure the end of this section is aligned
    END        ; end of file