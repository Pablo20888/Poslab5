; Archivo: Main_pos5.s
; Dispositivo: PIC16F887
; Autor: PABLO FUENTES 20888
; Compilador: pic-as (v2.30), MPLABX v5.50
;
; Programa: CONTADOR CON SETUP_TMR0
; Hardware: 2 displays
;
; Creado: 21 feb, 2022
; Última modificación: 26 feb, 2022

PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
  CONFIG FOSC=INTRC_NOCLKOUT   // Oscilador interno
  CONFIG WDTE=OFF  // WDT disabled (reinicio repetitivo del pic)
  CONFIG PWRTE=ON  // PWRT enabled (espera de 72ms al iniciar)
  CONFIG MCLRE=OFF // El pin MCLR se utiliza como I/0
  CONFIG CP=OFF    // Sin proteccion de codigo
  CONFIG CPD=OFF   // Sin proteccion de datos
    
  CONFIG BOREN=OFF // Sin reinicio cuando el voltaje de alimentacion baja de 4V
  CONFIG IESO=OFF  // Reinicio sin cambio de RELOJ de interno a externo
  CONFIG FCMEN=OFF // Cambio de RELOJ externo a interno en caso de fallo
  CONFIG LVP=ON    // Programacion en bajo voltaje permitida
    
;configuration word 2
  CONFIG WRT=OFF   // Proteccion de autoescritura por el programa desactivada
  CONFIG BOR4V=BOR40V  // Reinicio abajo de 4V, (BOR21V=2.1V)

UP    EQU 0   ; Asignacion de nombres para los pushbutton 
DOWN  EQU 1
 
reinicio_tmr0 macro ; Macro para el reinicio del tmr 0
 banksel PORTA	    ; Se llama al bank
 movlw  253	    ;valor inicial que sera colocado en el tmr0
 movwf  TMR0
 bcf	T0IF	    
 endm
 
PSECT udata_bank0   
  var:  DS 2	; Cantidad de bytes en cada variable
  Uni:	DS 1
  Decc:	DS 1
  Cen:	DS 1
    
;variables
PSECT udata_shr
  W_TEMP:	DS 1	    ;Variables a utilizar 
  STATUS_TEMP:  DS 1	    ;Asignar cantidad de bytes a cada variable
  flags:	DS 2
  nibble:	DS 2 
  cambio_disp:  DS 5
    
    
PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2
;-----------vector interrupt--------------;
ORG 04h     ;posicion 0004h para las interrupciones
push:
    movwf   W_TEMP	    ;Colocar las variables temporales a W
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:
    btfsc   RBIF	    ;Revisar interrupciones en el puerto B
    call    PB_subr	    ;Llamada a subrutina de pushbuttons
    btfsc   T0IF	    
    call    TMR0_SR	    ;Llamada a subrutina de SETUP_TMR0
    
pop:
    swapf   STATUS_TEMP, W  ;Regresa a W al status
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
PB_subr:
    banksel PORTA	    ;Subrutina de interrupcion de los push-butttons
    btfss   PORTB, UP
    incf    var
    movf    var, W
    movwf   PORTA
    btfss   PORTB, DOWN
    Decf    var
    movf    var, W
    movwf   PORTA
    bcf	    RBIF
    return
	
TMR0_SR:		    
    reinicio_tmr0           
    bcf	    PORTB, 5
    bcf	    PORTB, 6
    bcf	    PORTB, 7
    btfsc   flags, 0	    
    goto    DIS_1
    btfsc   flags, 1
    goto    DIS_2
    btfsc   flags, 2
    goto    DIS_3
    btfsc   flags, 3
    goto    DIS_4
   
display0:			
    movf    cambio_disp, W	
    movwf   PORTC		
    bsf	    PORTE, 0		
    goto    sigDisp0		
    
DIS_1:
    movf    cambio_disp+1, W	
    movwf   PORTC		
    bsf	    PORTE, 1		
    goto    sigDisp1

DIS_2:
    movf    cambio_disp+2, W	
    movwf   PORTC		
    bsf	    PORTB, 5		
    goto    sigDisp2
    
DIS_3:
    movf    cambio_disp+3, W	
    movwf   PORTC		
    bsf	    PORTB, 6		
    goto    sigDisp3

