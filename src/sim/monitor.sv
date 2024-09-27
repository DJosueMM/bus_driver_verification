class monitor # (parameter WIDTH = 16, MNT_ID = 0);
 
    mbx_monitor_checker mnt_ckecker_mbx;  
    
    virtual fifo_if_out #(.width(WIDTH)) vif_fifo_agent_checker;
    virtual fifo_if_in #(.width(WIDTH)) vif_fifo_dut;

    logic [WIDTH - 1 : 0] fifo_out [$];

    task run();
        
        $display("[%g] El monitor fue inicializado", $time);
        
        @(posedge vif_fifo_agent_checker.clk);
        forever begin

            instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_receive;
            vif_fifo_agent_checker.pndg    = '0;
            vif_fifo_agent_checker.pop     = '0;
            vif_fifo_agent_checker.dpop   = '0;
            $display("[ %g ] El Monitor espera por una transacción", $time);

       
            @(posedge vif_fifo_agent_checker.clk); begin
                //agregar logica de estar muestreando la senal de pndg de la fifo de salida emulada
                //cuando hay un dato hacer el pop en la interfaz vif_fifo_agent_checker
                
                @(posedge vif_fifo_dut); begin
                    if (vif_fifo_dut.push == 1) begin
                        fifo_out.push_front(vif_fifo_dut.dpush);
                    end
                        //se comprueba si hay datos pendientes para entrar al dut en la fifo de salida
                    if (fifo_out.size() == 0) begin
                        vif_fifo_agent_checker.pndg = 0;
                    end

                    else begin
                        vif_fifo_agent_checker.pndg = 1;
                        vif_fifo_agent_checker.dpop = fifo_out[$];
                        vif_fifo_agent_checker.pop = 1;
                        vif_fifo_agent_checker.dpop = fifo_in.pop_back();

                        transaction_receive.receive_time = $time;
                        transaction_receive.receiver_monitor = MNT_ID;
                        transaction_receive.pkg_id = vif_fifo_agent_checker.dpop[WIDTH-1:WIDTH-8];
                        transaction_receive.pkg_payload = vif_fifo_agent_checker.dpop[WIDTH-9:0];
                        
                        if (transaccion_receive.pkg_id == 8'b11111111) begin
                            transaction_receive.tipo_transaccion = broadcast;
                        end
                        else begin
                            transaction_receive.tipo_transaccion = send;
                        end

                        transaccion_receive.delay = 0;
                        transaccion_receive.max_delay = 0;
                        transaction_receive.print("Driver: Transacción recibida en el monitor");
                        mnt_ckecker_mbx.put(transaction_receive);
                    end      
                end
            end
        end
    endtask
endclass

