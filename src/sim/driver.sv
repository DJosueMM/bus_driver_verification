class driver # (parameter WIDTH = 16, parameter DRVS = 8);

    // Mailboxes para comunicación entre agente, driver y checker
    mbx_agent_driver   agnt_drv_mbx;     
    mbx_driver_checker drv_chkr_mbx;
    int                drv_id;  // Identificador del driver
    
    // Interfaz virtual con el DUT 
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_driver_fifo_dut;

    // FIFO para almacenar las transacciones entrantes
    logic [WIDTH - 1 : 0] fifo_in [$];
    logic [7 : 0]         current_pkg_id;     // ID del paquete actual
    logic [WIDTH - 9 : 0] current_payload;    // Payload del paquete actual
    logic [WIDTH - 1 : 0] current_data_tx;    // Datos a transmitir

    int espera;  // Contador de espera

    // Constructor para inicializar el driver con un ID opcional
    function new(int driver_id = 0);
        this.drv_id = driver_id;
    endfunction

    // Tarea principal que define el comportamiento del driver
    task run();
        
        // Mostrar un mensaje indicando que el driver ha sido inicializado
        $display("[%g] El driver [%g] fue inicializado", $time, drv_id);
        
        // Esperar al flanco positivo del reloj
        @(posedge vif_driver_fifo_dut.clk);
        
        // Comenzar un bucle infinito para recibir y procesar transacciones
        forever begin

            // Definir la transacción de envío
            instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_send;
            vif_driver_fifo_dut.pndng [0][drv_id] = '0;  // Inicializar la señal de "pendiente"
            vif_driver_fifo_dut.pop   [0][drv_id] = '0;  // Inicializar la señal de "pop"
            vif_driver_fifo_dut.D_pop [0][drv_id] = '0;  // Inicializar la señal de datos a ser extraídos

            $display("[ %g ] El Driver [%g] espera por una transacción", $time, drv_id);

            espera = 0;  // Inicializar el contador de espera
            
            // Esperar por una transacción desde el agente
            @(posedge vif_driver_fifo_dut.clk); begin
                agnt_drv_mbx.get(transaction_send);  // Obtener la transacción desde el mailbox del agente
                transaction_send.print("Driver: Transacción recibida en el driver");
                $display("[%g] Transacciones pendientes en el mbx agnt_drv [%g] = %g", $time, drv_id, agnt_drv_mbx.num());
            end

            // Esperar el tiempo de retraso especificado en la transacción
            while (espera < transaction_send.delay) begin
                @(posedge vif_driver_fifo_dut.clk); begin
                    espera = espera + 1;
                end
            end

            // Procesar la transacción basada en su tipo (send, broadcast, reset)
            case (transaction_send.tipo_transaccion)

                send: begin
                    // Flanco positivo del reloj para procesar la transacción de tipo "send"
                    @(posedge vif_driver_fifo_dut.clk); begin

                        // Preparar los datos para transmitir al DUT
                        this.current_payload = transaction_send.pkg_payload;
                        this.current_pkg_id = transaction_send.pkg_id;
                        this.current_data_tx = {current_pkg_id, current_payload};

                        // Insertar los datos en la FIFO de entrada
                        fifo_in.push_front(this.current_data_tx);
                        
                        // Mostrar los valores de la transacción en la consola
                        $display("pkg_payload[%h]", transaction_send.pkg_payload);
                        $display("pkg_id[%h]", transaction_send.pkg_id);
                        $display("pkg_payload[%h]", current_payload);
                        $display("pkg_id[%h]", current_pkg_id);
                        $display("current_data_tx[%h]", current_data_tx);

                        transaction_send.print("Driver: Transacción send enviada a la FIFO de entrada");
    
                        // Comprobar si hay datos pendientes en la FIFO
                        if (fifo_in.size() == 0)
                            vif_driver_fifo_dut.pndng[0][drv_id] = 0;
                        else
                            vif_driver_fifo_dut.pndng[0][drv_id] = 1;

                        // Conectar los datos de la FIFO con el DUT a través de la interfaz
                        vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                        
                        // Esperar a que el DUT esté listo para extraer los datos
                        while (vif_driver_fifo_dut.pop [0][drv_id] == 0) begin
                            @(posedge vif_driver_fifo_dut.clk);
                        end
                         
                        // Enviar los datos al DUT
                        if (vif_driver_fifo_dut.pop[0][drv_id] == 1) begin
                            vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                            transaction_send.send_time = $time;
                            transaction_send.receiver_monitor = transaction_send.pkg_id;
                            transaction_send.pkg_payload = transaction_send.pkg_payload;
                            transaction_send.tipo_transaccion = transaction_send.tipo_transaccion;
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada");
                            drv_chkr_mbx.put(transaction_send);  // Enviar la transacción al checker
                            $display("[ %g ] El Driver [%g] envio la transaccion al checker", $time, drv_id);
                            fifo_in.pop_back();  // Eliminar los datos de la FIFO
                        end
                        else begin
                            transaction_send.print("Driver: Transacción esperando en la fifo de entrada el pop del DUT");
                        end
                    end                
                end  

                broadcast: begin
                    // Proceso similar al caso "send", pero para transacciones de tipo "broadcast"
                    @(posedge vif_driver_fifo_dut.clk); begin
                        this.current_payload = transaction_send.pkg_payload;
                        this.current_pkg_id = transaction_send.pkg_id;
                        this.current_data_tx = {current_pkg_id, current_payload};
                        fifo_in.push_front(this.current_data_tx);
                        
                        $display("pkg_payload[%h]", transaction_send.pkg_payload);
                        $display("pkg_id[%h]", transaction_send.pkg_id);
                        $display("pkg_payload[%h]", current_payload);
                        $display("pkg_id[%h]", current_pkg_id);
                        $display("current_data_tx[%h]", current_data_tx);

                        transaction_send.print("Driver: Transacción send enviada a la FIFO de entrada");
    
                        if (fifo_in.size() == 0)
                            vif_driver_fifo_dut.pndng[0][drv_id] = 0;
                        else
                            vif_driver_fifo_dut.pndng[0][drv_id] = 1;

                        vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                        
                        while (vif_driver_fifo_dut.pop [0][drv_id] == 0) begin
                            @(posedge vif_driver_fifo_dut.clk);
                        end
                         
                        if (vif_driver_fifo_dut.pop[0][drv_id] == 1) begin
                            vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                            transaction_send.send_time = $time;
                            transaction_send.receiver_monitor = transaction_send.pkg_id;
                            transaction_send.pkg_payload = transaction_send.pkg_payload;
                            transaction_send.tipo_transaccion = transaction_send.tipo_transaccion;
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada");
                            drv_chkr_mbx.put(transaction_send);
                            $display("[ %g ] El Driver [%g] envio la transaccion al checker", $time, drv_id);
                            fifo_in.pop_back();
                        end
                        else begin
                            transaction_send.print("Driver: Transacción esperando en la fifo de entrada el pop del DUT");
                        end
                    end                
                end  

                reset: begin
                    // En caso de reset, se elimina el contenido de la FIFO de entrada
                    fifo_in.delete();
                    transaction_send.print("Driver: Transacción reset ejecutada");
                    $display("Driver: FIFO de entrada limpiada en reset");
                end
 
                default: begin
                    // Si la transacción no tiene un tipo válido, se muestra un error y se detiene la simulación
                    $display("[%g] Driver Error: la transacción recibida no tiene tipo válido", $time);
                    $finish;
                end
            endcase
        end
    endtask
endclass
