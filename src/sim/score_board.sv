class score_board #(parameter width = 16, parameter DRVS = 4);

    // Mailboxes para la comunicación
    mbx_checker_sb chkr_sb_mbx;      // Mailbox para recibir transacciones del monitor
    mbx_test_sb    test_sb_mbx;      // Mailbox para recibir comandos del test

    // Interfaz del scoreboard
    virtual dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) vif_sb_fifo_dut;

    consulta_sb consulta_test_sb; // Transacción recibida

    int transacciones_completadas = 0;  
    int instr_broadcast = 0;               
    int instr_send = 0;                    
    int latencia = 0;  
    int total_avg_delay = 0;                    
    int clk_cycles = 0;
    int time_elapsed = 0;
    logic [31 : 0] avr_delay_terminal [DRVS - 1 : 0];

    integer csv_file;      //CSV

    task run();
        // Abrir el archivo CSV para escritura
        csv_file = $fopen("scoreboard_report.csv", "w");
        if (!csv_file) begin
            $error("No se pudo abrir el archivo CSV para escritura");
            return;
        end
        
        // Escribir la cabecera del CSV
        $fdisplay(csv_file, "Tiempo, Transacciones_Completadas, Instr_Broadcast, Instr_Send, Latencia, Total_avg_Delay, Clk_Cycles, Time_elapsed, Monitor_Terminal, Delay_Terminal");

        $display("[%g] El Score Board fue inicializado", $time); // Mensaje de inicialización
  
        forever begin

            @(posedge vif_sb_fifo_dut.clk); // Esperar al flanco positivo del reloj
            clk_cycles ++;
            time_elapsed = clk_cycles * 20;
            instrucciones_driver_monitor #(.WIDTH(width)) complete_transaction;
      
            // Procesar transacciones en el mailbox del scoreboard
            if (chkr_sb_mbx.num() > 0) begin
                chkr_sb_mbx.get(complete_transaction); // Obtener la transacción del mailbox
                $display("[%g] SB recibe una transaccion del Checker", $time);
                
                transacciones_completadas ++;
                avr_delay_terminal[complete_transaction.receiver_monitor] = complete_transaction.receive_time - complete_transaction.send_time; // Calcular latencia
                latencia = complete_transaction.receive_time - complete_transaction.send_time;     
                total_avg_delay = (total_avg_delay +  latencia) / transacciones_completadas; 

                if (complete_transaction.tipo_transaccion == broadcast) 
                    instr_broadcast ++;
                else begin 
                    
                    if (complete_transaction.tipo_transaccion == send)
                        instr_send++
                end
                
                
                $display("[%g] Latencia promedio %0d", $time, total_avg_delay);
                $display("[%g] Transacciones Completadas %0d", $time, transacciones_completadas);
                $display("[%g] Broadcast Completados %0d", $time, instr_broadcast);
                $display("[%g] Send Completados %0d", $time, instr_send)

                // Escribir los datos de la transacción actual en el archivo CSV
                $fdisplay(csv_file, "%g,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",
                            transacciones_completadas, instr_broadcast,
                            instr_send, tlatencia,
                            total_avg_delay, clk_cycles,time_elapsed, complete_transaction.receiver_monitor, avr_delay_terminal[complete_transaction.receiver_monitor] );

            // Procesar el mailbox de comandos del test
                test_sb_mbx.tryget(consulta_test_sb); // Obtener la transacción del mailbox
                
                case (consulta_test_sb)

                    transacciones_completadas: begin
                        // Código para procesar las transacciones completadas
                        $display("Procesando: Transacciones Completadas \n\n");
                        $display("##########################################################");
                        $display("############### NÚMERO DE TRANSACCIONES %0d ###############", transacciones_completadas);
                        $display("##########################################################");
                    end

                    instr_broadcast: begin
                        // Código para procesar las transacciones tipo broadcast
                        $display("Procesando: Transacción de tipo Broadcast \n\n");
                        $display("##########################################################");
                        $display("############### NÚMERO DE BROADCASTS %0d ###############", instr_broadcast);
                        $display("##########################################################");
                    end

                    instr_send: begin
                        // Código para procesar las transacciones tipo send
                        $display("Procesando: Transacción de tipo Send \n\n");
                        $display("##########################################################");
                        $display("############### NÚMERO DE ENVÍOS %0d ###############", instr_send);
                        $display("##########################################################");
                    end

                    latencia: begin
                        // Código para calcular la latencia
                        $display("Procesando: Latencia \n\n");
                        $display("##########################################################");
                        $display("############### LATENCIA %0d CICLOS ###############", latencia);
                        $display("##########################################################");
                    end

                    total_avg_delay: begin
                        // Código para calcular el retardo promedio total
                        $display("Procesando: Retardo Promedio Total \n\n");
                        $display("##########################################################");
                        $display("############### RETARDO PROMEDIO TOTAL %0d CICLOS ###############", total_avg_delay);
                        $display("##########################################################");
                    end

                    clk_cycles: begin
                        // Código para procesar la cantidad de ciclos de reloj
                        $display("Procesando: Ciclos de Reloj \n\n");
                        $display("##########################################################");
                        $display("############### CICLOS DE RELOJ %0d ###############", clk_cycles);
                        $display("##########################################################");
                    end

                    time_elapsed: begin
                        // Código para procesar el tiempo transcurrido
                        $display("Procesando: Tiempo Transcurrido \n\n");
                        $display("##########################################################");
                        $display("############### TIEMPO TRANSCURRIDO %0d UNIDADES ###############", time_elapsed);
                        $display("##########################################################");
                    end

                    complete_report: begin
                        // Código para generar un reporte completo
                        $display("Procesando: Reporte Completo \n\n");
                        $display("##########################################################");
                        $display("############### REPORTE COMPLETO ###############");
                        $display("### TRANSACCIONES COMPLETADAS: %0d", transacciones_completadas);
                        $display("### BROADCASTS: %0d", instr_broadcast);
                        $display("### ENVÍOS: %0d", instr_send);
                        $display("### LATENCIA PROMEDIO: %0d CICLOS", total_avg_delay);
                        $display("### CICLOS DE RELOJ: %0d", clk_cycles);
                        $display("### TIEMPO TRANSCURRIDO: %0d UNIDADES", time_elapsed);
                        $display("##########################################################");
                    end

                    default: begin
                        // Código por defecto en caso de que no se cumpla ninguno de los casos anteriores
                        $display("Error: Consulta no reconocida");
                    end
                endcase
            end
        end
    endtask

    // Función para cerrar el archivo CSV
    function void close_csv();
        if (csv_file) begin
            $fclose(csv_file);  // Cerrar el archivo CSV
            $display("El archivo CSV ha sido cerrado correctamente.");
            $finish; // Finalizar la simulación
        end else begin
            $error("Error: El archivo CSV no estaba abierto o ya fue cerrado.");
            $finish; // Finalizar la simulación
        end
    endfunction

endclass
