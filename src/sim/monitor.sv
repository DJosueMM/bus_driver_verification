class monitor # (parameter WIDTH = 16, parameter DRVS = 8);
 
    mbx_monitor_checker mnt_ckecker_mbx;  
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_monitor_fifo_dut;

    int mnt_id;
    //logic [WIDTH - 1 : 0] fifo_out [$];
    logic [WIDTH - 1 : 0] aux_reconstr;
    localparam shift_aux = WIDTH - 8;

    function new(int monitor_id = 0);
        this.mnt_id = monitor_id;
    endfunction

    task run();
        
        $display("[%g] El monitor [%g] fue inicializado", $time, mnt_id);
        
        vif_monitor_fifo_dut.push   [0][mnt_id] = '0;
        vif_monitor_fifo_dut.D_push [0][mnt_id] = '0;
        
        @(posedge vif_monitor_fifo_dut.clk);

        forever begin

            instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_receive;
            
            $display("[%g] El Monitor [%g] espera por una transacción", $time, mnt_id);

            @(posedge vif_monitor_fifo_dut.clk);

                if (vif_monitor_fifo_dut.push[0][mnt_id] == 1) begin
                                      
                    $display("[%g] El Monitor [%g] obtuvo un dato del DUT", $time, mnt_id);
                    
                    transaction_receive= new();
                    
                    assign transaction_receive.pkg_id = {{shift_aux{1'b0}}, vif_monitor_fifo_dut.D_push};
                    assign transaction_receive.pkg_payload = vif_monitor_fifo_dut.D_push;
                    transaction_receive.receive_time = $time;
                    transaction_receive.receiver_monitor = mnt_id;

                    if (transaction_receive.pkg_id == 8'b11111111) begin
                        transaction_receive.tipo_transaccion = broadcast;
                    end
                    else begin
                        transaction_receive.tipo_transaccion = send;
                    end
                    
                    transaction_receive.delay = 0;
                    transaction_receive.max_delay = 0;
                    transaction_receive.print("Driver: Transacción reconstruida en el monitor");
                    mnt_ckecker_mbx.put(transaction_receive);
                    transaction_receive.print("Driver: Transacción enviada al Checker");
                    $display("[%g] El Monitor [%g] envio la transaccion al Checker", $time, mnt_id);
                end
            end
    endtask
endclass