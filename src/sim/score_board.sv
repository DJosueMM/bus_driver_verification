class score_board #(parameter width = 16, parameter bits = 1, parameter drvrs = 4);

    // Mailboxes para la comunicación
    trans_fifo_mbx chkr_sb_mbx;           // Mailbox para recibir transacciones del monitor
    comando_test_sb_mbx test_sb_mbx;      // Mailbox para recibir comandos del test

    // Interfaz del scoreboard
    virtual fifo_if #(.width(width), .bits(bits), .drvrs(drvrs)) vif;

    // Transacción y contadores
    trans_fifo #(.width(width)) transaccion; // Transacción recibida
    int transacciones_completadas = 0;      // Contador de transacciones completadas

    int num_transacciones;  // Número total de transacciones esperadas
    bit triggered;          // Flag para controlar la activación del scoreboard
    int instr_correctas;    // Contador de instrucciones correctas
    int instr_incorrectas;  // Contador de instrucciones incorrectas
    int latencia;           // Latencia de la transacción

    integer csv_file;      // Descriptor de archivo CSV

    event transacciones_event; // Evento para indicar la finalización de las transacciones

    // Tarea principal para ejecutar el scoreboard
    task run();
        // Abrir el archivo CSV para escritura
        csv_file = $fopen("scoreboard_report.csv", "w");
        if (!csv_file) begin
            $error("No se pudo abrir el archivo CSV para escritura");
            return;
        end

        // Escribir la cabecera del CSV
        $fdisplay(csv_file, "Transaction,Packet Data,Send Time,Delivery Time,Latency,Valid");

        $display("[%g] El Score Board fue inicializado", $time); // Mensaje de inicialización
        #5
        triggered = 1; // Activar el flag para iniciar el procesamiento de transacciones
        forever begin
            @(posedge vif.clk); // Esperar al flanco positivo del reloj
            if (triggered) begin
                // Procesar transacciones en el mailbox del scoreboard
                if (chkr_sb_mbx.num() > 0) begin
                    chkr_sb_mbx.get(transaccion); // Obtener la transacción del mailbox
                    latencia = transaccion.tiempo_out - transaccion.tiempo; // Calcular latencia
                    $display("[%g] ////////// SB recibe un paquete: %h", $time, transaccion.dato);
                    $display("[%g] ////////// Tiempo de envio %0d", $time, transaccion.tiempo);
                    $display("[%g] ////////// Tiempo de entrega %0d", $time, transaccion.tiempo_out);
                    $display("[%g] ////////// Latencia %0d", $time, latencia);

                    // Escribir los datos de la transacción actual en el archivo CSV
                    $fdisplay(csv_file, "%0d,%h,%0d,%0d,%0d,%0b",
                              transacciones_completadas, transaccion.dato,
                              transaccion.tiempo, transaccion.tiempo_out,
                              latencia, transaccion.validez);

                    transacciones_completadas++; // Incrementar el contador de transacciones

                    // Contar instrucciones correctas e incorrectas
                    if (transaccion.validez) begin
                        instr_correctas++;
                    end else begin
                        instr_incorrectas++;
                    end

                    // Comprobar si se han completado todas las transacciones esperadas
                    if (transacciones_completadas >= num_transacciones * 3) begin
                        triggered = 0;  // Desactivar el trigger cuando se cumple la condición
                        $display("[%g] Se completaron todas las transacciones: %0d", $time, transacciones_completadas);
                        ->transacciones_event; // Generar evento de finalización de transacciones
                    end
                end
            end

            // Procesar el mailbox de comandos del test
            if (test_sb_mbx.num() > 0) begin
                $display("#################### REPORTE FINAL ####################");
                $display("############### NÚMERO DE TRANSACCIONES %0d ###############", transacciones_completadas);
                $display("[%g] --- Se completaron %0d transacciones, con %0d correctas y %0d incorrectas ---",
                         $time, transacciones_completadas, instr_correctas, instr_incorrectas);
                
                // Cerrar el archivo CSV
                $fclose(csv_file);
                $finish; // Finalizar la simulación
            end
        end
    endtask
endclass
