
class driver # (parameter WIDTH = 16);

    mbx_agent_driver agnt_drv_mbx;     
    mbx_driver_checker drv_chkr_mbx;
    
    virtual fifo_if_in  #(.width(WIDTH)) vif_fifo_agent_checker;
    virtual fifo_if_out #(.width(WIDTH)) vif_fifo_dut;

    logic [WIDTH - 1 : 0] fifo_in [$];

    int espera;

    task run();
        
        $display("[%g] El driver fue inicializado", $time);
        
        @(posedge vif_fifo_agent_checker.clk);
        forever begin

            instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_send;
            vif_fifo_agent_checker.push    = '0;
            vif_fifo_agent_checker.rst     = '0;
            vif_fifo_agent_checker.dpush   = '0;
            vif_fifo_dut.pndg              = '0;
            vif_fifo_dut.pop               = '0;
            vif_fifo_dut.dpop              = '0;

            $display("[ %g ] El Driver espera por una transacción", $time);

            espera = 0;
            
            @(posedge vif_fifo_agent_checker.clk); begin
                agnt_drv_mbx.get(transaction_send);
                transaction_send.print("Driver: Transacción recibida en el driver");
                $display("Transacciones pendientes en el mbx agnt_drv = %g", agnt_drv_mbx.num());
            end

            while (espera < transaction_send.retardo) begin
                    @(posedge vif_fifo_agent_checker.clk); begin
                        espera = espera + 1;
                        vif_fifo_agent_checker.dpush = {transaction_send.pkg_id, transaction_send.pkg_payload};
                    end
            end

            case (transaction_send.tipo_transaccion)

                send: begin
          
                    @(posedge vif_fifo_agent_checker.clk); begin
                        vif_fifo_agent_checker.rst  = 0;
                        vif_fifo_agent_checker.push = 1;

                        if (vif_fifo_agent_checker.push == 1) begin
                            fifo_in.push_front(vif_fifo_agent_checker.dpush);  //aqui se lo metemos a la fifo de entrada
                            transaction_send.print("Driver: Transacción send enviada a la FIFO de entrada");
                        end

                        else begin
                            transaction_send.print("ERROR_Driver: Transacción no ha sido enviada a la FIFO"); //si aun no esta listo el dut, se espera
                        end

                        //se comprueba si hay datos pendientes para entrar al dut en la fifo de entrada
                        if (fifo_in.size() == 0)
                            vif_fifo_dut.pndg = 0;

                        else vif_fifo_dut.pndg = 1;

                        //se conecta la fifo de entrada con el dut por vif_fifo_dut
                        vif_fifo_dut.dpop = fifo_in[$];
                        
                        //me quedo esperando a que el bus atienda al driver
                        while (vif_fifo_dut.pop == 0) begin
                            @(posedge vif_fifo_dut.clk);
                        end
                         
                        //se envia al dut la info
                        if (vif_fifo_dut.pop == 1) begin
                            vif_fifo_dut.dpop = fifo_in[$];
                            transaction_send.send_time = $time;
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada"); //al enviar al dut, se mete en send time con $time
                            drv_chkr_mbx.put(transaction_send); //se envia al checker
                            vif_fifo_dut.dpop = fifo_in.pop_back();
                        end

                        else begin
                            transaction_send.print("Driver: Transacción esperando en la fifo de entrada el pop del DUT"); //si aun no esta listo el dut, se espera
                        end
                    end                
                end 

                broadcast: begin
          
                    @(posedge vif_fifo_agent_checker.clk); begin
                        vif_fifo_agent_checker.rst  = 0;
                        vif_fifo_agent_checker.push = 1;

                        if (vif_fifo_agent_checker.push == 1) begin
                            fifo_in.push_front(vif_fifo_agent_checker.dpush);  //aqui se lo metemos a la fifo de entrada
                            transaction_send.print("Driver: Transacción send enviada a la FIFO de entrada");
                        end

                        else begin
                            transaction_send.print("ERROR_Driver: Transacción no ha sido enviada a la FIFO"); //si aun no esta listo el dut, se espera
                        end

                        //se comprueba si hay datos pendientes para entrar al dut en la fifo de entrada
                        if (fifo_in.size() == 0)
                            vif_fifo_dut.pndg = 0;

                        else vif_fifo_dut.pndg = 1;

                        //se conecta la fifo de entrada con el dut por vif_fifo_dut
                        vif_fifo_dut.dpop = fifo_in[$];
                        
                        //me quedo esperando a que el bus atienda al driver
                        while (vif_fifo_dut.pop == 0) begin
                            @(posedge vif_fifo_dut.clk);
                        end
                         
                        //se envia al dut la info
                        if (vif_fifo_dut.pop == 1) begin
                            vif_fifo_dut.dpop = fifo_in[$];
                            transaction_send.send_time = $time;
                            transaction_send.print("Driver: Transacción enviada al DUT desde la fifo de entrada"); //al enviar al dut, se mete en send time con $time
                            drv_chkr_mbx.put(transaction_send); //se envia al checker
                            vif_fifo_dut.dpop = fifo_in.pop_back();
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