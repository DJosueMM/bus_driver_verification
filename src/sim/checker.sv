class checker #(parameter WIDTH = 16, parameter DRVS = 8);  // Clase checker con parámetros WIDTH y DRVS

    // Variables de transacciones para recibir del driver y monitor, y una auxiliar para guardar temporalmente
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_drv_received;   // Transacción recibida del driver
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_mnt_received;   // Transacción recibida del monitor
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_to_sb;          // Auxiliar para almacenar transacción para sb
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) revisando;                  // Auxiliar para revisar transacciones

    // Mailboxes para la comunicación entre drivers, monitores, y checker
    mbx_driver_checker  driver_checker_mbx [DRVS - 1 : 0];  // Mailbox del driver al checker (uno por driver)
    mbx_monitor_checker mnt_checker_mbx    [DRVS - 1 : 0];  // Mailbox del monitor al checker (uno por monitor)
    mbx_checker_sb      checker_sb_mbx;                     // Mailbox para enviar la transacción al scoreboard

    // Crear FIFOs para almacenar las transacciones recibidas de los drivers
    instrucciones_driver_monitor#(.WIDTH(WIDTH)) driver_fifo [$]; // Arreglo dinámico como FIFO de transacciones de drivers
  
    // Definición de la interfaz virtual conectada al DUT (device under test)
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_checker_fifo_dut;

    // Variables para almacenar los campos de las transacciones recibidas del monitor
    bit [7 : 0]         pkg_id_mnt;          // ID del paquete recibido del monitor
    bit [WIDTH - 9 : 0] pkg_payload_mnt;     // Payload del paquete recibido del monitor
    int                 rcv_mnt_mnt;         // Identificador del monitor que recibe la transacción
    tipo_trans          tipo_transaccion_mnt; // Tipo de transacción recibida del monitor

    // Variables auxiliares para control de flujo
    bit match_found;          // Bandera para indicar si se encontró una coincidencia
    bit success_get_driver;   // Indica si se recibió una transacción del driver exitosamente
    bit success_get_monitor;  // Indica si se recibió una transacción del monitor exitosamente

    // Constructor: inicializa las variables
    function new();
        this.pkg_id_mnt = '0;
        this.pkg_payload_mnt = '0;
        this.rcv_mnt_mnt = 0;
        this.tipo_transaccion_mnt = '0;

        this.match_found = 0;
        this.success_get_driver = 0;
        this.success_get_monitor = 0;
    endfunction

    // Método principal para ejecutar la verificación
    task run();

        // Imprimir un mensaje de inicio
        $display("[%g] El checker fue inicializado", $time);
        
        // Bucle infinito para monitorear y verificar continuamente las transacciones
        forever begin
            @(posedge vif_checker_fifo_dut.clk);  // Esperar el flanco positivo del reloj
            this.match_found = 0;  // Reiniciar el indicador de coincidencia
            this.pkg_id_mnt = '0;  // Resetear las variables de las transacciones del monitor
            this.pkg_payload_mnt = '0;
            this.rcv_mnt_mnt = 0;
            this.tipo_transaccion_mnt = '0;
            this.success_get_driver = 0;
            this.success_get_monitor = 0;

            // Iterar sobre los drivers para intentar recibir transacciones
            for (int i = 0; i < DRVS; i++) begin
                
                // Intentar obtener una transacción desde el driver
                this.success_get_driver = driver_checker_mbx[i].try_get(transaccion_drv_received);
                
                // Intentar obtener una transacción desde el monitor
                this.success_get_monitor = mnt_checker_mbx[i].try_get(transaccion_mnt_received);
                
                // Si se recibió una transacción del driver, se almacena en la FIFO
                if (this.success_get_driver) begin
                    driver_fifo.push_front(transaccion_drv_received);  // Añadir transacción a la FIFO
                    $display("Se añadió una transacción a la FIFO del Driver[%0d]", i);
                    transaccion_drv_received.print("Checker: Se recibe transacción desde el driver");
                end

                // Si se recibió una transacción del monitor, se procede a verificar
                if (this.success_get_monitor) begin
                    // Guardar campos relevantes de la transacción del monitor para la verificación
                    $display("Checker: se obtuvo una transacion del Monitor[%0d]", i);
                    this.pkg_id_mnt           = transaccion_mnt_received.pkg_id;
                    this.pkg_payload_mnt      = transaccion_mnt_received.pkg_payload;
                    this.rcv_mnt_mnt          = transaccion_mnt_received.receiver_monitor;
                    this.tipo_transaccion_mnt = transaccion_mnt_received.tipo_transaccion;

                    transaccion_mnt_received.print("Checker: revisando MONITOR contra transacciones");

                    // Verificar la transacción del monitor contra todas las transacciones de los drivers en la FIFO
                    foreach (driver_fifo[w]) begin
                        revisando = new();  // Crear una instancia temporal para revisar
                        revisando = driver_fifo[w];  // Acceder a la transacción en la posición w de la FIFO
                        revisando.print("Checker: revisando transacción en la FIFO");

                        // Imprimir detalles de las transacciones a comparar
                        $display("revisando.pkg_id [%g] revisando.pkg_payload [%g] revisando.receiver_monitor [%g] revisando.tipo_transaccion [%p]", 
                                  revisando.pkg_id, revisando.pkg_payload, revisando.receiver_monitor, revisando.tipo_transaccion);
                        $display("this.pkg_id_mnt [%g] this.pkg_payload_mnt [%g] this.rcv_mnt_mnt [%g] this.tipo_transaccion_mnt [%p]", 
                                  this.pkg_id_mnt, this.pkg_payload_mnt, this.rcv_mnt_mnt, this.tipo_transaccion_mnt);

                        $display("[%g] Checker: revisando coincidencia de transacción recibida en el monitor con la transacción [%g]", $time, w);

                        // Verificación para transacciones de tipo broadcast
                        if (this.tipo_transaccion_mnt == broadcast) begin 
                            if (this.pkg_id_mnt == revisando.pkg_id && this.pkg_payload_mnt[7 : 0] == revisando.pkg_payload[7 : 0] &&
                                this.tipo_transaccion_mnt == revisando.tipo_transaccion) begin
                                // Coincidencia encontrada: reconstruir y enviar al scoreboard
                                $display ("[%g] Checker: las transacciones coinciden", $time);
                                this.match_found = 1;
                                transaccion_to_sb = new();
                                transaccion_to_sb.max_delay        = transaccion_drv_received.max_delay;
                                transaccion_to_sb.delay            = transaccion_drv_received.delay;
                                transaccion_to_sb.pkg_id           = this.pkg_id_mnt;
                                transaccion_to_sb.pkg_payload      = this.pkg_payload_mnt;
                                transaccion_to_sb.send_time        = transaccion_drv_received.send_time;
                                transaccion_to_sb.receive_time     = transaccion_mnt_received.receive_time;
                                transaccion_to_sb.receiver_monitor = this.rcv_mnt_mnt;
                                transaccion_to_sb.tipo_transaccion = this.tipo_transaccion_mnt;

                                transaccion_to_sb.print("Checker: transacción completa reconstruida");
                                checker_sb_mbx.put(transaccion_to_sb);  // Enviar transacción al scoreboard
                                $display ("[%g] Checker: transacción enviada al sb", $time);
                                break;
                            end
                        end
                        else begin
                            // Verificación para transacciones no-broadcast
                            if (this.pkg_id_mnt == revisando.pkg_id && this.pkg_payload_mnt[7 : 0] == revisando.pkg_payload[7 : 0] &&
                                this.rcv_mnt_mnt == revisando.receiver_monitor && this.tipo_transaccion_mnt == revisando.tipo_transaccion) begin
                                // Coincidencia encontrada: reconstruir y enviar al scoreboard
                                $display ("[%g] Checker: las transacciones coinciden", $time);
                                this.match_found = 1;
                                transaccion_to_sb = new();
                                transaccion_to_sb.max_delay        = transaccion_drv_received.max_delay;
                                transaccion_to_sb.delay            = transaccion_drv_received.delay;
                                transaccion_to_sb.pkg_id           = this.pkg_id_mnt;
                                transaccion_to_sb.pkg_payload      = this.pkg_payload_mnt;
                                transaccion_to_sb.send_time        = transaccion_drv_received.send_time;
                                transaccion_to_sb.receive_time     = transaccion_mnt_received.receive_time;
                                transaccion_to_sb.receiver_monitor = this.rcv_mnt_mnt;
                                transaccion_to_sb.tipo_transaccion = this.tipo_transaccion_mnt;

                                transaccion_to_sb.print("Checker: transacción completa reconstruida");
                                checker_sb_mbx.put(transaccion_to_sb);  // Enviar transacción al scoreboard
                                $display ("[%g] Checker: transacción enviada al sb", $time);
                                break;
                            end
                        end
                    end

                    // Si no se encontró coincidencia, reportar un error
                    if (this.match_found == 0) begin
                        $display ("[%g] ERROR Checker: no se encontró coincidencia para la transacción del monitor", $time);
                        $finish;
                    end
                end
            end
        end
    endtask
endclass
