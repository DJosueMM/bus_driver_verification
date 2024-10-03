class checker #(parameter WIDTH = 16, parameter DRVS = 4);

    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion;   // Transacción recibida
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) auxiliar;      // Transacción auxiliar para manejar la FIFO emulada
    // trans_sb_mbx chkr_sb_mbx;               // Este mailbox es el que comunica el checker con el scoreboard

    instrucciones_driver_monitor emul_fifo[$];                   // Cola para almacenar los datos de la FIFO emulada
    
   
    mbx_monitor_checker mnt_checker_mbx;  
    mbx_driver_checker  driver_checker_mbx;

    int contador_auxiliar;

    function new();
        this.emul_fifo = {};  
        this.contador_auxiliar = 0;
    endfunction

    task run();
        $display("[%g] Checker inicializado", $time);
        //to_sb = new();

        //  Validar pkg_payload 
        assert(transaccion.pkg_payload >= 0 && transaccion.pkg_payload <= 'hFF)
            else $fatal("[%g] Payload fuera de rango en el Checker: pkg_payload=0x%h", $time, transaccion.pkg_payload);


        //  Validar receiver_monitor
        assert(transaccion.receiver_monitor >= 0 && transaccion.receiver_monitor < DRVS)
            else $fatal("[%g] ID de receiver_monitor inválido en el Checker: receiver_monitor=%0d", 
                            $time, transaccion.receiver_monitor);


        forever begin
            //to_sb = new();
            driver_checker_mbx.get(transaccion);
            transaccion.print("Checker: Se recibe transacción desde el driver");
            //to_sb.clean();
            case(transaccion.tipo_transaccion)
                send: begin

                        transaccion.print("Checker: Transacción Send");
                        emul_fifo.push_back(transaccion);  // Almacenar transacción en la FIFO

                end

                broadcast: begin

                        transaccion.print("Checker: Transacción Broadcast");
                        emul_fifo.push_back(transaccion);  // Almacenar transacción en la FIFO

                end

                reset: begin
                    contador_auxiliar = emul_fifo.size();  // Vaciar la FIFO durante reset
                    for(int i = 0; i < contador_auxiliar; i++) begin
                        auxiliar = emul_fifo.pop_front();
                        //to_sb.clean();
                        //to_sb.dato_enviado = auxiliar.dato;
                        //to_sb.tiempo_push  = auxiliar.tiempo;
                        //to_sb.reset = 1;
                        //to_sb.print("Checker: Reset");
                        chkr_sb_mbx.put(//to_sb);
                    end
                    $display("[%g] Checker: Reset completo, FIFO vaciada", $time);
                end

                default: begin
                    $display("[%g] Error del Checker: Tipo de transacción inválido", $time);
                    $finish;
                end
            endcase
        end
    endtask
endclass
