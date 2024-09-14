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
// Definición del tipo de transacciones posibles en los drivers //
////////////////////////////////////////
typedef enum {

    send,
    broadcast,
    reset

} tipo_trans;


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

// Clase para definir los datos que maneja y sus detalles las instrucciones driver_monitor
// estos tipos de datos se transmiten desde el agente al driver_monitor y desde el driver_monitor al checker
class instrucciones_driver_monitor # (parameter WIDTH = 16); 

    // Definición de los miembros de la clase
    rand int                 max_delay;         // Tiempo máximo de retraso en ciclos de reloj
    rand int                 delay;             // Retraso en ciclos de reloj
    rand bit [7 : 0]         pkg_id;            // ID del paquete de datos (ajustar el tamaño según sea necesario)
    rand bit [WIDTH - 1 : 0] pkg_payload;       // ID del paquete de datos (ajustar el tamaño según sea necesario)
    int                      send_time;         // Tiempo en el que se envió el paquete
    int                      receive_time;      // Tiempo en el que se recibió el paquete
    int                      receiver_monitor;  // Monitor receptor del paquete
    rand tipo_trans          tipo_transaccion;  //Tipo de transaccion declarado tipo_trans
   
   //Constraint de retardo
    constraint const_delay {
        max_delay <= 5;         //Retardo maximo al randomizar, VERIFICAR
        delay     <  max_delay; //Definir cotas del delay
        delay     >= 0;
    }
    
    //Constraint id if broadcast
    constraint const_broad {

        if (tipo_transaccion == broadcast) begin //Definir el ID correcto en caso de randomizar 
            pkg_id = 8'b11111111;                //en operacion de broadcast
        end

        else;
    }

    // Constructor por defecto
    function new(int max_d = 0, int d = 0, bit[7 : 0] id = '0, int [WIDTH - 1 : 0] payload = '0, int st = 0, int rt = 0, int rcv_mtr = 0, tipo_trans tipo = send);
        this.max_delay        = max_d;
        this.delay            = d;
        this.pkg_id           = id;
        this.pkg_payload      = payload;
        this.send_time        = st;
        this.receive_time     = rt;
        this.receiver_monitor = rcv_mtr;
        this.tipo_transaccion = tipo;
    endfunction

    // funcion para limpiar los valores
    function void clean;
        this.max_delay        = 0;
        this.delay            = 0;
        this.pkg_id           = 0;
        this.pkg_payload      = 0;
        this.send_time        = 0;
        this.receive_time     = 0;
        this.receiver_monitor = 0;
        this.tipo_transaccion = 0;

    endfunction

    // funcion para imprimir los valores de los datos en la clase y transaccionS
    function void print(string tag = ""); //este tag se inicializa al llamar a la funcion
        $display("[%g] %s Max Delay=%d Delay=%d pkg_id=0x%h pkg_payload=0x%h Send_Time=%d Receive_Time=%d Receiver Monitor=%d Tipo=0x%p", 
                 $time, tag, max_delay, delay, pkg_id, pkg_payload, send_time, receive_time, receiver_monitor, tipo_transaccion);
    endfunction

endclass

//Definicion de mailboxes

////////////////////////////////////////
// Definición de mailboxes de tipo definido instrucciones_agente para comunicar las interfaces TEST -> AGENTE 
////////////////////////////////////////
typedef mailbox # (instrucciones_agente) mbx_test_agent;


////////////////////////////////////////
// Definición de arreglo de mailboxes de tipo definido instrucciones_driver para comunicar las interfaces 
//                                                                       AGENTE         -> DRIVER_MONITOR 
//                                                                       DRIVER_MONITOR -> CHECKER
////////////////////////////////////////                                 
typedef mailbox # (instrucciones_driver_monitor) mbx_agent_driver_and_monitor_checker; 
//Usamos el mismo mailbox para que sea el mismo dato que se modifique tanto en el monitor como en el driver
//asi solo se acceden a los elementos necesarios en cada etapa de las transacciones


////////////////////////////////////////
// Definición de arreglo de mailboxes de tipo definido res_check para comunicar las interfaces CHECKER -> SCOREBOARD 
////////////////////////////////////////
typedef mailbox # (res_check) mbx_checker_sb;


////////////////////////////////////////
// Definición de arreglo de mailboxes de tipo definido consulta_sb para comunicar las interfaces TEST -> SCOREBOARD 
////////////////////////////////////////
typedef mailbox # (consulta_sb) mbx_test_sb;

