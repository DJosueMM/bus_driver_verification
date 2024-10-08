class checker #(parameter WIDTH = 16, parameter DRVS = 8);

    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_drv_received;   // Transacción recibida del driver
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_mnt_received;   // Transacción recibida del monitor
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaccion_to_sb;          // Auxiliar para guardar transacciones temporales
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) revisando;
    
    mbx_driver_checker  driver_checker_mbx [DRVS - 1 : 0];  // Mailbox del driver al checker
    mbx_monitor_checker mnt_checker_mbx    [DRVS - 1 : 0];  // Mailbox del monitor al checker
    mbx_checker_sb      checker_sb_mbx;

    // FIFO para las transacciones provenientes de los drivers
    instrucciones_driver_monitor#(.WIDTH(WIDTH)) driver_fifo [$]; 
  
    // Definición de la interface a la que se conectará el DUT
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_checker_fifo_dut;
    
    // Variables auxiliares
    bit [7 : 0]         pkg_id_mnt;
    bit [WIDTH - 9 : 0] pkg_payload_mnt;
    int                 rcv_mnt_mnt;
    tipo_trans          tipo_transaccion_mnt;
    
    //variables para realizar el check
    bit match_found;
    bit success_get_driver;
    bit success_get_monitor;

    // Constructor
    function new();

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
            
            // Reiniciar indicadores de coincidencia y variables auxiliares
            this.match_found = 0;  
            this.pkg_id_mnt = '0;
            this.pkg_payload_mnt = '0;
            this.rcv_mnt_mnt = 0;
            this.tipo_transaccion_mnt = '0;
            this.match_found = 0;
            this.success_get_driver = 0;
            this.success_get_monitor = 0;
            
            // Iterar sobre todas las transacciones de los drivers
            for (int i = 0; i < DRVS; i++) begin
                
                this.success_get_driver = driver_checker_mbx[i].try_get(transaccion_drv_received);  // Intentar recibir la transacción del driver
                this.success_get_monitor = mnt_checker_mbx[i].try_get(transaccion_mnt_received);  // Intentar recibir la transacción del monitor
                
                if (this.success_get_driver) begin
                    // Añadir la transacción recibida a la FIFO 
                    driver_fifo.push_front(transaccion_drv_received);
                    $display("Se añadió una transacción a la FIFO del Driver[%0d]", i);

                    transaccion_drv_received.print("Checker: Se recibe transacción desde el driver");
                end

                if (this.success_get_monitor) begin

                    $display("Checker: se obtuvo una transacion del Monitor[%0d]", i);
                    //se obtienen los campos a buscar en transacciones realizadas por los drivers
                    this.pkg_id_mnt           = transaccion_mnt_received.pkg_id;
                    this.pkg_payload_mnt      = transaccion_mnt_received.pkg_payload;
                    this.rcv_mnt_mnt          = transaccion_mnt_received.receiver_monitor;
                    this.tipo_transaccion_mnt = transaccion_mnt_received.tipo_transaccion;


                    transaccion_mnt_received.print("Checker: revisando transaccion recibida en el monitor");
                    
                    /*
                    en este punto ya llego la transaccion del driver, falta la del monitor.
                    entonces cuando llega la del monitor, se busca en toda la fifo de transacciones de drivers
                    si hay alguna que coincida con la del monitor.*/
                    foreach (driver_fifo[w]) begin

                        this.match_found = 0;
                        // Acceder al elemento en la posición w de la cola
                        revisando = new();
                        revisando = driver_fifo[w];
                        revisando.print("Checker: revisando transaccion anteriormente recibida de driver");
                        $display ("intento #[%g]", w);
                        $display("revisando.pkg_id           ENVIADO DEL DRIVER [%g]    vs RECIBIDO DEL MONITOR [%g] \nrevisando.pkg_payload      ENVIADO DEL DRIVER [%h]   vs RECIBIDO DEL MONITOR [%h] \nrevisando.receiver_monitor ENVIADO DEL DRIVER [%g]    vs RECIBIDO DEL MONITOR [%g] \nrevisando.tipo_transaccion ENVIADO DEL DRIVER [%p] vs RECIBIDO DEL MONITOR [%p]", 
                                  revisando.pkg_id, this.pkg_id_mnt,  revisando.pkg_payload, this.pkg_payload_mnt, revisando.receiver_monitor, this.rcv_mnt_mnt, revisando.tipo_transaccion, this.tipo_transaccion_mnt); 
                        
                        $display("[%g] Checker: revisando coincidencia de transaccion recibida en el monitor con la transaccion [%g]", $time, w);
                        
                        //si la del monitor es de broadcast, se necesita buscar el origen de ese broadcast
                        if (this.tipo_transaccion_mnt == broadcast) begin 
                            
                            //para cada elemento, se comprueba si el id y el payload coinciden. Y que ambas sean broadcast
                            if (this.pkg_id_mnt == revisando.pkg_id && this.pkg_payload_mnt == revisando.pkg_payload &&
                                this.tipo_transaccion_mnt == revisando.tipo_transaccion) begin
                            
                                $display ("[%g] Checker: las transacciones coinciden", $time);
                                this.match_found = 1;

                                //se construye la transaccion completa recuperada, para eviar al sb
                                transaccion_to_sb = new();
                                transaccion_to_sb.max_delay        = transaccion_drv_received.max_delay;
                                transaccion_to_sb.delay            = transaccion_drv_received.delay;
                                transaccion_to_sb.pkg_id           = 8'b11111111;
                                transaccion_to_sb.pkg_payload      = this.pkg_payload_mnt;
                                transaccion_to_sb.send_time        = transaccion_drv_received.send_time;
                                transaccion_to_sb.receive_time     = transaccion_mnt_received.receive_time;
                                transaccion_to_sb.receiver_monitor = this.rcv_mnt_mnt;
                                transaccion_to_sb.tipo_transaccion = this.tipo_transaccion_mnt;
                                transaccion_to_sb.sender_monitor   = transaccion_drv_received.sender_monitor;
        
                                transaccion_to_sb.print("Checker: transaccion completa reconstruida");
                                checker_sb_mbx.put(transaccion_to_sb);
                                $display ("[%g] Checker: transaccion enviada al sb", $time);
                                //al encontrar una coincidencia, no se elimina la transaccion de la fifo, porque al ser broadcast
                                //es necesario que todos los monitores la reciban.
                                break;
                            end

                            else $display ("[%g] Checker: las transacciones no coinciden, pasando a la siguiente", $time);

                        end

                        else begin

                            //si es un send, se busca que el id, el payload y el monitor coincidan
                            if (this.pkg_id_mnt == revisando.pkg_id && this.pkg_payload_mnt[7 : 0] == revisando.pkg_payload[7 : 0] &&
                                this.rcv_mnt_mnt == revisando.receiver_monitor && this.tipo_transaccion_mnt == revisando.tipo_transaccion) begin
                                 
                                //se reconstruye la transaccion y se envia al sb
                                $display ("[%g] Checker: las transacciones coinciden", $time);
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
                                transaccion_to_sb.sender_monitor   = transaccion_drv_received.sender_monitor;
        
                                transaccion_to_sb.print("Checker: transaccion completa reconstruida");
                                checker_sb_mbx.put(transaccion_to_sb);
                                $display ("[%g] Checker: transaccion enviada al sb", $time);
                                //se elimina la transaccion de la fifo, ya que se encontro la pareja y no es necesaria
                                driver_fifo.delete(w);
                                break;
                            end

                            else $display ("[%g] Checker: las transacciones no coinciden, pasando a la siguiente", $time);

                        end
                    end
                    
                    //si al terminar de buscar en la fifo, no se encontro coincidencia, se termina la simulacion 
                    //esto porque en el momento que se revisa ya debe haber una posible coincidencia si todo esta funcionando bien
                    if (this.match_found == 0) begin
                        $display ("[%g] ERROR Checker: las transaccion recibida no coincide con ninguna enviada", $time);
                        transaccion_mnt_received.print("Checker: ERROR EN LA TRANSACCION RECIBIDA");
                        $finish;
                    end
                end
            end
        end
    endtask
    
    // Método para revisar los datos descartados
    /*Esta tarea es util para al finalizar el test hacer unas ultimas comprobaciones.
      1. Se revisa que las transacciones de broadcast hayan sido recibidas por todos los monitores.
      2. Se revisa que las transacciones de send no validas hayan sido descartadas correctamente. 
         con descartadas se refiere a que se encuentren en la FIFO, esto implica que no se recibieron datos 
         coincidentes con una transaccion invalida. 

         en este segundo punto hay varios tipos:

            - Si el id del paquete es igual al id del monitor, se descarta. Porque no tiene sentido que un monitor
              reciba un paquete que el mismo envio. Asi no funciona el DUT
            - Si el id del paquete es mayor o igual a DRVS - 1, se descarta. Porque no hay monitores con id mayor, 
              osea que esa transaccion se envio a un monitor que no existe.
            - Si el id del paquete es diferente que el monitor que lo recibio, se descarta. Porque no tiene sentido
              que un monitor reciba un paquete que no le corresponde.
              
      3. Si no se cumple ninguno de los puntos anteriores, se termina la simulacion. Y si hay una transaccion valida
         pendiente de evaluarse en la fifo en el momento que se ejecuta este checkeo, tambien hay un error ya que nunca
         se recibio el paquete que si estaba valido.
    */
    task revisar_datos_descartados();
        
        $display("\n[%g] Test: comprobando que los datos no validos hayan sido correctamente descartados\n", $time);
        // Recorre cada entrada en la FIFO driver_fifo
        foreach(driver_fifo[i]) begin
            
            //se verifican que los broadcast sigan en la fifo al terminar, esto implica que ya todos los monitores la recibieron
            if (driver_fifo[i].tipo_transaccion == broadcast) begin
                //driver_fifo.delete(i);
                $display("[%g] Transaccion de broadcast ya fue recibida por todos los monitores:\n %p", $time, driver_fifo[i]);
            end 
            
            else begin

                if ((driver_fifo[i].tipo_transaccion == send && driver_fifo[i].pkg_id != driver_fifo[i].receiver_monitor) ||
                    (driver_fifo[i].tipo_transaccion == send && driver_fifo[i].pkg_id >= DRVS - 1) || 
                    (driver_fifo[i].sender_monitor == driver_fifo[i].pkg_id)) begin
                    $display("[%g] Transaccion ilegal o sin proposito correctamente descartada:\n%p", $time, driver_fifo[i]);
                    //driver_fifo.delete(i);
                end 
                
                else begin
                    $display("[%g] ERROR: Transaccion Valida pendiente a evaluarse:\n%p", $time, driver_fifo[i]);
                    $finish;
                end
            end
        end
    endtask
endclass