DIS_4:
    movf    cambio_disp+4, W	
    movwf   PORTC		
    bsf	    PORTB, 7		
    goto    sigDisp4
    
sigDisp0:		
    movlw   00000001B
    xorwf   flags, 1	    
    return
sigDisp1:
    movlw   00000011B
    xorwf   flags, 1
    return
sigDisp2:
    movlw   00000110B
    xorwf   flags, 1
    return
sigDisp3:
    movlw   00001100B
    xorwf   flags, 1
    return
sigDisp4:
    clrf    flags
    return

RTRN_TMR0:
    return
    
PSECT code, delta=2, abs
ORG 100h    ; Ubicación para le codigo
 TABLA:
    clrf    PCLATH
    bsf	    PCLATH, 0   ;PCLATH = 01
    andlw   0x0f
    addwf   PCL         ;PC = PCLATH + PCL  se configura la TABLA para el siete segmentos
    retlw   00111111B  ;0
    retlw   00000110B  ;1
    retlw   01011011B  ;2
    retlw   01001111B  ;3
    retlw   01100110B  ;4
    retlw   01101101B  ;5
    retlw   01111101B  ;6
    retlw   00000111B  ;7
    retlw   01111111B  ;8
    retlw   01100111B  ;9
    retlw   01110111B  ;A
    retlw   01111100B  ;B
    retlw   00111001B  ;C
    retlw   01011110B  ;D
    retlw   01111001B  ;E
    retlw   01110001B  ;F
       
;-----------configuracion--------------;
	
main:
    banksel ANSEL	
    clrf    ANSEL	
    clrf    ANSELH  
    banksel TRISA	
    movlw   0x0
    movwf   TRISA
    bsf	    TRISB, UP	
    bsf	    TRISB, DOWN
    bcf	    TRISE, 0	
    bcf	    TRISE, 1
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    bcf	    TRISB, 7
    bcf	    OPTION_REG, 7   
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    movlw   0x0  
    movwf   TRISC
    call    RELOJ	
    call    config_ioc	
    call    SETUP_TMR0	
    call    SETUP_INT	
    banksel PORTA	
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    var

;----------Loop------------------------------

loop:
    banksel PORTA	
    call    SETUP_NIBBLES
    call    SETUP_DISPLAYS
    banksel PORTA
    call    division
    goto loop		
  
    
SETUP_NIBBLES:
    movf    var, W	
    andlw   0x0f
    movwf   nibble
    swapf   var, W
    andlw   0x0f
    movwf   nibble+1
    return
    
SETUP_DISPLAYS:
    movf    nibble, W	    
    call    TABLA
    movwf   cambio_disp
    movf    nibble+1, W
    call    TABLA
    movwf   cambio_disp+1
    movf    Cen, W
    call    TABLA
    movwf   cambio_disp+2
    movf    Decc, W
    call    TABLA
    movwf   cambio_disp+3
    movf    Uni, W
    call    TABLA
    movwf   cambio_disp+4
    return
    
config_ioc:
    banksel TRISA
    bsf	    IOCB, UP	   
    bsf	    IOCB, DOWN
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF
    return
    
RELOJ:
    banksel  OSCCON
    bcf      IRCF2      
    bsf	     IRCF1
    bcf	     IRCF0
    bsf	     SCS        
    return
    
SETUP_TMR0:
    banksel TRISA
    bcf	    T0CS       
    bcf	    PSA	       
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0        
    banksel PORTA
    reinicio_tmr0
    return

SETUP_INT:	    
    bsf	    GIE     
    bsf	    RBIE
    bsf	    T0IE
    bcf	    RBIF
    bcf	    T0IF
    return

division: 
    clrf    Cen		     
    movf    PORTA, 0	    
    movwf   Uni	    	    
    movlw   100		    
    subwf   Uni, 0	    
    btfsc   STATUS, 0	    
    incf    Cen		    
    btfsc   STATUS, 0	    
    movwf   Uni
    btfsc   STATUS, 0
    goto    $-7
    clrf    Decc	    
    movlw   10		    
    subwf   Uni, 0
    btfsc   STATUS, 0
    incf    Decc
    btfsc   STATUS, 0
    movwf   Uni		    
    btfsc   STATUS, 0
    goto    $-7
    btfss   STATUS, 0	    
    return

END


