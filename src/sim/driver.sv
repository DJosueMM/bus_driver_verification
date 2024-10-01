
class driver # (parameter WIDTH = 16, DRVS = 8);

    mbx_agent_driver   agnt_drv_mbx;     
    mbx_driver_checker drv_chkr_mbx;
    int                drv_id;
    
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_driver_fifo_dut;

    logic [WIDTH - 1 : 0] fifo_in [$];

    int espera;

    function new(int driver_id = 0);
        this.drv_id = driver_id;
    endfunction

    task run();
        
        $display("[%g] El driver fue inicializado", $time);
        
       @(posedge vif_driver_fifo_dut.clk);
        forever begin

            instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_send;
            vif_driver_fifo_dut.pndng [0][drv_id] = '0;
            vif_driver_fifo_dut.pop   [0][drv_id] = '0;
            vif_driver_fifo_dut.D_pop [0][drv_id] = '0;

            $display("[ %g ] El Driver [%d] espera por una transacción", drv_id, $time);

            espera = 0;
            
            @(posedge vif_driver_fifo_dut.clk); begin
                agnt_drv_mbx.get(transaction_send);
                transaction_send.print("Driver: Transacción recibida en el driver");
                $display("Transacciones pendientes en el mbx agnt_drv = %g", agnt_drv_mbx.num());
            end

            while (espera < transaction_send.delay) begin
                    @(posedge vif_driver_fifo_dut.clk); begin
                        espera = espera + 1;
                    end
            end

            case (transaction_send.tipo_transaccion)

                send: begin
          
                    @(posedge vif_driver_fifo_dut.clk); begin

                        fifo_in.push_front({transaction_send.pkg_id, transaction_send.pkg_payload});  //aqui se lo metemos a la fifo de entrada
                        transaction_send.print("Driver: Transacción send enviada a la FIFO de entrada");
    
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
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada"); //al enviar al dut, se mete en send time con $time
                            //drv_chkr_mbx.put(transaction_send); //se envia al checker
                            fifo_in.pop_back();
                        end

                        else begin
                            transaction_send.print("Driver: Transacción esperando en la fifo de entrada el pop del DUT"); //si aun no esta listo el dut, se espera
                        end
                    end                
                end 

                broadcast: begin
          
                    @(posedge vif_driver_fifo_dut.clk); begin

                        fifo_in.push_front({transaction_send.pkg_id, transaction_send.pkg_payload});  //aqui se lo metemos a la fifo de entrada
                        transaction_send.print("Driver: Transacción send enviada a la FIFO de entrada");
    
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
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada"); //al enviar al dut, se mete en send time con $time
                            //drv_chkr_mbx.put(transaction_send); //se envia al checker
                            fifo_in.pop_back();
                        end

                        else begin
                            transaction_send.print("Driver: Transacción esperando en la fifo de entrada el pop del DUT"); //si aun no esta listo el dut, se espera
                        end
                    end                
                end 

                reset: begin
                    fifo_in.delete();
                    transaction_send.print("Driver: Transacción reset ejecutada");
                    $display("Driver: FIFO de entrada limpiada en reset");
                end
 
                default: begin
                    $display("[%g] Driver Error: la transacción recibida no tiene tipo válido", $time);
                    $finish;
                end
            endcase
        end
    endtask
endclass