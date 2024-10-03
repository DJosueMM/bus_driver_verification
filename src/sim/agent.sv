class agent # (parameter WIDTH = 16, parameter DRVS = 4);

    mbx_test_agent   test_agent_mbx;   // Mailbox del test al agente
    mbx_agent_driver agnt_drv_mbx [DRVS - 1 : 0];     // Arreglo de mailboxes del agente a cada driver
    
    int                        num_transacciones;   // Número de transacciones para las funciones del agente
    int                        max_retardo;         // Retardo máximo para las funciones del agente
    rand bit    [7 : 0]        id_spec;             // ID del driver receptor
    rand int                   driver_spec;         // Driver que envía la transacción
    tipo_trans                 tipo_spec;           // Tipo de transacción
    rand bit                   rand_reset;          // Variable para reset                  
    rand bit                   rand_broadcast;      // Variable para broadcast

    instrucciones_agente  instruccion; // para guardar la última instruccion leída
    virtual dut_compl_if #(.width(WIDTH)) vif_agnt_dut;
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion;

    constraint const_illegal_ID           {id_spec        >= DRVS; id_spec > 0;}        //constraint para que el ID sea invalido
    constraint const_legal_ID             {id_spec        <= DRVS; id_spec > 0;}        //constraint para que el ID sea valido
    constraint const_reset_dist           {rand_reset     dist {0 := 90, 1 := 10}; }    //constraint para la distribucion de reset
    constraint const_rand_broadcast       {rand_broadcast dist {0 := 25, 1 := 75}; }    //constraint para la distribucion de broadcast
    constraint const_no_reset             {tipo_spec    != reset;}                      //constraint para que no haya reset
    constraint const_no_broadcast         {tipo_spec    != broadcast;}                  //constraint para que no haya broadcast
    
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
        
                const_no_reset.constraint_mode(1);   
                const_illegal_ID.constraint_mode(0);
                const_legal_ID.constraint_mode(0);
                const_rand_broadcast.constraint_mode(0); 
                const_no_broadcast.constraint_mode(0); 
                vif_agnt_dut.reset = 0;

                case(instruccion)

                    init : begin  // Bloque de inicialización para setear todo en 0

                        // Comprobar si hay al menos un driver activo (DRVS > 0)
                        if (DRVS == 0) begin
                            // Si no hay más de un driver (DRVS == 0), imprime un mensaje de advertencia
                            transaccion.print("Solo hay un Driver, no se puede inicializar desde el agente");
                        end
                        else begin
                            // Si hay más de un driver, proceder con la creación de transacciones de inicialización
                            
                            // Crear una nueva transacción y aleatorizar sus campos
                            transaccion = new();
                            transaccion.randomize();

                            // Asignar valores específicos a los campos de la transacción
                            transaccion.pkg_payload = '0;  // Asignar 0 al payload del paquete
                            transaccion.pkg_id = '1;       // Asignar 1 al ID del paquete
                            transaccion.delay = 5;         // Asignar un retraso de 5 unidades de tiempo

                            // Establecer el tipo de transacción como broadcast
                            tipo_spec = broadcast;
                            transaccion.tipo_transaccion = tipo_spec;

                            // Imprimir los detalles de la transacción creada
                            transaccion.print("Agente: transacción de inicializacion creada");

                            // Enviar la transacción al último driver en la lista de mailboxes (agnt_drv_mbx[DRVS-1])
                            agnt_drv_mbx[DRVS-1].put(transaccion);
                            
                            // Crear y aleatorizar otra nueva transacción
                            transaccion = new();
                            transaccion.randomize();

                            // Asignar nuevamente los valores específicos a la nueva transacción
                            transaccion.pkg_payload = '0;  // Payload de 0
                            transaccion.pkg_id = '1;       // ID del paquete de 1
                            transaccion.delay = 10;        // Retraso de 10 unidades de tiempo

                            // El tipo de transacción se establece como broadcast
                            tipo_spec = broadcast;
                            transaccion.tipo_transaccion = tipo_spec;
                            
                            // Imprimir los detalles de la segunda transacción
                            transaccion.print("Agente: transacción de inicializacion creada");

                            // Enviar esta transacción al primer driver en la lista de mailboxes (agnt_drv_mbx[0])
                            agnt_drv_mbx[0].put(transaccion);
                        end
                    end


                    send_random_payload_legal_id: begin  // Esta instruccion genera transacciones aleatorias
                
                        for(int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            
                            id_spec = $urandom_range(0, DRVS - 1);  // Se elige un ID aleatorio
                            driver_spec = $urandom_range(0, DRVS - 1); 
                            transaccion.pkg_id = id_spec; // Se asigna el ID a la transacción

                            tipo_spec = send;
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción send_random_payload_legal_id creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    send_random_payload_ilegal_id: begin    // Esta instruccion genera transacciones aleatorias con ID ilegal
                 
                        for(int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            
                            id_spec = $urandom % 25;  // Se elige un ID aleatorio con posibilidad de invalido
                            driver_spec = $urandom_range(0, DRVS - 1); 
                            transaccion.pkg_id = id_spec; // Se asigna el ID a la transacción

                            tipo_spec = send;
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción send_random_payload_legal_id creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    send_w_mid_reset: begin             // Esta instruccion genera transacciones aleatorias con reset
                        const_no_reset.constraint_mode(0);   
                        const_illegal_ID.constraint_mode(0);
                        const_legal_ID.constraint_mode(0);
                        const_reset_dist.constraint_mode(1);
                        for(int i = 0; i < num_transacciones; i++) begin
                            const_illegal_ID.constraint_mode(0);
                            const_legal_ID.constraint_mode(1);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            driver_spec = $urandom_range(0, DRVS - 1);
                            rand_reset  = $urandom_range(0, 1);
                            tipo_spec = send;
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción send_w_mid_reset creada para posterior reset");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                            
                            if (rand_reset == 1) begin
                                transaccion.tipo_transaccion = reset;
                                vif_agnt_dut.reset = 1;
                            end
                            
                            else begin  
                                transaccion.tipo_transaccion = send;
                                vif_agnt_dut.reset = 0;
                            end
                            driver_spec = $urandom_range(0, DRVS - 1);
                            transaccion.print("Agente: transacción send_w_mid_reset creada como potencial reset");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    consecutive_send: begin             // Esta instruccion genera transacciones consecutivas

                        driver_spec = $urandom_range(0, DRVS - 1);                       // Se elige un driver aleatorio
                        for(int i = 0; i < num_transacciones; i++) begin
                            const_illegal_ID.constraint_mode(0);
                            const_legal_ID.constraint_mode(1);

                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            tipo_spec = send;

                            id_spec = $urandom_range(0, DRVS - 1);  // Se elige un ID aleatorio
                            transaccion.pkg_id = id_spec; // Se asigna el ID a la transacción

                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción consecutive_send creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    broadcast_random: begin        // Esta instruccion genera transacciones broadcast aleatorias

                        for(int i = 0; i < num_transacciones; i++) begin
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;

                            driver_spec = $urandom_range(0, DRVS - 1);
                            id_spec = $urandom_range(0, DRVS - 1);  // Se elige un ID aleatorio
                            transaccion.pkg_id = id_spec; // Se asigna el ID a la transacción


                            rand_broadcast = $urandom_range(0, 1);

                            if (rand_broadcast == 1) begin
                                tipo_spec = broadcast;
                                transaccion.pkg_id = '1; // Se asigna el ID a la transacción // Se asigna el ID a la transacción como broadcast
                            end
                            
                            else begin  
                                tipo_spec = send;
                            end

                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción broadcast_random creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
                        end
                    end

                    all_broadcast: begin         // Esta instruccion genera transacciones broadcast para todos los drivers

                        for(int i = 0; i < DRVS; i++) begin
                            const_illegal_ID.constraint_mode(0);
                            const_legal_ID.constraint_mode(1);
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;

                            tipo_spec = broadcast;                  // Se define el tipo de transacción
                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.pkg_id = '1; // Se asigna el ID a la transacción como broadcast

                            transaccion.print("Agente: transacción all_broadcast creada");
                            agnt_drv_mbx[i].put(transaccion);
                        end
                    end

                    some_broadcast: begin      // Esta instruccion genera transacciones broadcast aleatorias para algunos drivers
                        const_rand_broadcast.constraint_mode(1);
                        for (int i = 0; i < DRVS; i++) begin
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;

                            id_spec = $urandom_range(0, DRVS - 1);  // Se elige un ID aleatorio
                            transaccion.pkg_id = id_spec; // Se asigna el ID a la transacción

                            rand_broadcast = $urandom_range(0, 1);
                            if (rand_broadcast == 1) begin
                                tipo_spec = broadcast;
                                transaccion.pkg_id = '1; // Se asigna el ID a la transacción como broadcast
                            end
                            
                            else begin  
                                tipo_spec = send;
                            end

                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción some_broadcast creada");
                            agnt_drv_mbx[i].put(transaccion);

                        end
                    end

                    all_for_one: begin      // Esta instruccion genera transacciones para todos para un ID

                        id_spec = $urandom_range(0, DRVS - 1);
                        const_no_broadcast.constraint_mode(1); 

                        for (int i = 0; i < DRVS; i++) begin
                            transaccion = new();
                            transaccion.max_delay = max_retardo;
                            transaccion.randomize();
                            transaccion.pkg_id = id_spec;
                            transaccion.print("Agente: transacción all_for_one creada");
                            agnt_drv_mbx[i].put(transaccion);
                        end
                    end

                    all_sending_random: begin   // Esta instruccion genera transacciones aleatorias para todos los drivers

                        const_legal_ID.constraint_mode(1);
                        
                        for (int i = 0; i < DRVS; i++) begin
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            tipo_spec = send;                  // Se define el tipo de transacción

                            id_spec = $urandom_range(0, DRVS - 1);  // Se elige un ID aleatorio
                            transaccion.pkg_id = id_spec; // Se asigna el ID a la transacción

                            transaccion.tipo_transaccion = tipo_spec;
                            transaccion.print("Agente: transacción all_sending_random creada");
                            agnt_drv_mbx[i].put(transaccion);
                        end
                    end
                    
                    auto_send_random: begin     // Esta instruccion hace que se envíen transacciones a sí mismo

                        const_illegal_ID.constraint_mode(0);
                        const_legal_ID.constraint_mode(1);
                        const_reset_dist.constraint_mode(0);
                        const_no_broadcast.constraint_mode(1); 
                         
                        for (int i = 0; i < num_transacciones; i++) begin

                            driver_spec = $urandom_range(0, DRVS - 1);     
                            transaccion = new();
                            transaccion.randomize();
                            transaccion.max_delay = max_retardo;
                            id_spec = driver_spec; //revisar asignacion de int a bit
                            transaccion.pkg_id = id_spec;
                            
                            transaccion.print("Agente: transacción auto_send_random creada");
                            agnt_drv_mbx[driver_spec].put(transaccion);
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