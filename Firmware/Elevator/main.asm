// Implementa��o Elevador (Firmware)
// 
// Curso: Engenharia de Computa��o
// Disciplina: Microcontroladores e Aplica��es
// Professor: Erick Barboza
// Alunos: Bruno Lemos, Karla Sophia, Leticia Gabriela e Maria Fernanda

/* Defini��es de vari�veis globais */

// Clock do microcontrolador (16Mhz)
#define CLOCK 16.0e6

/* Defini��es dos registradores */

// Registrador para uso geral
.def temp = R16

// Registradores usados para armazenar o estado do elevador
.def door = r20
.def floor = r21
.def next_floor = r22
.def counter = r23

/* Mudan�a para a mem�ria de programa */

.cseg
.org 0

/* Tabela de vetores de interrup��o (IVT) */

rjmp SETUP
.org OC1Aaddr
jmp OCI1A_Interrupt

/* Interrup��es */

OCI1A_Interrupt:
	push temp
	in temp, SREG
	push temp

	pop temp
	out SREG, temp
	pop temp
	reti

/* Fun��es */

// Enable Timer: Uma subrotina utilizada para ativar o timer A
//
// Registradores usados: r16 (temp)
Enable_Timer:
	push temp
	in temp, SREG
	push temp

	lds temp, TIMSK1
	sbr temp, 1 << OCIE1A
	sts TIMSK1, temp

	pop temp
	out SREG, temp
	pop temp

	sei

	ret

// Enable Timer: Uma subrotina utilizada para desativar o timer A
//
// Registradores usados: r16 (temp)
Disable_Timer:
	push temp
	in temp, SREG
	push temp

	lds temp, TIMSK1
	cbr temp, 1 << OCIE1A
	sts TIMSK1, temp

	pop temp
	out SREG, temp
	pop temp

	cli

	ret

// Delay 20ms: Uma subrotina que aciona um delay de 20ms
//
// Registradores usados: r16 (temp), r17, r18
// Assumindo que o clock � 16Mhz, 20ms precisa de 320.000 ciclos de clock
// CLOCK (16.0e6) * 20ms = CLOCK (16.0e6) * 0.02 = 320.000
Delay_20ms:
	push r16
	push r17
	push r18

	ldi r18, byte3(CLOCK * 0.02)
	ldi r17, high(CLOCK * 0.02)
	ldi r16, low(CLOCK * 0.02)

	subi r16, 1
	subi r17, 0
	subi r18, 0
	brcc pc-3

	pop r18
	pop r17
	pop r16

	ret

SETUP:
	/* Inicializa��o da pilha */

	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL, temp

	/* Defini��o das portas B, D e C */

	// Porta B
	//
	// PB5 = Andar 0 (Bot�es internos) - Entrada
	// PB4 = Andar 1 (Bot�es internos) - Entrada
	// PB3 = Andar 2 (Bot�es internos) - Entrada
	// PB2 = Andar 3 (Bot�es internos) - Entrada
	// PB1 = Andar 0 (Bot�es externos) - Entrada
	// PB0 = Andar 1 (Bot�es externos) - Entrada
	ldi temp, 0b00000000

	// Configurando a Porta B
	out DDRB, temp

	// Porta D
	// 
	// PD7 = Andar 2 (Bot�es externos) - Entrada
	// PD6 = Andar 3 (Bot�es externos) - Entrada
	// PD5 = Abrir Porta - Entrada
	// PD4 = Fechar Porta - Entrada
	// PD3 = Display 7 (Enrada A1) - Sa�da
	// PD2 = Display 7 (Enrada A2) - Sa�da
	// PD1 = Display 7 (Enrada A3) - Sa�da
	// PD0 = Display 7 (Enrada A4) - Sa�da
	ldi temp, 0b00001111

	// Configurando a Porta D
	out DDRD, temp

	// Porta C
	//
	// PC5 = Led - Sa�da
	// PC4 = Buzzer - Sa�da
	ldi temp, 0b00110000

	// Configurando a Porta C
	out DDRC, temp

	/* Definindo o estado inicial dos pinos de Sa�da */

	// Porta D
	//
	// PD3 = Display 7 (Enrada A1) - 0
	// PD2 = Display 7 (Enrada A2) - 0
	// PD1 = Display 7 (Enrada A3) - 0
	// PD0 = Display 7 (Enrada A4) - 0
	ldi temp, 0b00000000

	// Configurando a Porta D
	out PORTD, temp

	// Porta C
	//
	// PC5 = Led - 0
	// PC4 = Buzzer - 0
	ldi temp, 0b00000000

	// Configurando a Porta C
	out PORTC, temp

	/* Configurando o Timer A para 1s */

	// Tempo de 1s
	#define DELAY 1.0e-3

	// Prescale de 1024
	.equ PRESCALE = 0b101
	.equ PRESCALE_DIV = 1024

	// Clear Timer and Compare (CTC)
	.equ WGM = 0b0100
	
	// Calculando o valor para o TOP
	.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*DELAY))

	// Validando se ele est� dentro do limite esperado (65.532)
	.if TOP > 65535
	.error "TOP is out of range"
	.endif

	// Atribuindo o valor de compara��o (TOP)
	ldi temp, high(TOP)
	sts OCR1AH, temp
	ldi temp, low(TOP)
	sts OCR1AL, temp

	// Atribuindo o valor para o modo de opera��o (WGM)
	ldi temp, ((WGM&0b11) << WGM10)
	sts TCCR1A, temp
	ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, temp

	rjmp MAIN

MAIN:
	rjmp MAIN