# File: costruisci_stringa_output.s
# Autore: Alessandro Righi
# Data: 29/06/16
# Descrizione: funzione che costruisce la stringa di output

.include "states.inc" # File header che contiene la definizione delle costanti per gli stati.

.text # Indico all'assemblatore di inserire quanto segue nella sezione text.
.global costruisci_stringa_output # Indico di esportare globalmente il simbolo costruisci_stringa_output
.type costruisci_stringa_output, @function # Indico che questa label è una funzione (serve al debugger)

# Funzione che costruisce la stringa per l'output dello stato corrispondente. 
# Parametri di ingresso:
# EDI -> buffer di output su cui scrivere
# ESI -> stato del motore
# ECX -> conteggio dei secondi
# Valori di ritorno: nessuno.
costruisci_stringa_output:
    # Iposto l'output ALM: se mi trovo in FG
    cmpl $FG, %esi # se lo stato non è FG 
    jne no_alm     # non devo attivare ALM

    # e il conteggio dei secondi è >= 15
    cmpl $15, %ecx # se il conteggio dei secondi è minore di 15
    jl no_alm      # non devo attivare ALM

    # attivo l'allarme
    movb $'1', (%edi) # metto il valore ASCII 1 al carattere 0 della stringa.
    jmp continue      # salto via la label che setta ALM a 0

# Label che viene richiamata in caso di non attivazone di ALM
no_alm:
    # altrimenti lo stetto a 0
    movl $'0', (%edi)

continue:
    # creo l'output per lo stato, prima cifra di STATE
    movl $2, %eax     # metto 2 (0x10) in EAX
    andl %esi, %eax   # metto in AND EAX con EDI 
    shrl $1, %eax     # schifto di 1 a destra
    addl $48, %eax    # aggiunto il valore ASCII dello 0
    movb %al, 2(%edi) # sposto quello che ho ottenuto nella stringa di output

    # seconda cifra
    movl $1, %eax     # metto 1 (0x01) in EAX
    andl %esi, %eax   # metto in AND EAX con EDI
    addl $48, %eax    # aggiungo il valore ASCII dello 0
    movb %al, 3(%edi) # sposto quello che ho ottenuto nella stringa di output

    # Ora non mi resta che creare l'output per il numero di secondi. Devo fare una divisione.
    xorl %edx, %edx  # azzero EDX
    movl %ecx, %eax  # metto ECX in EAX
    movl $10, %ecx   # metto il dividento 10 in ECX
    divl %ecx        # divide EDX:EAX per ECX, con quoziente in EAX e resto in EDX

    # Ora ho le mie due cifre del numero, quindi gli aggiungo il valore ASCII dello 0
    addl $48, %eax  
    addl $48, %edx 

    # e sposto i valori nella giusta posizione della stringa
    movb %al, 5(%edi) 
    movb %dl, 6(%edi)

    # manca solo da aggiungere alla stringa le due virgole e il '/n' finale nei corrispondenti spazi
    movb $',', 1(%edi)
    movb $',', 4(%edi)
    movb $'\n', 7(%edi)

    # ed ho finito!
    ret
