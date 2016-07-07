# File: elaborato.s
# Autore: Alessandro Righi
# Data: 29/06/16
# Descrizione: file principale dell'elaborato

.include "syscall.inc" # file header per la definizione delle syscall
.include "states.inc"  # file header per la definizione degli stati

# Allocazione delle stringhe: esse vengono allocate nella sezione rodata in quanto non è necessario 
# modificarle a runtime, in modo del tutto simile a quello che farebbe un compilatore C.
# Vengono anche impostate delle costanti per contenere la dimensione in byte delle stringhe: 
# l'operatore ".-", che alla fine ho capito come funziona, calcola il numero di byte fra la label 
# indicatagli e la corrente posizione dell'assemblatore, ossia esegue la sottrazione fra l'indirizzo 
# attuale a cui è posizionato e l'indirizzo della label specificatagli (se ho capito bene).
.section .rodata
str_messaggio_iniziale: .ascii "Progetto Assembly 2016 - Alessandro Righi\n"
len_messaggio_iniziale = .-str_messaggio_iniziale

str_messaggio_fine: .ascii "Coputazione terminata con successo!\n"
len_messaggio_fine = .-str_messaggio_fine

str_usage: .ascii "Utilizzo: ./elaborato file-input file-output\n"
len_usage = .-str_usage

str_file_input_error: .ascii "Errore nell'apertura del file di input, controlla path e permessi!\n"
len_file_input_error = .-str_file_input_error

str_file_output_error: .ascii "Errore nell'apertura del file di output, controlla path e permessi!\n"
len_file_output_error = .-str_file_output_error

# Variabili globali non inizializzate, inizializzate a 0 dal kernel al caricamento in memoria.
.section .bss
input_fd: .space 4  # variabile intera che contiene il file descriptor del file di input
output_fd: .space 4 # variabile intera che contiene il file descriptor del file di output
stato: .space 4     # variabile intera che contiene lo stato attuale del motore
count: .space 4     # variabile intera che contiene il conteggio dei secondi nell'attual modalità

# buffer di input da 9 byte usato durante la lettura da file
input_buffer_len = 9
input_buffer: .space input_buffer_len

# buffer di output da 8 byte usato durante la scrittura su file
output_buffer_len = 8
output_buffer: .space output_buffer_len

# Codice principale del programa: _start è l'entry point di ogni programa assembly.
.section .text
.global _start # dichiaro il simbolo start come globale, in modo da renderlo visibile al linker
_start:

    # NB: i parametri da riga di comanto si trovano sullo stack alle seguenti locazioni di memoria:
    #     argc    -> (%esp)   - numero di argomenti passati al programma
    #     argv[0] -> 4(%esp)  - nome dell'eseguibile
    #     argv[1] -> 8(%esp)  - primo argomento, path file di input
    #     argv[2] -> 12(%esp) - secondo argomento, path file di output

    # Controllo se gli argomenti passati al programma sono esattamente 3: in caso contrario salto
    # alla label che stampa a video un messaggio di utilizzo.
    cmpl $3, (%esp)
    jne print_usage

    # Apro il file di input in modalità read-only mediante la chiamata di sistema open.
    movl $sys_open, %eax
    movl 8(%esp), %ebx
    movl $O_READONLY, %ecx
    int $SYSCALL

    # Controllo che il valore di ritorno, ossia il file descriptor del file aperto, è maggiore di 0:
    # in caso contrario significa che è stato riscontrato un errore nell'apertura dei file, quindi 
    # salto ad un apposita label che stampa un messaggio di errore ed esce.
    cmpl $0, %eax
    jle file_input_error

    # Metto il file descriptor del file appena aperto nella variabile input_fd
    movl %eax, input_fd

    # Apro il file di output in modalità sola scrittura. Se il file non esiste, esso viene creato, 
    # con i permessi 644 in formato UNIX (lettura e scrittura per l'utente, sola lettura per il 
    # gruppo e gli altri). Nel caso invece il file sia già esistente esso viene troncato a 0 byte.
    movl $sys_open, %eax
    movl 12(%esp), %ebx
    movl $O_WRITEONLY_AND_CREATE_AND_TRUNCATE, %ecx
    movl $0644, %edx # permessi in stile unix: user = all, group e other = read 
    int $SYSCALL

    # Come prima controllo che non si siano verificati errori durante l'apertura del file, in caso 
    # contrario salto alla stessa label che stampa un messaggio di errore ed esce.
    cmpl $0, %eax
    jle file_output_error

    # Metto il file descriptor del file di output nella variabile output_fd.
    movl %eax, output_fd

    # Stampo a video il messaggio di benvenuto.
    movl $sys_write, %eax
    movl $stdout, %ebx
    movl $str_messaggio_iniziale, %ecx
    movl $len_messaggio_iniziale, %edx
    int $SYSCALL 

