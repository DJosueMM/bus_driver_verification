
class ambiente #(parameter width = 16, parameter DRVS = 8);

    // Declaración de los componentes del ambiente
    agent   #(.WIDTH(width), .DRVS(DRVS)) agent_inst;

    driver  #(.WIDTH(width))                driver_inst [DRVS];
    //monitor #(.WIDTH(width), .MNT_ID(DRVS)) monitor_inst [DRVS];


    // Definición de la interface que conecta el DUT
    virtual fifo_if_out #(.width(width)) _driver_dut_if  [DRVS];
    //virtual fifo_if_in  #(.width(width)) _dut_monitor_if  [DRVS];

    virtual dut_compl_if #(.width(width), .drvs(DRVS)) _compl_dut_if_;

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
        agent_driver_mbx    = new();
        //driver_checker_mbx  = new();
        //monitor_checker_mbx = new();
        //checker_sb_mbx      = new();
        //test_sb_mbx         = new();

        // Instanciación de los componentes del ambiente
        for (int i = 0; i < DRVS; i++) begin
            driver_inst[i] = new();
            //monitor_inst[i] = new();
        end

        agent_inst = new();

        //checker_inst = new();
        //scoreboard_inst = new();


        // Conexión de las interfaces y mailboxes en el ambiente
        agent_inst.test_agent_mbx = test_agent_mbx;
        agent_inst.agnt_drv_mbx   = agent_driver_mbx;

        for (int d = 0; d < DRVS; d++) begin

            //driver mbx
            driver_inst[d].agnt_drv_mbx = agent_driver_mbx[d];
            //driver_inst[d].drv_chkr_mbx = driver_checker_mbx[d];
            //interface con driver
            driver_inst[d].vif_fifo_dut = _driver_dut_if [d];
            //monitor mbx
            //monitor_inst[d].mnt_ckecker_mbx = monitor_checker_mbx[d];
            //interface con monitor
            //monitor_inst[d].vif_fifo_dut = _dut_monitor_if [d];
        end
    endfunction

    virtual task run();
        $display("[%g] El ambiente fue inicializado",$time);
        fork
            for (int f = 0; f < DRVS; f++) begin
                
                automatic int a = f;
                driver_inst [a].run();
                //monitor_inst[a].run();
            end
            agent_inst.run();
            //checker_inst.run();
            //scoreboard_inst.run();
        join_none
    endtask
endclass