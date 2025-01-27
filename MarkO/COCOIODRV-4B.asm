;*********************************************************************
;* Title: COCOIODRV-4B.asm
;*********************************************************************
;* Author: R. Allen Murphey, & MarkO
;*
;* License: Contributed 2021 by R. Allen Murphey to CoCoIO Development
;*
;* Description: CoCoIO with WIZnet W5100S driver code
;*
;* Documentation: https://www.wiznet.io/product-item/w5100s/
;*
;* Include Files: W5100SEQU.asm - W5100S Equates
;*                COCOIOEQU.asm - CoCoIO Equates
;*                COCOIOCFG.asm - CoCoIO Config Data
;*
;* Assembler: lwasm 1.4.2
;*
;* Revision History:
;* Rev #     Date      Who     Comments
;* -----  -----------  ------  ---------------------------------------
;* 00     2021         RAM     Initial Reset and Config functions
;*********************************************************************

            include "W5100SEQU.asm"
            include "COCOIOEQU.asm"

PIA0BD:     equ   $FF02       ; PIA 0 PORT B DATA
PIA0BC:     equ   $FF03       ; PIA 0 PORT B CONTROL

POLCAT:     equ   $A000
CHROUT:     equ   $A002


            org   $7E00
RESETP:     jmp   W5100_RST         ;$7E00
CONFIG:     jmp   W5100_CFG         ;$7E03
SETREG:     jmp   W5100_SETREG      ;$7E06
GATEWAY:    jmp   W5100_GATEWAY     ;$7E09
SUBNET:     jmp   W5100_SUBNET      ;$7E0C
HARDWARE:   jmp   W5100_HARDWARE    ;$7E0F
IPADDR:     jmp   W5100_IPADDR      ;$7E12
MPISLOT:    jmp   MPISLOT1          ;$7E15

DISPGW:     jmp   DISP_GATEWAY      ;$7E18
DISPSN:     jmp   DISP_SUBNET       ;$7E1B
DISPHW:     jmp   DISP_HARDWARE     ;$7E1E
DISPIPADD:  jmp   DISP_IPADDR       ;$7E21


W5100_RST:                    ; Reset the CoCoIO WIZnet 5100S
            jsr   MPISLOT1
;            jsr   DALLY
            lda   CIO0CMND    ; Read the current value of MR from CoCoIO Command
            ora   #%10000000  ; Flip bit 7 RST to 1 = init all W5100S registers - autoclear in 3 SYS_CLK
            sta   CIO0CMND    ; Trigger the reset
RSTDONE:    lda   CIO0CMND    ; Now read command register to check bit 7 clears when reset is done
            bmi   RSTDONE     ; if bit 7, then A was negative, keep checking bit
SETMODE:    ora   #%00000011  ; bit 7 cleared, setup Ping Block disabled, no PPPoE, AutoIncrement, and Indirect Bus Mode
            sta   CIO0CMND    ; configure the chip and done
            lda   CIO0CMND    ; readback mode
            cmpa  #3          ; is it what we want?
            bne   SETMODE     ; no, try again
            rts

W5100_CFG:                    ; Configure the CoCoIO WIZnet W5100S
            jsr   MPISLOT1
;            jsr   DALLY
                                  ; Bring up layer 3 default route
            ldd   #GAR0           ; W5100S Gateway Address Register 0
            ldx   #MYGATEWAY      ; Get the location of the Gateway data 
            ldy   #4              ; Setup for loop counting
            jsr   W5100_SETREG

                                  ; Bring up layer 3 network mask
            ldd   #SUBR0          ; W5100S Subnet Mask Address Register 0
            ldx   #MYSUBNET       ; Get the location of the Subnet data
            ldy   #4              ; Setup for loop counting
            jsr   W5100_SETREG

                                  ; Bring up layer 2 address
            ldd   #SHAR0          ; W5100S Source Hardware Address Register 0
            ldx   #MYMAC          ; Get the location of the MAC data
            ldy   #6              ; Setup for loop counting
            jsr   W5100_SETREG

                                  ; Bring up layer 3 address
            ldd   #SIPR0          ; W5100S Source IP Register 0
            ldx   #MYIP           ; Get the location of the IP data
            ldy   #4              ; Setup for loop counting
            jsr   W5100_SETREG
            rts

