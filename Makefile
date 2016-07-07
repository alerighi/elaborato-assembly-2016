# File: Makefile
# Autore: Alessandro Righi
# Data: 29/06/16
# Descrizione: file per la compilazione del progetto assembly

# Variabili che indicano quale assemblatore e linker si vogliono usare
AS:=as
LD:=ld

# L'opzione -rf di rm sopprime l'errore in caso di file non esistenti (serve per clean)
RM=/bin/rm -rf

# Viene usato l'echo di sistema in quanto l'echo integrato in make non supporta le opzioni -n e -e.
ECHO=/bin/echo

# I flag predefiniti per AS ed LD sono quelli per forzare la compilazione a 32 bit su sistemi a 64.
ASFLAGS:=--32
LDFLAGS:=-m elf_i386

# Variabile che indica il nome dell'eseguibile che si vuole generare
BINNAME=elaborato

# Variabile che contiene la lista dei file oggetto da compilare per il programma.
OBJ=elaborato.o calcola_stato.o costruisci_stringa_output.o

# Variabile che contiene la lista dei file header inclusi nel programma.
HEADERS=syscall.inc states.inc

# Di default make esegue il primo target definito nell'ordine. Per convenzione viene chiamato all
# il target da eseguire di default, quando non vengono specificati argomenti dalla riga di comando.
all: $(BINNAME)
	@$(ECHO) "Complilazione terminata correttamente!"
	@$(ECHO) "Eseguire con ./$(BINNAME) file_input.txt file_output.txt"

# Questo target genera il codice oggetto del file specificato, ossia assembla il file corrispondente
# .s in un file .o, richiamando l'assemblatore. La sintassi per questa cosa è un pò ostica.
%.o: %.s $(HEADERS)
	@$(ECHO) -n "Assembling $<"
	@$(AS) -c -o $@ $< $(ASFLAGS)
	@$(ECHO) -e "\t[ ok ]"

# Target che linka insieme il programma e genera il binario principale del progetto.
$(BINNAME): $(OBJ)
	@$(ECHO) -n "Linking $(BINNAME)"
	@$(LD) -o $@ $^ $(LDFLAGS)
	@$(ECHO) -e  "\t[ ok ]"

# Target che esegue la compilazione inserendo i simboli per il debug. Viene aggiunta ai flag per 
# l'assemblatore e per il linker l'opzione -g che indica di includere i simboli di debug nell'
# eseguibili, e successivamente viene generato il binario richiamando il targetn $(BINNAME)
debug: ASFLAGS += -g
debug: LDFLAGS += -g
debug: clean $(BINNAME)

# Target che pulisce la cartella dei sorgenti, eliminando tutti i file .o e il binario principale
clean:
	@$(ECHO) -n "Cleaning sources"
	@$(RM) *.o
	@$(RM) $(BINNAME)
	@$(ECHO) -e "\t[ ok ]"

# Target che stampa a video un messaggio di aiuto sull'utilizzo di questo Makefile.
help:
	@$(ECHO) "Utilizzo:"
	@$(ECHO) "    make - compila il progetto"
	@$(ECHO) "    make debug - compila con i simboli di debug"
	@$(ECHO) "    make clean - pulisce la directory dei sorgenti"

