class agent # (parameter WIDTH = 16, DRVS = 4);

    mbx_test_agent                                       test_agent_mbx;   // Mailbox del test al agente
    mbx_agent_driver_and_monitor_checker [DRVS - 1 : 0]  agnt_drv_mbx;     // Arreglo de mailboxes del agente a cada driver
    
    int                        num_transacciones;  // Número de transacciones para las funciones del agente
    int                        max_retardo;
    int                        retardo_spec;
    bit        [7 : 0]         id_spec;
    bit        [WIDTH - 9 : 0] payload_spec;
    int                        send_time_spec;
    tipo_trans                 tipo_spec;
 
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion;

    function new();
        num_transacciones = 2;
        max_retardo       = 5;
    endfunction

    task run;

        $display("[%g] El Agente fue inicializado", $time);

        forever begin
            
            #1;

            if(test_agent_mbx.num() > 0) begin

                $display("[%g] Agente: recibe instruccion", $time);
                test_agent_mbx.get(instruccion);

                case(instruccion)

                    send_random_payload_legal_id: begin // Esta instruccion genera num_tranacciones escrituras seguidas del mismo número de lecturas
                        for(int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.randomize();
                            tpo_spec = escritura;
                            transaccion.tipo = tpo_spec;
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end

                         //////////////////////////////////////////////////
                        /////Instruccion de escritura lectura simultanea a alto nivel
                        /////////////////////////////////////////////////////////////////

                        for(int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            tpo_spec = escritura_lectura;
                            transaccion.tipo = tpo_spec;
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    send_random_payload_ilegal_id: begin // Esta instruccion genera transacciones aleatorias
                        transaccion = new();
                        transaccion.max_retardo = max_retardo;
                        transaccion.randomize();
                        transaccion.print("Agente: transacción creada");
                        agnt_drv_mbx.put(transaccion);
                    end

                    send_w_mid_reset: begin
                        transaccion = new();
                        transaccion.tipo = tpo_spec;
                        transaccion.dato = dto_spec;
                        transaccion.retardo = ret_spec;
                        transaccion.print("Agente: transacción creada");
                        agnt_drv_mbx.put(transaccion);
                    end

                    consecutive_send: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    broadcast_random: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    some_sending_random: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    some_broadcast: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    all_for_one: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    all_sending_random: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    all_broadcast: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end

                    auto_send_random: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end
                endcase
            end
        end
    endtask
endclass