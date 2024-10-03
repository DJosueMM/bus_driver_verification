
class ambiente #(parameter width = 16, parameter DRVS = 8);

    localparam DRIVERS_Q = DRVS;
    // Declaración de los componentes del ambiente

    score_board #(.WIDTH(width), .DRVS(DRVS)) sb_inst;
    checker     #(.WIDTH(width), .DRVS(DRVS)) checker_inst;
    agent       #(.WIDTH(width), .DRVS(DRVS)) agent_inst;
    driver      #(.WIDTH(width), .DRVS(DRVS)) driver_inst  [DRVS - 1 : 0];
    monitor     #(.WIDTH(width), .DRVS(DRVS)) monitor_inst [DRVS - 1 : 0];
    
    


    // Definición de la interface que conecta el DUT
    virtual dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) vif_ambiente_fifo_dut;


    // declaración de los mailboxes
    mbx_test_agent       test_agent_mbx;                      // mailbox del test al agente         
    mbx_agent_driver     agent_driver_mbx    [DRVS - 1 : 0];  // mailbox del agente al driver
    mbx_driver_checker   driver_checker_mbx  [DRVS - 1 : 0];  // mailbox del driver al checker
    mbx_monitor_checker  monitor_checker_mbx [DRVS - 1 : 0];  // mailbox del monitor al checker
    mbx_checker_sb       checker_sb_mbx;                       // mailbox del checker al scoreboard
    mbx_checker_sb       chkr_sb_mbx;     
    mbx_test_sb          test_sb_mbx; 


    function new();
        // Instanciación de los mailboxes
        test_agent_mbx      = new();
        checker_sb_mbx      = new();
        chkr_sb_mbx         = new();
        test_sb_mbx         = new();

        // Instanciación de los componentes del ambiente
        for (int i = 0; i < DRVS; i++) begin

            driver_inst         [i] = new(i);
            monitor_inst        [i] = new(i);

            agent_driver_mbx    [i] = new();
            driver_checker_mbx  [i] = new();
            monitor_checker_mbx [i] = new();
        end

        agent_inst = new();
        checker_inst = new();
        sb_inst = new();

        // Conexión de las interfaces y mailboxes en el ambiente
        sb_inst.vif_sb_fifo_dut   = vif_ambiente_fifo_dut;
        sb_inst.chkr_sb_mbx       = checker_sb_mbx;
        sb_inst.test_sb_mbx       = test_sb_mbx;
        agent_inst.vif_agnt_dut   = vif_ambiente_fifo_dut;
        checker_inst.vif_checker_fifo_dut = vif_ambiente_fifo_dut;
        agent_inst.test_agent_mbx = test_agent_mbx;
        agent_inst.agnt_drv_mbx   = agent_driver_mbx;
        checker_inst.driver_checker_mbx = driver_checker_mbx;
        checker_inst.mnt_checker_mbx = monitor_checker_mbx;
        checker_inst.checker_sb_mbx = checker_sb_mbx;

        for (int c = 0; c < DRVS; c++) begin
          
            //driver
            driver_inst[c].agnt_drv_mbx        = agent_driver_mbx  [c];
            driver_inst[c].drv_chkr_mbx        = driver_checker_mbx[c];
            driver_inst[c].vif_driver_fifo_dut = vif_ambiente_fifo_dut;
            
            //monitor
            monitor_inst[c].mnt_ckecker_mbx      = monitor_checker_mbx [c];
            monitor_inst[c].vif_monitor_fifo_dut = vif_ambiente_fifo_dut;

        end
    endfunction

    virtual task run();
        $display("[%g] El ambiente fue inicializado",$time);
        fork
            agent_inst.run();
            checker_inst.run();
            sb_inst.run();

            for (int j = 0; j < DRIVERS_Q; j++) begin
                fork     
                    automatic int a = j;
                    driver_inst[a].run();
                    monitor_inst[a].run();
                join_none
            end
        join_none
    endtask
endclass