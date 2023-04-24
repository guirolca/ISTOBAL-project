#include <p18f4520.h>
#include <stdlib.h>	
#include <delays.h>
#include <usart.h>

#pragma config OSC = INTIO67
#pragma config PWRT = ON, BOREN = SBORDIS, BORV = 3
#pragma config WDT = OFF
#pragma config MCLRE = ON, PBADEN = ON, CCP2MX = PORTC
#pragma config STVREN = ON, LVP = OFF

unsigned char dato[6];
unsigned char dato2,sumcheck;
unsigned int  i,j,datox,datoy,Value,Value2,Value3,ValueL,ValueH,Value2H,Value2L,Value3H,Value3L,State,Initialservo,count,datoconf;
float Servo1,Servo2,Pixelx;	//Direccion del esclavo

//unsigned long dato1,dato2;	// Variable en la que se almacenará el resultado de la conversión

void R_Int_Alta(void);  // Declaración de la subrutina de tratamiento de interrupciones de alta prioridad

#pragma code Vector_Int_Alta=0x08  // Vectorización de las interrupciones de alta prioridad
void Int_Alta (void)
{
    _asm GOTO R_Int_Alta _endasm
}
#pragma code

#pragma interrupt R_Int_Alta  // Rutina de tratamiento de las interrupciones de alta prioridad
void R_Int_Alta (void)
{
    if (INTCONbits.TMR0IF==1) // Check if interrupt is caused by timer 0 overflow
    {
        INTCONbits.TMR0IF=0; // Interrupt flag is reset to ?0'
        
        switch (State)
        {
            case 1:
                PORTCbits.RC0=1;
                PORTCbits.RC1=0;
                TMR0H=ValueH; // TMR0H and TMR0L are reload with the initial value corresponding to 1,5ms
                TMR0L=ValueL;
                State=2;
                break;
            case 2:
                PORTCbits.RC0=0;
                PORTCbits.RC1=0;
                TMR0H=Value3H; // TMR0H and TMR0L are reload with the initial value corresponding to 20ms
                TMR0L=Value3L; // TMR0=65536-(TINTERVALO/TT0)=65536-(20000·E-6*4·E6)/4)=45536
                State=3;
                break;    
                
            case 3:
                PORTCbits.RC0=0;
                PORTCbits.RC1=1;
                TMR0H=Value2H; // TMR0H and TMR0L are reload with the initial value corresponding to 20ms
                TMR0L=Value2L; // TMR0=65536-(TINTERVALO/TT0)=65536-(20000·E-6*4·E6)/4)=45536
                State=1;
                break;

        }
    }


    else if (PIR1bits.RCIF) 		// Se comprueba si la interrupción ha sido por recepción
    {
            
            dato2 = ReadUSART(); // Se almacena el dato leído en la posición correspondiente del bufer
            dato[count]=dato2;
            if (dato[0]==210){
                count++;
                if (count==6){
                    if (sumcheck==dato[5]){
                        
                    LATDbits.LATD0=!LATDbits.LATD0;
                        datox=dato[1]*256+dato[2];
                        datox=640-datox;
                        datoy=dato[3]*256+dato[4];
                    }
                        count=0;
                        sumcheck=0;
                          
            }
                else{
                    sumcheck+=dato[count-1];
                }
            }   
    }
}

void main(void)		// Programa principal
{
    Delay10KTCYx(50);
    TRISA=0xF1;                 // RB0, RB1 y RB2 de salida

    OSCCONbits.IRCF0=0;
    OSCCONbits.IRCF1=1;
    OSCCONbits.IRCF2=1;

    OpenUSART (USART_TX_INT_OFF & USART_RX_INT_ON & USART_ASYNCH_MODE
            & USART_EIGHT_BIT & USART_CONT_RX & USART_BRGH_HIGH,25);

    // Se configura la USART en modo 8 bits, sin paridad, 1 Stop bit,  9600 baud
    // e interr. de recepción habilitada
    // Vel. Com.= Fosc/(16*(SPBREG+1))=4000000/(16*(25+1))=9615



    TRISA=0b00000000; // Input A
    TRISC=0xFC;
    TRISDbits.TRISD0=0;

    ADCON1=0b00001100; // Analogue inputs A0 and A1 and A2
    ADCON2=0b10010001; //right; 4*T; FOSC/4 (T=1us)

    T0CON=0x88;	// Timer 0 modo temp. de 16 bits. Prescalar (por lo visto desactivado [88]). TIMER ON
	TMR0H=65536/256;	// Se carga el valor de TMR0H y TMR0L para un intervalo de 1s
	TMR0L=65536%256;	// TMR0=65536-(TINT*FOSC/4*PRES)=65536-(1s*65534Hz(que he puesto yo))/4*1(disabled))=???? =0x0002
    INTCONbits.GIE=1;	// Se habilitan las interrupciones a nivel global
    INTCONbits.PEIE = 1;	// Se activan las interrupciones de periféricos a nivel global
    INTCONbits.TMR0IE=1; // Se habilita la interrupción del Temporizador 0
    PIE1bits.RCIE=1; // Se habilita la interrupción del Temporizador 0
    
    State=1;
    count=0;
    sumcheck=0;
    datox=300;
    datoy=200;

    while(1)	// Bucle principal
    {
        
    Servo1=datox*25/16; //Valores de pixel correpondientes sobre 1000 para facilitar los calculos
    Servo2=datoy*25/12;
    
    Value=65536-(860+1750/3+Servo1*0.33); //Formulas de calculo de frecuencia de los servos
    Value2=65536-(860+1750/3+Servo2*0.25);
    Value3=65536-(20000);
  //  Value=65536-1500;
  //  Value2=65536-1500;
    ValueH=Value>>8;
    ValueL=Value & 0xFF;
    Value2H=Value2>>8;
    Value2L=Value2 & 0xFF;
    Value3H=Value3>>8;
    Value3L=Value3 & 0xFF;
        
    }
}