W5100_SETREG:                 ; Configure the Registers; D for Start, Y for Length, X for Data
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY
            tfr   y,d         ; Setup B for loop counting
SETLOOP:    lda   ,x+         ; Load A with the next byte of Gateway
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY
            decb              ; Decrement loop counter
            bne   SETLOOP     ; No, go back and do more
;            jsr   DALLY
            rts



W5100_GATEWAY:                ; Configure the Gateway address

W5100_SUBNET:                 ; Next the Subnet Mask

W5100_HARDWARE:               ; Next the Source Hardware Address

W5100_IPADDR:                 ; Next the Source IP Address

            rts

DISP_GATEWAY: 
            ldd   #GWLABEL
            jsr   DISPSTR0     ; Display the Label
            ldd   #GAR0        ; W5100S Gateway Address Register 0
            ldy   #4           ; Setup for loop counting
            jmp   W5100_DISREG ; Read the Registers


DISP_SUBNET:
            ldd   #SNLABEL
            jsr   DISPSTR0    ; Display the Label            
            ldd   #SUBR0      ; W5100S Subnet Mask Address Register 0
            ldy   #4           ; Setup for loop counting
            jmp   W5100_DISREG ; Read the Registers


DISP_HARDWARE:
            ldd   #MALABEL
            jsr   DISPSTR0     ; Display the Label
            ldd   #SHAR0       ; W5100S Source Hardware Address Register 0
            ldy   #6           ; Setup for loop counting
            jmp   W5100_DISREG ; Read the Registers


DISP_IPADDR:
            ldd   #IPLABEL
            jsr   DISPSTR0    ; Display the Label
            ldd   #SIPR0      ; W5100S Source IP Register 0
            ldy   #4           ; Setup for loop counting
            jmp   W5100_DISREG ; Read the Registers


W5100_DISREG:                 ; Display the Registers; D for Start, Y for Length
;            ldd   #GWLABEL
;            jsr   DISPSTR0    ; Display the Label
;            ldd   #GAR0       ; W5100S Gateway Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            tfr   y,d         ; Setup B for loop counting
DISLOOP:   
            jsr   BIN2HEX
            jsr   DISPB2H
            decb              ; Decrement loop counter
            bne   DISLOOP     ; No, go back and do more

            rts



MPISLOT1:                     ; Configure Multipack SCS to slot 1
            lda   $FF7F       ; Read the MPI slot control
            anda  #%11110000  ; zero out the SCS nybble for MPI slot 1
            sta   $FF7F       ; Write the updated SCS
            rts

DILLY:      lda   PIA0BD      ; clear any pending VSYNC interrupt on PIA0
DILLY1:     lda   PIA0BC      ; load up the current flags
            bpl   DILLY1      ; if bit 7 not set, keep checking flags
            lda   PIA0BD      ; clear the interrupt that just happened
            rts

DALLY:      pshs  x
            ldx   #$1000      ; A maximum delay loop 
DALLY1:     leax  -1,x        ; Decrement X
            bne   DALLY1      ; if X>0 not done yet
            puls  x
            rts




BIN2HEX:    ; W5100 Read DATA and Output HEX in ASCII

            pshs  d           ; Save D ( A&B ) for later

            lda   CIO0DATA    ; GET DATA from W5100, ( or BINVAL )
            ;
            ; CONVERT MORE SIGNIFICANT DIGIT TO ASCII
            ;
            tfr   a,b         ; SAVE ORIGINAL BINARY VALUE MOVE HIGH DIGIT TO LOW DIGIT
            lsra
            lsra
            lsra
            lsra
            cmpa  #9          ; BRANCH IF HIGH DIGIT IS DECIMAL
            bls   B2H30       ; ELSE ADD 7 S0 AFTER ADDING '0' THE 
            adda  #7          ; CHARACTER WILL BE IN 'A'..'F'
