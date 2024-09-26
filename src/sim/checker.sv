class checker (parameter WIDTH = 16, DRVS = 4);

    instrucciones_driver_monitor #(.width(WIDTH)) transaccion; // Transacción recibida en el mailbox
    instrucciones_driver_monitor #(.width(width)) auxiliar;   // Transacción usada como auxiliar para leer el fifo emulado
    // trans_sb                  #(.width(WIDTH)) //to_sb;                // Transacción usada para comunicarse con el scoreboard
    
    instrucciones_driver_monitor emul_fifo[$];                // This queue is going to be used as golden reference for the fifo
    mbx_driver_checker           driver_checker_mbx;            // Este mailbox es el que comunica con el driver/monitor
    // trans_sb_mbx chkr_sb_mbx;               // Este mailbox es el que comunica el checker con el scoreboard
    
    int contador_auxiliar;

    function new();
        this.emul_fifo = {};
        this.contador_auxiliar = 0;
    endfunction


    task run();
        $display("[%g] El checker fue inicializado", $time);
        //to_sb = new();
        forever begin
            //to_sb = new();
            driver_checker_mbx.get(transaccion);
            transaccion.print("Checker: Se recibe transacción desde el driver");
            //to_sb.clean();
            case(transaccion.tipo)

                send: begin
                    if(emul_fifo.size() == DRVS) begin // Revisa si la Fifo está llena para generar un overflow
                        auxiliar = emul_fifo.pop_front();
                        //to_sb.dato_enviado = auxiliar.dato;
                        //to_sb.tiempo_push = auxiliar.tiempo;
                        //to_sb.overflow = 1;
                        //to_sb.print("Checker: Overflow");
                        //chkr_sb_mbx.put(to_sb);
                        emul_fifo.push_back(transaccion);
                    end else begin  // En caso de no estar llena simplemente guarda el dato en la fifo simulada
                        transaccion.print("Checker: Send");
                        emul_fifo.push_back(transaccion);
                    end
                end

                broadcast: begin
                    if(emul_fifo.size() == DRVS) begin // Revisa si la Fifo está llena para generar un overflow
                        auxiliar = emul_fifo.pop_front();
                        //to_sb.dato_enviado = auxiliar.dato;
                        //to_sb.tiempo_push = auxiliar.tiempo;
                        //to_sb.overflow = 1;
                        //to_sb.print("Checker: Overflow");
                        //chkr_sb_mbx.put(to_sb);
                        emul_fifo.push_back(transaccion);
                    end else begin  // En caso de no estar llena simplemente guarda el dato en la fifo simulada
                        transaccion.print("Checker: Broadcast");
                        emul_fifo.push_back(transaccion);
                    end
                end

                reset: begin // en caso de reset vacía la fifo simulada y envía todos los datos perdidos al SB
                    contador_auxiliar = emul_fifo.size();
                    for(int i = 0; i < contador_auxiliar; i++) begin
                        auxiliar = emul_fifo.pop_front();
                        //to_sb.clean();
                        //to_sb.dato_enviado = auxiliar.dato;
                        //to_sb.tiempo_push  = auxiliar.tiempo;
                        //to_sb.reset = 1;
                        //to_sb.print("Checker: Reset");
                        chkr_sb_mbx.put(//to_sb);
                    end
                end
    

                default: begin
                    $display("[%g] Checker Error: la transacción recibida no tiene tipo valido", $time);
                    $finish;
                end
            endcase
        end
    endtask




endclass