
class driver # (parameter WIDTH = 16, parameter DRVS = 8);

    mbx_agent_driver   agnt_drv_mbx;     //mailbox del agente al driver
    mbx_driver_checker drv_chkr_mbx;     //mailbox del driver al checker

    int drv_id; //identificador del driver [este sera de 0 a DRVS-1]
    
    //Interfaz del driver con el DUT
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_driver_fifo_dut;

    logic [WIDTH - 1 : 0] fifo_in [$];    //fifo emulada de entrada al DUT
    
    //variables para almacenar los datos actuales en el driver
    logic [7 : 0]         current_pkg_id; 
    logic [WIDTH - 9 : 0] current_payload;
    logic [WIDTH - 1 : 0] current_data_tx;

    int espera; //variable para simular el retardo

    //constructor, inicializa el driver con el id indicado en el parametro
    function new(int driver_id = 0);
        this.drv_id = driver_id;
    endfunction
     
    //task principal
    task run();
        
        $display("[%g] El driver  [%g] fue inicializado", $time, drv_id);
        
       @(posedge vif_driver_fifo_dut.clk);
        forever begin
            //se crea una transacción de tipo instrucciones_driver_monitor para enviarla al DUT
            instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_send;
            
            //las senales que controla el driver son pnndg, pop y D_pop.
            //se inicializan en 0
            vif_driver_fifo_dut.pndng [0][drv_id] = '0;
            vif_driver_fifo_dut.pop   [0][drv_id] = '0;
            vif_driver_fifo_dut.D_pop [0][drv_id] = '0;

            $display("[%g] El Driver  [%g] espera por una transacción", $time, drv_id);

            espera = 0;
            
            //se espera a que llegue una transacción al mailbox del agente
            @(posedge vif_driver_fifo_dut.clk); begin
                $display("[%g] Transacciones pendientes en el mbx agnt_drv [%g] = %g", $time, drv_id, agnt_drv_mbx.num());
                agnt_drv_mbx.get(transaction_send); //se queda aca hasya que llegue una transacción
                $display("[%g] Driver: Transacción recibida en el driver [%g]", $time, drv_id);
                transaction_send.print("Transacción recibida en el driver");
            end
            
            //se emula el retardo
            while (espera < transaction_send.delay) begin
                    @(posedge vif_driver_fifo_dut.clk); begin
                        espera = espera + 1;
                    end
            end
            
            //se evalua el tipo de transaccion, entre send, broadcast y reset
            case (transaction_send.tipo_transaccion)
                
                //si se da un send
                send: begin
          
                    @(posedge vif_driver_fifo_dut.clk); begin
                        
                        //se obtienen los datos de la transaccion, se concatenan formando el paquete
                        this.current_payload = transaction_send.pkg_payload;
                        this.current_pkg_id = transaction_send.pkg_id;
                        this.current_data_tx = {this.current_pkg_id, this.current_payload};
                        fifo_in.push_front(this.current_data_tx);  //aqui se lo metemos a la fifo de entrada
                        
                        $display("[%g] Driver [%g] envio la transaccion send a la FIFO de entrada", $time, drv_id);
                        transaction_send.print("Driver: Transacción send enviada a la FIFO de entrada");
    
                        //se comprueba si hay datos pendientes para entrar al dut en la fifo de entrada
                        if (fifo_in.size() == 0)
                            vif_driver_fifo_dut.pndng[0][drv_id] = 0;

                        else vif_driver_fifo_dut.pndng[0][drv_id] = 1;

                        //se conecta la fifo de entrada con el dut por vif_driver_fifo_dut
                        //en el Dpop se coloca el ultimo elemento de la fifo
                        vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                        
                        //me quedo esperando a que el bus atienda al driver
                        while (vif_driver_fifo_dut.pop [0][drv_id] == 0) begin
                            @(posedge vif_driver_fifo_dut.clk);
                        end
                         
                        //se envia al dut la info
                        if (vif_driver_fifo_dut.pop[0][drv_id] == 1) begin
                            vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                            transaction_send.send_time = $time;
                            transaction_send.receiver_monitor = this.current_pkg_id;
                            transaction_send.pkg_payload      = transaction_send.pkg_payload;
                            transaction_send.tipo_transaccion = transaction_send.tipo_transaccion;
                            transaction_send.sender_monitor   = drv_id;
                            $display("[%g] Driver [%g] envio la transaccion al DUT", $time, drv_id);

                             //al enviar al dut, se mete en send time con $time
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada");
                            drv_chkr_mbx.put(transaction_send); //se envia al checker
                            $display("[ %g ] El Driver [%g] envio la transaccion al checker", $time, drv_id);
                            fifo_in.pop_back(); //una vez procesado, se saca de la fifo
                        end

                        else;
                            //esta linea se comenta para no hacer tanto spam en el log
                            //transaction_send.print("Driver: Transacción esperando en la fifo de entrada el pop del DUT"); //si aun no esta listo el dut, se espera

                    end                
                end  
                
                //exactamente igual que el send
                broadcast: begin
          
                    @(posedge vif_driver_fifo_dut.clk); begin

                        this.current_payload = transaction_send.pkg_payload;
                        this.current_pkg_id = transaction_send.pkg_id;
                        this.current_data_tx = {current_pkg_id, current_payload};
                        fifo_in.push_front(this.current_data_tx);  //aqui se lo metemos a la fifo de entrada
                        
                        $display("[%g] Driver [%g] envio la transaccion broadcast a la FIFO de entrada", $time, drv_id);
                        transaction_send.print("Driver: Transacción broadcast enviada a la FIFO de entrada");
    
                        //se comprueba si hay datos pendientes para entrar al dut en la fifo de entrada
                        if (fifo_in.size() == 0)
                            vif_driver_fifo_dut.pndng[0][drv_id] = 0;

                        else vif_driver_fifo_dut.pndng[0][drv_id] = 1;

                        //se conecta la fifo de entrada con el dut por vif_driver_fifo_dut
                        vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                        
                        //me quedo esperando a que el bus atienda al driver
                        while (vif_driver_fifo_dut.pop [0][drv_id] == 0) begin
                            @(posedge vif_driver_fifo_dut.clk);
                        end
                         
                        //se envia al dut la info
                        if (vif_driver_fifo_dut.pop[0][drv_id] == 1) begin
                            vif_driver_fifo_dut.D_pop[0][drv_id] = fifo_in[$];
                            transaction_send.send_time = $time;
                            transaction_send.receiver_monitor = transaction_send.pkg_id;
                            transaction_send.pkg_payload      = transaction_send.pkg_payload;
                            transaction_send.tipo_transaccion = transaction_send.tipo_transaccion;
                            transaction_send.sender_monitor   = drv_id;
                            

                            $display("[%g] Driver [%g] envio la transaccion al DUT", $time, drv_id);
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada"); //al enviar al dut, se mete en send time con $time
                            drv_chkr_mbx.put(transaction_send); //se envia al checker
                            $display("[ %g ] El Driver [%g] envio la transaccion al checker", $time, drv_id);
                            fifo_in.pop_back();
                        end

                        else;
                            //transaction_send.print("Driver: Transacción esperando en la fifo de entrada el pop del DUT"); //si aun no esta listo el dut, se espera
    
                    end                
                end  
                
                //el reset en el driver solo se encarga de limpiar la fifo emulada
                reset: begin
                    fifo_in.delete();
                    transaction_send.print("Driver: Transacción reset ejecutada");
                    $display("Driver: FIFO de entrada limpiada en reset");
                end
                
                //si no se tiene un tipo valido, se termina la simulacion
                default: begin
                    $display("[%g] Driver Error: la transacción recibida no tiene tipo válido", $time);
                    $finish;
                end
            endcase
        end
    endtask
endclass