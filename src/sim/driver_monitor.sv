class driver_monitor # (parameter WIDTH = 16);

    mbx_agent_driver_and_monitor_checker agnt_drv_mbx;     
    mbx_agent_driver_and_monitor_checker mnt_ckecker_mbx;  
    
    virtual fifo_if #(.width(WIDTH)) vif_fifo_agent_checker;
    virtual fifo_if #(.width(WIDTH)) vif_fifo_dut;

    int espera;

    task run();
        
        $display("[%g] El driver fue inicializado", $time);
        
        @(posedge vif_fifo_agent_checker.clk);
        forever begin

            instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction;
            vif_fifo_agent_checker.push    = '0;
            vif_fifo_agent_checker.pop     = '0;
            vif_fifo_agent_checker.dpush   = '0;
            $display("[ %g ] El Driver espera por una transacción", $time);
            espera = 0;
            
            @(posedge vif_fifo_agent_checker.clk);
                agnt_drv_mbx.get(transaction);
                transaction.print("Driver: Transacción recibida en el driver");
                $display("Transacciones pendientes en el mbx agnt_drv = %g", agnt_drv_mbx.num());
            end

            while (espera < transaction.retardo) begin
                    @(posedge vif.clk);
                    espera = espera + 1;
                    vif_fifo_agent_checker.dpush = {transaction.pkg_id, transaction.pkg_payload};
                end
            end

            case (transaction.tipo_transaccion)
                send: begin
          
                    @(posedge vif_fifo_agent_checker.clk);
                        vif_fifo_agent_checker.push = 1;
                        vif_fifo_agent_checker.rst  = 0;
                        transaction.print("Driver: Transacción send enviada a la FIFO de entrada");
                    
                    //aqui se lo metemos a la fifo de entrada
                    

                    //se conecta la fifo de entrada con el dut por vif_fifo_dut
                    //al enviar al dut, se mete en send time con $time
                    drv_chkr_mbx.put(transaction);
                
                end 
                broadcast: begin

                    //se repite lo del send
                    vif.push = 1;
                    transaction.tiempo = $time;
                    drv_chkr_mbx.put(transaction);
                    transaction.print("Driver: Transacción broadcast ejecutada");
                end
                reset: begin
                    //se repite lo del send con rst
                    vif.rst = 1;
                    transaction.tiempo = $time;
                    drv_chkr_mbx.put(transaction);
                    transaction.print("Driver: Transacción reset ejecutada");
                end
 
                default: begin
                    $display("[%g] Driver Error: la transacción recibida no tiene tipo válido", $time);
                    $finish;
                end
            endcase

            //agregar logica de estar muestreando la senal de pndg de la fifo de salida emulada
            //cuando hay un dato hacer el pop en la interfaz vif_fifo_agent_checker
            
            @(posedge vif.clk);
        end
    endtask
endclass