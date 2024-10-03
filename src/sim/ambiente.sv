class ambiente #(parameter width = 16, parameter DRVS = 8);

    localparam DRIVERS_Q = DRVS;  // Definición de un parámetro local que indica la cantidad de drivers
    
    // Declaración de los componentes del ambiente
    checker #(.WIDTH(width), .DRVS(DRVS)) checker_inst;  // Instancia del checker, encargado de verificar la salida
    agent   #(.WIDTH(width), .DRVS(DRVS)) agent_inst;    // Instancia del agente, encargado de la comunicación con el driver
    driver  #(.WIDTH(width), .DRVS(DRVS)) driver_inst  [DRVS - 1 : 0];  // Arreglo de instancias de drivers, uno para cada periférico
    monitor #(.WIDTH(width), .DRVS(DRVS)) monitor_inst [DRVS - 1 : 0];  // Arreglo de instancias de monitores, uno para cada periférico

    // Definición de la interface que conecta el DUT
    virtual dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) vif_ambiente_fifo_dut;  // Interfaz virtual para la comunicación con el DUT

    // Declaración de los mailboxes
    mbx_test_agent       test_agent_mbx;                      // Mailbox del test al agente  
    mbx_agent_driver     agent_driver_mbx    [DRVS - 1 : 0];  // Mailbox del agente al driver, uno por driver
    mbx_driver_checker   driver_checker_mbx  [DRVS - 1 : 0];  // Mailbox del driver al checker, uno por driver
    mbx_monitor_checker  monitor_checker_mbx [DRVS - 1 : 0];  // Mailbox del monitor al checker, uno por monitor
    mbx_checker_sb       checker_sb_mbx;                      // Mailbox del checker al scoreboard
    
    // Constructor de la clase ambiente
    function new();
        // Instanciación de los mailboxes
        test_agent_mbx      = new();  // Mailbox para enviar mensajes del test al agente
        checker_sb_mbx      = new();  // Mailbox para la comunicación del checker al scoreboard
        
        // Instanciación de los componentes del ambiente
        for (int i = 0; i < DRVS; i++) begin
            driver_inst         [i] = new(i);  // Instanciación de cada driver con su ID
            //monitor_inst        [i] = new(i);  // Instanciación de cada monitor (comentado)
            agent_driver_mbx    [i] = new();  // Mailbox para la comunicación del agente con el driver
        end

        agent_inst = new();  // Instanciación del agente
        checker_inst = new();  // Instanciación del checker

        // Conexión de las interfaces y mailboxes en el ambiente
        agent_inst.vif_agnt_dut   = vif_ambiente_fifo_dut;  // Conexión del agente con la interfaz del DUT
        checker_inst.vif_checker_fifo_dut = vif_ambiente_fifo_dut;  // Conexión del checker con la interfaz del DUT
        agent_inst.test_agent_mbx = test_agent_mbx;  // Conexión del mailbox del test al agente
        agent_inst.agnt_drv_mbx   = agent_driver_mbx;  // Conexión del mailbox del agente a los drivers
        checker_inst.driver_checker_mbx = driver_checker_mbx;  // Conexión del mailbox del driver al checker
        checker_inst.mnt_checker_mbx = monitor_checker_mbx;  // Conexión del mailbox del monitor al checker
        checker_inst.checker_sb_mbx = checker_sb_mbx;  // Conexión del mailbox del checker al scoreboard

        // Conexión de los drivers y monitores a sus respectivos mailboxes y la interfaz del DUT
        for (int c = 0; c < DRVS; c++) begin
            // Driver
            driver_inst[c].agnt_drv_mbx        = agent_driver_mbx  [c];  // Mailbox del agente al driver
            driver_inst[c].vif_driver_fifo_dut = vif_ambiente_fifo_dut;  // Conexión del driver con la interfaz del DUT
            
            // Monitor
            monitor_inst[c].mnt_ckecker_mbx      = monitor_checker_mbx [c];  // Mailbox del monitor al checker
            monitor_inst[c].vif_monitor_fifo_dut = vif_ambiente_fifo_dut;  // Conexión del monitor con la interfaz del DUT
        end
    endfunction

    // Tarea principal que ejecuta el ambiente
    virtual task run();
        $display("[%g] El ambiente fue inicializado",$time);  // Mensaje de inicialización
        fork
            agent_inst.run();  // Ejecución del agente
            checker_inst.run();  // Ejecución del checker

            // Ejecución de los drivers y monitores en paralelo
            for (int j = 0; j < DRIVERS_Q; j++) begin
                fork     
                    automatic int a = j;    //se declara como variable automatica para que no se mantenga el valor de j final
                    driver_inst[a].run();  // Ejecución del driver j
                    monitor_inst[a].run();  // Ejecución del monitor j
                join_none
            end
        join_none
    endtask
endclass
