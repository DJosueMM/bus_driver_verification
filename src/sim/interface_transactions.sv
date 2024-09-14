
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