# Qui entro nel loop principale del programma.
main_loop:

    # Leggo una riga dal file di input, e la metto nel buffer di input
    movl $sys_read, %eax
    movl input_fd, %ebx
    movl $input_buffer, %ecx
    movl $input_buffer_len, %edx
    int $SYSCALL

    # Se il numero di caratteri letti è uguale a 0, siamo giunti alla fine del file (EOF), quindi 
    # salto alla label che termina l'esecuzione del programma.
    testl %eax, %eax
    jz quit    

    # Chiamo la funzione che computa il nuovo stato del motore.
    movl $input_buffer, %edi # passo alla funzione il buffer di input nel registro EDI
    call calcola_stato

    # Se il nuovo stato appena calcolato è uguale a SPENTO, dobbiamo porre il contatore dei secondi 
    # a 0 come da specifiche.
    cmpl $SPENTO, %eax
    je resetta_count

    # Se il segnale di reset è attivo, ossia nella stringa di input alla posizione 2 abbiamo il 
    # il valore 1, dobiamo resettare il contatore dei secondi.
    cmpb $'1', 2(%ecx)
    je resetta_count

    # Se il nuovo stato non è uguale allo stato attuale del motore, significa che abbiamo cambiato 
    # stato e pertanto è necessario resettare il contatore dei secondi 
    cmpl %eax, stato
    jne resetta_count

    # Altrimenti incremento il contatore dei secondi di un unità
    incl count;

    # Salto via il reset del contatore dei secondi
    jmp continua

# questa label resetta il contatore dei secondi, ossia copia 0 nella variabile contatore.
resetta_count:
    
    # Carico 0 nella variabile contatore.
    movl $0, count

continua:

    # Ora carico il nuovo stato appena calcolato nella variabile stato.
    movl %eax, stato
    
    # Richiamo la funzione che costruisce la stringa di output da scrivere sul file di output.
    movl $output_buffer, %edi # in EDI metto il puntatore al buffer di output
    movl %eax, %esi           # in ESI metto lo stato corrente del motore 
    movl count, %ecx          # in ECX metto il contatore dei secondi
    call costruisci_stringa_output

    # Scrivo sul file di output la stringa precedentemente costruita.
    movl $sys_write, %eax
    movl output_fd, %ebx
    movl $output_buffer, %ecx
    movl $output_buffer_len, %edx
    int $SYSCALL

    # Rieseguo tutto il ciclo
    jmp main_loop

# Label che viene richiamata al momento dell'uscita dal programma, ossia in caso di EOF.
quit: 

    # Chiudo il file di input mediante la chiamata close.
    movl $sys_close, %eax
    movl input_fd, %ebx
    int $SYSCALL

    # Chiudo il file di output mediante la chiamata close.
    movl $sys_close, %eax
    movl output_fd, %ebx
    int $SYSCALL

    # Stampo a video il messaggo finale del programma che ne indica la corretta esecuzione.
    movl $sys_write, %eax
    movl $stdout, %ebx
    movl $str_messaggio_fine, %ecx
    movl $len_messaggio_fine, %edx
    int $SYSCALL

    # Esco dal programma tramite la chiamata di sistema exit con un valore di ritorno indicante un 
    # successo, ossia il valore 0 (definito mediante la costante EXIT_SUCCESS).
    movl $sys_exit, %eax
    movl $EXIT_SUCCESS, %ebx
    int $SYSCALL

# Label che stampa un messaggio di aiuto sull'utilizzo del programma, che viene richiamata quando l'
# utente non specifica correttamente gli argomenti da passare al programma.
print_usage:

    # Stampo il messaggio di utilizzo.
    movl $sys_write, %eax
    movl $stderr, %ebx
    movl $str_usage, %ecx
    movl $len_usage, %edx
    int $SYSCALL

    # Salto alla label che esce con valore di ritorno indicante un errore.
    jmp exit_error

# Label che stampa un messaggio di errore riguardante la non corretta apertura del file di input.
file_input_error:

    # Stampo il messaggo di errore relativo all'apertura del file di input.
    movl $sys_write, %eax
    movl $stderr, %ebx
    movl $str_file_input_error, %ecx
    movl $len_file_input_error, %edx
    int $SYSCALL

    # Salto alla label che esce con valore di ritorno indicante un errore.
    jmp exit_error

# Label che viene richiamata in caso di errore nell'apertura del file di output: chiude il file di 
# input precedentemente aperto, quindi stampa a video un opportuno messaggio di errore, ed esce con 
# stato di errore.
file_output_error:

    # Chiudo il file di input mediante la chiamata close.
    movl $sys_close, %eax
    movl input_fd, %ebx
    int $SYSCALL

    # Stampo il messaggo di errore relativo all'apertura del file di output.
    movl $sys_write, %eax
    movl $stderr, %ebx
    movl $str_file_output_error, %ecx
    movl $len_file_output_error, %edx
    int $SYSCALL

    # Falltrough ad exit_error

# Label che termina il programma indicando uno stato di uscita di errore, ossia il valore 1 (definito
# mediante la costante EXIT_ERROR)
exit_error: 

    # Esegue la chiamata di sistema exit con stato di uscita EXIT_ERROR (1)
    movl $sys_exit, %eax
    movl $EXIT_ERROR, %ebx
    int $SYSCALL
