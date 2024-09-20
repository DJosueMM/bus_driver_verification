class agent # (parameter WIDTH = 16, DRVS = 4);

    mbx_test_agent                                       test_agent_mbx;   // Mailbox del test al agente
    mbx_agent_driver_and_monitor_checker [DRVS - 1 : 0]  agnt_drv_mbx;     // Arreglo de mailboxes del agente a cada driver
    
    int                        num_transacciones;  // Número de transacciones para las funciones del agente
    int                        max_retardo;
    int                        retardo_spec;
    bit        [7 : 0]         id_spec;
    bit        [WIDTH - 9 : 0] payload_spec;
    int                        send_time_spec;
    rand int                   driver_spec;
    tipo_trans                 tipo_spec;
    rand bit                   rand_reset;                        
    rand bit                   rand_broadcast; 

    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion;

    constraint const_illegal_ID           {id_spec        >= DRVS; id_spec > 0;}     //constraint para que el ID sea invalido
    constraint const_legal_ID             {id_spec        <= DRVS; id_spec > 0;}     //constraint para que el ID sea valido
    constraint const_instrucciones_dist   {rand_reset     dist {0 := 90, 1 := 10}; } //constraint para que el driver sea valido
    constraint const_rand_broadcast       {rand_broadcast dist {0 := 25, 1 := 75}; } //constraint para que el driver sea valido
    constraint const_no_reset             {tipo_spec    != reset;}                   //constraint para que el driver sea valido
    
    function new();
        num_transacciones = 100;
        max_retardo       = 10;
    endfunction

    task run;

        $display("[%g] El Agente fue inicializado", $time);

        forever begin
            
            #1;

            if(test_agent_mbx.num() > 0) begin

                $display("[%g] Agente: recibe instruccion", $time);
                test_agent_mbx.get(instruccion);
        
                
                case(instruccion)
                    const_no_reset.constraint_mode(1);   
                    const_illegal_ID.constraint_mode(0);
                    const_legal_ID.constraint_mode(0);

                    send_random_payload_legal_id: begin // Esta instruccion genera num_tranacciones escrituras seguidas del mismo número de lecturas
                
                        for(int i = 0; i < num_transacciones; i++) begin
                            const_illegal_ID.constraint_mode(0);
                            const_legal_ID.constraint_mode(1);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            driver_spec.randomize();
                            tipo_spec = send;
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción send_random_payload_legal_id creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    send_random_payload_ilegal_id: begin // Esta instruccion genera transacciones aleatorias
                 
                        for(int i = 0; i < num_transacciones; i++) begin
                            const_illegal_ID.constraint_mode(1);
                            const_legal_ID.constraint_mode(0);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            driver_spec.randomize();
                            tipo_spec = send;
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción send_random_payload_ilegal_id creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    send_w_mid_reset: begin
                        const_no_reset.constraint_mode(0);   
                        const_illegal_ID.constraint_mode(0);
                        const_legal_ID.constraint_mode(0);
                        const_instrucciones_dist.constraint_mode(1);
                        for(int i = 0; i < num_transacciones; i++) begin
                            const_illegal_ID.constraint_mode(0);
                            const_legal_ID.constraint_mode(1);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            driver_spec.randomize();
                            tipo_spec = send;
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción send_w_mid_reset creada para posterior reset");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                            
                            if (rand_reset == 1) begin
                                transaccion.tipo_transaccion = reset;
                            end
                            
                            else begin  
                                transaccion.tipo_transaccion = send;
                            end
                            driver_spec.randomize();
                            transaccion.print("Agente: transacción send_w_mid_reset creada como potencial reset");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    consecutive_send: begin 
                        driver_spec.randomize();                        // Se elige un driver aleatorio
                        for(int i = 0; i < num_transacciones; i++) begin
                            const_illegal_ID.constraint_mode(0);
                            const_legal_ID.constraint_mode(1);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción send_random_payload_legal_id creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    broadcast_random: begin 
                        const_illegal_ID.constraint_mode(0);
                        const_legal_ID.constraint_mode(0);
                        const_instrucciones_dist.constraint_mode(0);
                        for(int i = 0; i < num_transacciones; i++) begin
                            const_legal_ID.constraint_mode(1);
                            const_rand_broadcast.constraint_mode(1);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            driver_spec.randomize();

                            if (rand_broadcast == 1) begin
                                tipo_spec = broadcast;
                            end
                            
                            else begin  
                                tipo_spec = send;
                            end

                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción broadcast_random creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    all_broadcast: begin 
                        const_illegal_ID.constraint_mode(0);
                        const_legal_ID.constraint_mode(0);
                        const_instrucciones_dist.constraint_mode(0);
                        for(int i = 0; i < DRVS; i++) begin
                            const_illegal_ID.constraint_mode(0);
                            const_legal_ID.constraint_mode(1);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            tipo_spec = broadcast;                  // Se define el tipo de transacción
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción all_broadcast creada");
                            agnt_drv_mbx[i].put(transaccion);
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

                    some_sending_random: begin 
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


                    auto_send_random: begin 
                        for (int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.max_retardo = max_retardo;
                            transaccion.randomize();
                            transaccion.print("Agente: transacción creada");
                            agnt_drv_mbx.put(transaccion);
                        end
                    end
                    default: begin
                        $display("[%g] Agente: instrucción no reconocida", $time);
                    end
                endcase
            end
        end
    endtask
endclass