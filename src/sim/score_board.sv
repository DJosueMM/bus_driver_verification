class score_board # (parameter width = 16, parameter DRVS = 4);

    virtual dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) vif_sb_fifo_dut;


    localparam CLK_PERIOD = 20; // Periodo del reloj en ns
    consulta_sb consulta_test_sb;

    mbx_checker_sb checker_sb_mbx;     
    mbx_test_sb test_sb_mbx;
    
    //variables de estadisticas de simulacion
    int transacciones_completadas = 0;  
    int instr_broadcast = 0;               
    int instr_send = 0;                    
    real latencia = 0;  
    real total_avg_delay = 0;                    
    int clk_cycles = 0;
    int time_elapsed = 0;
    real terminal_activa [DRVS - 1 : 0];    //variable para contar las transacciones por terminal
    real avr_delay_terminal [DRVS - 1 : 0]; //variable para calcular el promedio de retardo por terminal

    integer csv_file;  //auxiliar para crear el csv

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

            instrucciones_driver_monitor #(.WIDTH(width)) complete_transaction;
            @(posedge vif_sb_fifo_dut.clk); // Esperar al flanco positivo del reloj
            clk_cycles++;
            time_elapsed = clk_cycles * CLK_PERIOD;
      
            // Procesar transacciones en el mailbox del scoreboard
            if (checker_sb_mbx.num() > 0) begin
                checker_sb_mbx.get(complete_transaction); // Obtener la transacción del mailbox
                $display("[%g] SB recibe una transaccion del Checker", $time);
                
                transacciones_completadas++;
                terminal_activa[complete_transaction.receiver_monitor]++; //se aumenta el contador de transacciones por terminal, para la terminal correspondiente     
                avr_delay_terminal[complete_transaction.receiver_monitor] = (avr_delay_terminal[complete_transaction.receiver_monitor] + complete_transaction.receive_time - complete_transaction.send_time) / terminal_activa[complete_transaction.receiver_monitor]; // Calcular latenciavpor terminal
                latencia = complete_transaction.receive_time - complete_transaction.send_time; //calcula la latencia de la transaccion
                total_avg_delay = (total_avg_delay + latencia) / transacciones_completadas;  //calcula el promedio de retardo total

                if (complete_transaction.tipo_transaccion == broadcast) 
                    instr_broadcast++; //aumenta el contador de transacciones de tipo broadcast
                else if (complete_transaction.tipo_transaccion == send)
                    instr_send++; //aumenta el contador de transacciones de tipo send
                
                //$display("[%g] Latencia promedio %0d", $time, total_avg_delay);
                //$display("[%g] Transacciones Completadas %0d", $time, transacciones_completadas);
                //$display("[%g] Broadcast Completados %0d", $time, instr_broadcast);
                //$display("[%g] Send Completados %0d", $time, instr_send);

                // Escribir los datos de la transacción actual en el archivo CSV
                $fdisplay(csv_file, "%g,%d,%d,%d,%f,%f,%d,%d,%d,%p",
                          $time, transacciones_completadas, instr_broadcast, instr_send, latencia,
                          total_avg_delay, clk_cycles, time_elapsed, 
                          complete_transaction.receiver_monitor, avr_delay_terminal);
            end

            // Procesar el mailbox de comandos del test
            if (test_sb_mbx.num() > 0) begin     
                test_sb_mbx.try_get(consulta_test_sb); // Obtener la transacción del mailbox
                
                //dependiendo del tipo, se imprime el reporte correspondiente
                case (consulta_test_sb)

                    transacciones_completadas: begin
                        $display("Procesando: Transacciones Completadas \n\n");
                        $display("##########################################################");
                        $display("############### NÚMERO DE TRANSACCIONES %0d ###############", transacciones_completadas);
                        $display("##########################################################");
                    end

                    instr_broadcast: begin
                        $display("Procesando: Transacción de tipo Broadcast \n\n");
                        $display("##########################################################");
                        $display("############### NÚMERO DE RECIBIDAS POR BROADCASTS %0d ###############", instr_broadcast);
                        $display("##########################################################");
                    end

                    instr_send: begin
                        $display("Procesando: Transacción de tipo Send \n\n");
                        $display("##########################################################");
                        $display("############### NÚMERO DE ENVÍOS %0d ###############", instr_send);
                        $display("##########################################################");
                    end

                    latencia: begin
                        $display("Procesando: Latencia \n\n");
                        $display("##########################################################");
                        $display("############### LATENCIA %f CICLOS ###############", latencia);
                        $display("##########################################################");
                    end

                    total_avg_delay: begin
                        $display("Procesando: Retardo Promedio Total \n\n");
                        $display("##########################################################");
                        $display("############### RETARDO PROMEDIO TOTAL %0d CICLOS ###############", total_avg_delay);
                        $display("##########################################################");
                    end

                    clk_cycles: begin
                        $display("Procesando: Ciclos de Reloj \n\n");
                        $display("##########################################################");
                        $display("############### CICLOS DE RELOJ %0d ###############", clk_cycles);
                        $display("##########################################################");
                    end

                    time_elapsed: begin
                        $display("Procesando: Tiempo Transcurrido \n\n");
                        $display("##########################################################");
                        $display("############### TIEMPO TRANSCURRIDO %0d ns      ###############", time_elapsed);
                        $display("##########################################################");
                    end

                    complete_report: begin
                        $display("Procesando: Reporte Completo \n\n");
                        $display("##########################################################");
                        $display("############### REPORTE COMPLETO ###############");
                        $display("### TRANSACCIONES COMPLETADAS: %0d", transacciones_completadas);
                        $display("### RECIBIDAS POR BROADCASTS: %0d", instr_broadcast);
                        $display("### ENVÍOS: %0d", instr_send);
                        $display("### LATENCIA PROMEDIO: %f CICLOS", total_avg_delay);
                        $display("### CICLOS DE RELOJ: %0d", clk_cycles);
                        $display("### TIEMPO TRANSCURRIDO: %0d UNIDADES", time_elapsed);
                        $display("##########################################################");
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
        end else begin
            $error("Error: El archivo CSV no estaba abierto o ya fue cerrado.");
        end
    endfunction
endclass
