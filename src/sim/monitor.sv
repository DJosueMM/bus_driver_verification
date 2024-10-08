class monitor # (parameter WIDTH = 16, parameter DRVS = 8);

    mbx_monitor_checker mnt_ckecker_mbx;  //mailbox del monitor al checker
    virtual dut_compl_if # (.width(WIDTH), .drvs(DRVS), .bits(1)) vif_monitor_fifo_dut; //Interfaz del monitor con el DUT
    
    //transaccion que almacenara lo recibido por el DUT
    instrucciones_driver_monitor #(.WIDTH(WIDTH)) transaction_receive;
    
    //id del monitor
    int mnt_id;
    
    //variable auxiliar para reconstruir la transaccion 
    logic [WIDTH - 1 : 0] aux_reconstr;

    //constructor, inicializa el monitor con el id indicado en el parametro
    function new(int monitor_id = 0);
        this.mnt_id = monitor_id;
    endfunction

    task run();
        
        $display("[%g] El monitor [%g] fue inicializado", $time, mnt_id);
        
        
        @(posedge vif_monitor_fifo_dut.clk);

            forever begin
                
                //las senales que controla el monitor son push y D_push.
                //se inicializan en 0
                vif_monitor_fifo_dut.push   [0][mnt_id] = '0;
                vif_monitor_fifo_dut.D_push [0][mnt_id] = '0;
                $display("[%g] El Monitor [%g] espera por una transacción", $time, mnt_id);

                @ (posedge vif_monitor_fifo_dut.clk);
                    
                    //mientras no haya una transacción en el DUT, el monitor espera
                    while (vif_monitor_fifo_dut.push[0][mnt_id] == 0) begin
                        @(posedge vif_monitor_fifo_dut.clk);
                    end
                    
                    //si hay una transacción en el DUT, el monitor la recibe
                    if (vif_monitor_fifo_dut.push[0][mnt_id] == 1) begin
                                        
                        $display("[%g] El Monitor [%g] obtuvo un dato del DUT", $time, mnt_id);
                        
                        //se reconstruye la transacción
                        transaction_receive= new();
                        
                        transaction_receive.pkg_id           = vif_monitor_fifo_dut.D_push[0][mnt_id][WIDTH - 1 : WIDTH - 8];
                        transaction_receive.pkg_payload      = vif_monitor_fifo_dut.D_push[0][mnt_id][WIDTH - 9 : 0];
                        transaction_receive.receive_time     = $time; //se le agrega el tiempo de recibido
                        transaction_receive.receiver_monitor = mnt_id; //se le agrega el id del monitor que lo recibio
                        
                        //se evalua el tipo de transaccion, entre send, broadcast
                        if (transaction_receive.pkg_id == 8'b11111111) begin
                            transaction_receive.tipo_transaccion = broadcast;
                        end
                        else begin
                            transaction_receive.tipo_transaccion = send;
                        end
                        
                        //se envia la transacción al checker
                        transaction_receive.delay = 0;
                        transaction_receive.max_delay = 0;
                        $display("[%g] El Monitor [%g] reconstruyo la transaccion", $time, mnt_id);
                        transaction_receive.print("Monitor: Transacción reconstruida en el monitor");
                        mnt_ckecker_mbx.put(transaction_receive);
                        transaction_receive.print("Monitor: Transacción enviada al Checker");
                        $display("[%g] El Monitor [%g] envio la transaccion al Checker", $time, mnt_id);
                    end
            end
    endtask
endclass