class checker #(parameter WIDTH = 16, parameter DRVS = 8);

    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_drv_received;   // Transacción recibida del driver
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_mnt_received;   // Transacción recibida del monitor
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_to_sb;          // Auxiliar para guardar transacciones temporales
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) revisando;
    
    mbx_driver_checker  driver_checker_mbx [DRVS - 1 : 0];  // Mailbox del driver al checker
    mbx_monitor_checker mnt_checker_mbx    [DRVS - 1 : 0];  // Mailbox del monitor al checker
    mbx_checker_sb      checker_sb_mbx;

    // Crear FIFOs para cada mailbox
    instrucciones_driver_monitor#(.WIDTH(WIDTH)) driver_fifo [$]; // FIFOs para los drivers
  
    // Definición de la interface a la que se conectará el DUT
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_checker_fifo_dut;

    bit [7 : 0]         pkg_id_mnt;
    bit [WIDTH - 9 : 0] pkg_payload_mnt;
    int                 rcv_mnt_mnt;
    tipo_trans          tipo_transaccion_mnt;

    bit match_found;
    bit success_get_driver;
    bit success_get_monitor;

    // Constructor
    function new();
        this.pkg_id_drv = '0;
        this.pkg_payload_drv = '0;
        this.rcv_mnt_drv = 0;
        this.tipo_transaccion_drv = '0;

        this.pkg_id_mnt = '0;
        this.pkg_payload_mnt = '0;
        this.rcv_mnt_mnt = 0;
        this.tipo_transaccion_mnt = '0;

        this.match_found = 0;
        this.success_get_driver = 0;
        this.success_get_monitor = 0;
    endfunction

    // Método para verificar transacciones
    task run();

        $display("[%g] El checker fue inicializado", $time);
        
        // Bucle infinito para reiniciar el proceso de verificación
        forever begin

            
            @(posedge vif_checker_fifo_dut.clk);
            // Iterar sobre todas las transacciones de los drivers
            this.match_found = 0;  // Reiniciar indicador de coincidencia
            for (int i = 0; i < DRVS; i++) begin
                
                this.success_get_driver = driver_checker_mbx[i].try_get(transaccion_drv_received);  // Intentar recibir la transacción del driver
                this.success_get_monitor = mnt_checker_mbx[i].try_get(transaccion_mnt_received);  // Intentar recibir la transacción del monitor
                
                if (this.success_get_driver) begin
                    // Añadir la transacción recibida a la FIFO correspondiente
                    driver_fifo.push_back(transaccion_drv_received);
                    $display("Se añadió una transacción a la FIFO del Driver[%0d]", i);

                    transaccion_drv_received.print("Checker: Se recibe transacción desde el driver");
                end

                if (this.success_get_monitor) begin

                    // Añadir la transacción recibida a la FIFO correspondiente
                    $display("Checker: se obtuvo una transacion del Monitor[%0d]", i);
                    //se obtienen los campos a buscar en transacciones realizadas por los drivers
                    this.pkg_id_mnt           = transaccion_mnt_received.pkg_id;
                    this.pkg_payload_mnt      = transaccion_mnt_received.pkg_payload;
                    this.rcv_mnt_mnt          = transaccion_mnt_received.receiver_monitor;
                    this.tipo_transaccion_mnt = transaccion_mnt_received.tipo_transaccion;
                    
                    foreach (driver_fifo[w]) begin

                        this.match_found = 0;
                        // Acceder al elemento en la posición w de la cola
                        revisando = new();
                        revisando = driver_fifo[w];
                        $display("[%g] Checker: revisando coincidencia de transaccion recibida en el monitor con la transaccion [%g]", $time, w)
                        if (this.pkg_id_mnt == revisando.pkg_id && this.pkg_payload_mnt == revisando.pkg_payload && 
                            this.rcv_mnt_mnt == revisando.receiver_monitor && this.tipo_transaccion_mnt == revisando.tipo_transaccion) begin
                        
                            $display ("[%g] Checker: las transacciones coinciden", $time)
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
    
                            transaccion_to_sb.print("Checker: transaccion completa reconstruida");
                            checker_sb_mbx.put(transaccion_to_sb);
                            $display ("[%g] Checker: transaccion enviada al sb", $time)
                            driver_fifo.delete(w);
                            break;
                        end
                    end

                    if (this.match_found == 0) begin
                        $display ("[%g] ERROR Checker: las transaccion recibida no coincide con ninguna enviada", $time)
                    end
                end
            end
        end
    endtask
endclass
