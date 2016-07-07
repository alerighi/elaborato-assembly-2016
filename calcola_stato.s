# File: calcola_stato.s
# Autore: Alessandro Righi
# Data: 29/06/16
# Descrizione: funzione che calcola lo stato del motore

.include "states.inc" # File header che contiene la definizione delle costanti per gli stati.

.text # Indico all'assemblatore di inserire quanto segue nella sezione text.
.global calcola_stato          # Indico di esportare globalmente il simbolo calcola_stato
.type calcola_stato, @function # Indico che questa label è una funzione (serve al debugger)
# Parametri di ingresso: 
# EDI -> buffer di input da cui leggere
# Valori di ritorno:
# EAX -> stato del motore
calcola_stato:
    # si protrebbe richiamare una funzione atoi, il che sarebbe forse il metodo più pulito, tuttavia
    # mi è venuto in mente un metodo "più ottimizzato" e più semplice alla fin fine

    # prima controllo che il motore non sia spento 
    cmpb $'0', (%edi)
    je spento

    # comparo la 5a lettera della stringa, ossia la prima cifra del numero di giri, con il valore 
    # corrispondente a 2 in codice ASCII. Se minore il numero è per forza minore di 2000, quindi SG
    cmpb $'2', 4(%edi)
    jl sg

    # se il numero è maggiore di 5000, sicuramente FG
    cmpb $'5', 4(%edi)
    jge fg

    # ora comparo sempre la 5a lettera con 52, corrispondente al valore ASCII di 4. Se minore di 4 
    # sicuramente OPT, se uguale a 4, controllo le cifre seguenti, se una cifra delle seguenti è 
    # maggiore di 0, siamo nello stato FG, se tutte le cifre seguenti al 4 sono zero, allora 
    # abbiamo il valore 4000 e ci troviamo ancora in OPT.
    cmpb $'4', 4(%edi)
    jl opt

    cmpb $'0', 5(%edi)
    jne fg 

    cmpb $'0', 6(%edi)
    jne fg 
    
    cmpb $'0', 7(%edi)
    jne fg 

# Label che ritorna in EAX lo stato OPT
opt:
    movl $OPT, %eax 
    ret

# Label che ritorna dalla funzione lo stato FG
fg:
    movl $FG, %eax
    ret 

# Label che ritorna dalla funzione lo stato SG
sg:
    movl $SG, %eax
    ret

# Label che ritorna dalla funzione lo stato SPENTO
spento:
    movl $SPENTO, %eax
    ret