B2H30:      adda  #'0'        ; ADD ASCII 0 TO MAKE A CHARACTER
            sta HEX1VAL       ; STORE ASCII DATA

            ;
            ; CONVERT LESS SIGNIFICANT DIGIT TO ASCII
            ; 
            andb  #$0f        ; MASK OFF LOW DIGIT    
            cmpb  #9          ; BRANCH IF LOW DIGIT IS DECIMAL    
            bls   B2H30LD     ; ELSE ADD 7 SO AFTER ADDING '0' THE
            addb  #7          ; CHARACTER WILL BE IN 'A'..'F'
B2H30LD:    addb  #'0'        ; ADD ASCII 0 TO MAKE A CHARACTER
            stb   HEX2VAL     ; STORE ASCII DATA

            puls  d           ; Restore D ( A&B )

            rts  

DISPB2H:    lda   HEX1VAL
            jsr   [CHROUT]
            lda   HEX2VAL
            jsr   [CHROUT]
            rts

BINVAL:     fcb   $00
HEX1VAL:    fcb   $00
HEX2VAL:    fcb   $00



DISPSTR0:   ; This Sends a NULL Terminated String to CHROUT, MAX 256 Bytes
            pshs  d,x,y       ; Save D ( A&B ), X & Y for later

            tfr   d,x         ; Copy D to X, for Head of StringZ
            ldb   #0          ; Setup B for MAX loop, 256
DISPSTRLP:  lda   ,x+         ; Load A with the byte of the String
            beq   DISPSTRX    ; End of String Reached   
            jsr   [CHROUT]    ; Output Character on Screen
            decb              ; Decrement loop counter
            bne   DISPSTRLP   ; No, go back and do more

DISPSTRX:
            puls  d,x,y       ; Restore D ( A&B ), X & Y

            rts

GWLABEL:    fcc   "GATEWAY:     "
;            fcb   $0D,$0A,$00
            fcb   $00
SNLABEL:    fcc   "SUBNET:      "
;            fcb   $0D,$0A,$00
            fcb   $00
MALABEL:    fcc   "MAC ADDRESS: "
;            fcb   $0D,$0A,$00
            fcb   $00
IPLABEL:    fcc   "IP ADDRESS:  "
;            fcb   $0D,$0A,$00
            fcb   $00

BUFRSOC0:   ; This sets up Socket 0, with 8KB RX and TX Buffers
            ldd   #RMSR       ; RX Memory Size Register
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY

            lda   #MSR_8KB_S0 ; Memory Size, 8KB, Socket 0
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY

;            ldd   #TMSR       ; TX Memory Size Register
;            sta   CIO0ADDR    ; CoCoIO Address Register MSB
;            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY

            lda   #MSR_8KB_S0 ; Memory Size, 8KB, Socket 0
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY
            rts


INITSOC0:
            ; The Local Port.         
            ldd   #S0_PORTR0  ; Socket 0 Source Port Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY

            ldd   #$C000      ; Port $C000
            sta   CIO0DATA    ; Store it to W5100S
            stb   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY



            ldd   #S0_MR      ; Socket 0 Mode Register
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY

            lda   #S_CR_OPEN  ; Open Command
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY
            rts





;     S0_MR





FORGNIP:                      ; Foreign IP Address
            fcb   192,168,254,100

FORGNPORT:                    ; Foreign Port
            fdb   20000       

FORGNC:                       ; My Source Hardware Address
            fcb   $00,$08,$DC,$00,$00,$01

FORGNP:                        ; My Source IP Address
            fcb   192,168,254,10


            include "COCOIOCFG.asm"

            end   RESET       ; End of driver
