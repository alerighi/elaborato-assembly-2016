# File: syscall.inc
# Autore: Alessandro Righi
# Data: 29/06/16
# Descrizione: file che contiene utili macro per le syscall

# macro per il numero delle syscall
sys_exit = 1
sys_read = 3
sys_write = 4
sys_open = 5
sys_close = 6

# macro per i file descriptor principali
stdin = 0
stdout = 1
stderr = 2

# macro per sys_open
O_READONLY = 0
O_WRITEONLY_AND_CREATE_AND_TRUNCATE = 01101

# macro per sys_exit
EXIT_SUCCESS = 0
EXIT_ERROR = 1

# macro per l'esecuzione di una syscall
SYSCALL = 0x80
