;****************** main.s ***************
; Program written by: Dr. D
; Date Created: 4/8/21
; Last Modified: 4/8/21
; Brief description of the program: Code to configure the System Clock
;	
  

 ; ********************************************************************
 ; ********************* EQU Label Definitions ************************
 ; ********************************************************************

; System Clock registers
SYSCTL_RIS_R	EQU	0x400FE050
SYSCTL_RCC_R	EQU	0x400FE060
SYSCTL_RCC2_R	EQU	0x400FE070
SYSDIV2			EQU	4	; this is actually SYSDIV2 + SYSDIV2LSB, 
						; see Table 5-6, p.224 of documentation

	THUMB
	
		  
; *********************************************************************
; *************************** CODE AREA IN ROM ************************
; *********************************************************************
	AREA    MySysClockConfig, CODE, READONLY, ALIGN=2		; Flash ROM
		    
	ALIGN
		  

	EXPORT	SysClock80MHz_Config

SysClock80MHz_Config

; System Clock Initialization
;	R0 --> RCC register data
;	R1 --> RCC register address
;	R2 --> RCC2 register data
;	R3 --> RCC2 register address
; step 0: configure system to use RCC2
	LDR	R3, =SYSCTL_RCC2_R
	LDR	R2, [R3]
	ORR	R2, R2, #0x80000000		; set USERCC2 bit
	STR R2, [R3]
; step 1: bypass PLL while initializing
	LDR	R3, =SYSCTL_RCC2_R
	LDR	R2, [R3]	
	ORR	R2, R2, #0x00000800		; set BYPASS2, which overrides BYPASS
	STR	R2, [R3]
; step 2: set crystal value & select the Main Oscillator (MOSC)
	LDR	R1, = SYSCTL_RCC_R
	LDR	R0, [R1]
	BIC	R0, R0, #0x000007C0		; clear XTAL field in RCC
	ORR	R0, R0, #0x00000540		; configure for 16MHz crystal
	STR	R0,	[R1]
	LDR	R3, =SYSCTL_RCC2_R
	LDR	R2, [R3]	
	BIC	R2, R2, #0x00000070		; select Main Oscillator MOSC in RCC2
	STR	R2, [R3]
; step 3: turn on the PLL by clearing PWRDN2
	LDR	R3, =SYSCTL_RCC2_R
	LDR	R2, [R3]	
	BIC	R2, R2, #0x00002000		; power up the PLL
	STR	R2, [R3]
; step 4: divide the clock frequency (if desired)
	ORR	R2,	R2, #0x40000000		; set DIV400 to pass the undivided 400MHz clk thru
	BIC	R2, R2, #0x1FC00000		; clear system clock divider field (SYSDIV2) including SYSDIV2LSB
	ADD	R2, R2, #(SYSDIV2<<22)	; SYSDIV2 = 4 & BYPASS2 = 1 --> 80 MHz clock (see documentation)
	STR	R2, [R3]	
; step 5: wait for PLL to lock by polling PLLRIS
;	R0 --> SYSCTL_RIS_R data
;	R1 --> SYSCTL_RIS_R address
	LDR	R1, =SYSCTL_RIS_R		; raw interrupt status register
PLL_Init_loop
	LDR	R0, [R1]
	ANDS R0, R0, #0x00000040	; mask for PLL RIS
	BEQ	PLL_Init_loop			; if PLL RIS == 0, keep polling
; step 6: enable use of PLL by clearing BYPASS
	LDR	R3, =SYSCTL_RCC2_R
	LDR	R2, [R3]	
	BIC	R2, R2, #0x00000800		; clear BYPASS2 --> switch to PLL clock signal
	STR	R2, [R3]
	NOP

	BX	LR
	
	
	ALIGN      ; make sure the end of this section is aligned
    END        ; end of file