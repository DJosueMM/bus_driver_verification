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
            
            @(posedge vif.clk);
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
                    transaction.dato = vif.dato_out;
                    transaction.tiempo = $time;
                    @(posedge vif.clk);
                    vif.pop = 1;
                    drv_chkr_mbx.put(transaction);
                    transaction.print("Driver: Transacción ejecutada");
                end
                broadcast: begin
                    vif.push = 1;
                    transaction.tiempo = $time;
                    drv_chkr_mbx.put(transaction);
                    transaction.print("Driver: Transacción ejecutada");
                end
                reset: begin
                    vif.rst = 1;
                    transaction.tiempo = $time;
                    drv_chkr_mbx.put(transaction);
                    transaction.print("Driver: Transacción ejecutada");
                end
 
                default: begin
                    $display("[%g] Driver Error: la transacción recibida no tiene tipo válido", $time);
                    $finish;
                end
            endcase
            @(posedge vif.clk);
        end
    endtask
endclass