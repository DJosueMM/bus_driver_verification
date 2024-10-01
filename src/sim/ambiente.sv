
class ambiente #(parameter width = 16, parameter DRVS = 8);

    // Declaración de los componentes del ambiente
    agent   #(.WIDTH(width), .DRVS(DRVS)) agent_inst;

    driver  #(.width(width),.DRVS(DRVS)) driver_inst [DRVS];
    //monitor #(.WIDTH(width), .MNT_ID(DRVS)) monitor_inst [DRVS];


    // Definición de la interface que conecta el DUT
    virtual dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) vif_fifo_dut;
    //virtual fifo_if_in  #(.width(width)) _dut_monitor_if  [DRVS];

    // declaración de los mailboxes
    mbx_test_agent       test_agent_mbx;                      // mailbox del test al agente         
    mbx_agent_driver     agent_driver_mbx    [DRVS - 1 : 0];  // mailbox del agente al driver
    //mbx_driver_checker   driver_checker_mbx  [DRVS - 1 : 0];  // mailbox del driver al checker
    //mbx_monitor_checker  monitor_checker_mbx [DRVS - 1 : 0];  // mailbox del monitor al checker
    //mbx_checker_sb       checker_sb_mbx;                       // mailbox del checker al scoreboard
    //mbx_test_sb          test_sb_mbx;                          // mailbox del test al scoreboard


    function new();
        // Instanciación de los mailboxes
        test_agent_mbx      = new();
        //driver_checker_mbx  = new();
        //monitor_checker_mbx = new();
        //checker_sb_mbx      = new();
        //test_sb_mbx         = new();

        // Instanciación de los componentes del ambiente
        for (int i = 0; i < DRVS; i++) begin
            automatic int b = i;
            driver_inst[b] = new(b);
            agent_driver_mbx[b] = new();
            //monitor_inst[i] = new();
        end

        agent_inst = new();

        //checker_inst = new();
        //scoreboard_inst = new();

        // Conexión de las interfaces y mailboxes en el ambiente
        //agent_inst.vif_agnt_dut = vif_fifo_dut;
        agent_inst.test_agent_mbx = test_agent_mbx;
        agent_inst.agnt_drv_mbx   = agent_driver_mbx;

        for (int c = 0; c < DRVS; c++) begin
            //automatic int c = d;
            //driver mbx
            driver_inst[c].agnt_drv_mbx = agent_driver_mbx[c];
            //driver_inst[c].drv_chkr_mbx = driver_checker_mbx[c];
            //interface con driver
            driver_inst[c].vif_fifo_dut = vif_fifo_dut;
            //monitor mbx
            //monitor_inst[c].mnt_ckecker_mbx = monitor_checker_mbx[c];
            //interface con monitor
            //monitor_inst[c].vif_fifo_dut = _dut_monitor_if [c];
        end
    endfunction

    virtual task run();
        $display("[%g] El ambiente fue inicializado",$time);
        fork
            for (int f = 0; f < DRVS; f++) begin
                
                automatic int a = f;
                driver_inst[a].run();
                //monitor_inst[a].run();
            end
            agent_inst.run();
            //checker_inst.run();
            //scoreboard_inst.run();
        join_none
    endtask
endclass