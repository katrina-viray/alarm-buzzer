
; 
SYSCTL_RCGCGPIO_R  	EQU 0x400FE608

; PortF configuration registers
GPIO_PORTF_DIR_R   	EQU 0x40025400	; GPIO direction register (GPIODIR)
GPIO_PORTF_AFSEL_R 	EQU 0x40025420	; GPIO alternative function select (GPIOAFSEL)
GPIO_PORTF_PUR_R   	EQU 0x40025510	; GPIO pull-up resistor register (GPIOPUR)
GPIO_PORTF_DEN_R   	EQU 0x4002551C	; GPIO digital enable (GPIODEN)
GPIO_PORTF_LOCK_R  	EQU 0x40025520	; GPIO lock register (GPIOLOCK)
GPIO_PORTF_CR_R    	EQU 0x40025524	; GPIO commit register (GPIOCR)
GPIO_PORTF_AMSEL_R 	EQU 0x40025528	; GPIO analog mode select (GPIOAMSEL)
GPIO_PORTF_PCTL_R  	EQU 0x4002552C	; GPIO port control (GPIOPCTL) 
GPIO_LOCK_KEY      	EQU 0x4C4F434B  ; Unlocks the GPIO_CR register




	THUMB
	
		  
; *********************************************************************
; *************************** CODE AREA IN ROM ************************
; *********************************************************************
	AREA    MyPortFConfig, CODE, READONLY, ALIGN=2		; Flash ROM
		    
	ALIGN
		  

	EXPORT	PortF_Config
		

PortF_Config
; PORT F INITIALIZATION CODE ***********************************
; step 1:  activate clock for Port F
	LDR	R1,	=SYSCTL_RCGCGPIO_R	; load R1 with address of GPIO Run Mode Clock Gating Control register
	LDR	R0, [R1]
	ORR	R0, R0, #0x20			; set bit 5 to turn on clock for Port F
	STR	R0, [R1]				; store bits back to RCGCGPIO register
	NOP
	NOP							; allow time for clock to configure
; step 2: unlock the lock register for Port F
	; 2a: load the key in the lock register
	LDR R1, =GPIO_PORTF_LOCK_R	; loads register R1 with address of Port F lock register
	LDR	R0, =0x4C4F434B			; loads value 0x4C4F434B into R0
	STR	R0, [R1]				; stores value 0x4C4F434B into lock register

	; 2b: give write access to GPIOAFSEL, GPIOPUR, GPIOPDR, & GPIODEN configuration registers
	LDR	R1, =GPIO_PORTF_CR_R	; loads register R1 with address of Port F commit register
	LDR	R0, [R1]				; loads register R0 with value in Port F commit register
	ORR	R0, R0, #0xFF			; sets bits 0-7 of R0 leaving other bits unchanged
	STR	R0, [R1]				; sets bits 0-7 of Port F commit register

; step 3: disable analog function --> analog function is disabled by default
	LDR	R1, =GPIO_PORTF_AMSEL_R	; analog mode select register
	LDR	R0, [R1]				; load content of GPIOAMSEL register to R0
	BIC	R0, R0, #0xFF			; clear bottom 8 bits of the GPIOAMSEL data
	STR R0, [R1]
  
; step 4: clear bits in PCTL --> most GPIO pins are set to GPIO on reset (i.e., no alternate function)
	LDR	R1, =GPIO_PORTF_PCTL_R	; load R1 with address of port control register
	MOV	R0, #0					; load 0s in all 32 bits to set all 8 pins to GPIO and not an alternate function (4 bits per pin)
	STR	R0, [R1]
 
; step 5: set direction register
	LDR	R1, =GPIO_PORTF_DIR_R	; load the address pointing to the Port F GPIO direction register(GPIODIR)
	LDR	R0,	[R1]				; load the current contents of the Port F GPIODIR
	BIC	R0,	R0, #0x11			; clear bits 0 (make them inputs)
	ORR	R0, R0, #0xE			; set bits 1 (make them outputs)
	STR R0, [R1]				; store the result in the Port F GPIODIR
	
	LDR	R1, =GPIO_PORTF_PUR_R
	LDR	R0,	[R1]
	ORR	R0,	#0x11				; place pull-up resistor on input pin 0
	STR	R0, [R1]
	
; step 6: clear bits in alternate function register
	LDR	R1,	=GPIO_PORTF_AFSEL_R	; alternate function register address
	LDR	R0,	[R1]				; load AFSEL register value into R0
	BIC	R0, R0, #0x1F			; clear all port F bits (could have used mask of 0xFF too)
	STR	R0, [R1]				; write back to AFSEL register
 
; step 7: enable digital port
	LDR	R1, =GPIO_PORTF_DEN_R	; load digital enable register address
	LDR	R0, [R1]				; load value of GPIODEN register into R0
	ORR	R0, R0, #0x1F			; set bits for pins 1-0 to enable digital pins (could have used mask of 0xFF too)
	STR	R0, [R1]

	NOP
	
	BX	LR
	
    ALIGN      ; make sure the end of this section is aligned
    END        ; end of file