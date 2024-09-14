
//Definicion de tipos de datos

////////////////////////////////////////
// Definición de estructura para generar comandos hacia el agente //
////////////////////////////////////////
typedef enum {

    send_random_payload_legal_id,
    send_random_payload_ilegal_id,
    send_w_mid_reset,
    consecutive_send,
    broadcast_random,
    some_sending_random,
    some_broadcast,
    all_for_one,
    all_sending_random,
    all_broadcast,
    auto_send_random

} instrucciones_agente;

////////////////////////////////////////
// Definición de estructura para generar comandos hacia el driver //
////////////////////////////////////////
typedef enum {

    send,
    reset

} instrucciones_driver;


////////////////////////////////////////
// Definición de estructura para generar comandos hacia el scoreboard //
////////////////////////////////////////
typedef enum {

    pkg_rx,
    pkg_tx,
    avg_delay,
    total_avg_delay,
    total_transactions,
    broadcast_report,
    result_condition,
    total_report
    
} consulta_sb;

class intrucciones_monitor;

    // Definición de los miembros de la clase
    rand int         max_delay;         // Tiempo máximo de retraso en ciclos de reloj
    rand int         delay;             // Retraso en ciclos de reloj
    rand bit         pkg;               // Paquete de datos (ajustar el tamaño según sea necesario)
    int              send_time;         // Tiempo en el que se envió el paquete
    int              receive_time;      // Tiempo en el que se recibió el paquete
    int              dest;              // Destino del paquete
    int              receiver_monitor;  // Monitor receptor del paquete
    rand int         id;                // Identificador de la transacción
    rand bit         payload;           // Payload de la transacción (ajustar el tamaño según sea necesario)

    // Restricciones (si fueran necesarias)
    // constraint const_delay {
    //     delay < max_delay;
    //     delay >= 0;
    // }

    // Constructor por defecto
    function new(int max_d = 0, int d = 0, bit[7:0] pkg = 0, int st = 0, int rt = 0, string dst = "", string rcv_mtr = "", int i = 0, bit[15:0] pl = 0);
        this.max_delay          = max_d;
        this.delay              = d;
        this.pkg                = pkg;
        this.send_time          = st;
        this.receive_time       = rt;
        this.dest               = dst;
        this.receiver_monitor   = rcv_mtr;
        this.id                 = i;
        this.payload            = pl;
    endfunction

    // Método para limpiar los valores
    function void clean;
        this.max_delay          = 0;
        this.delay              = 0;
        this.pkg                = 0;
        this.send_time          = 0;
        this.receive_time       = 0;
        this.dest               = 0;
        this.receiver_monitor   = 0;
        this.id                 = 0;
        this.payload            = 0;
    endfunction

    // Método para imprimir los valores
    function void print(string tag = "");
        $display("[%g] %s Max Delay=%d Delay=%d pkg=0x%h Send Time=%d Receive Time=%d Dest=%d Receiver Monitor=%d ID=%d Payload=0x%h", 
                 $time, tag, max_delay, delay, pkg, send_time, receive_time, dest, receiver_monitor, id, payload);
    endfunction

endclass


//Definicion de mailboxes

////////////////////////////////////////
// Definición de mailboxes de tipo definido instrucciones_agente para comunicar las interfaces //
////////////////////////////////////////
typedef mailbox # (instrucciones_agente) mbx_test_agent;

////////////////////////////////////////
// Definición de arreglo de mailboxes de tipo definido instrucciones_driver para comunicar las interfaces //
////////////////////////////////////////
typedef mailbox # (instrucciones_driver) mbx_agent_driver;

////////////////////////////////////////
// Definición de arreglo de mailboxes de tipo definido instrucciones_monitor para comunicar las interfaces //
////////////////////////////////////////
typedef mailbox # (instrucciones_monitor) mbx_monitor_checker;

////////////////////////////////////////
// Definición de arreglo de mailboxes de tipo definido res_check para comunicar las interfaces //
////////////////////////////////////////
typedef mailbox # (res_check) mbx_checker_sb;

////////////////////////////////////////
// Definición de arreglo de mailboxes de tipo definido consulta_sb para comunicar las interfaces //
////////////////////////////////////////
typedef mailbox # (consulta_sb) mbx_test_sb;

