class secuencer #(parameter width = 16, parameter DRVS = 8);

    mbx_test_agent test_agent_mbx;

    parameter num_transacciones = 5;
    parameter max_retardo = 4;

    instrucciones_agente instr_agent;

    // Definición del ambiente de la prueba
    ambiente #(.width(width),.DRVS(DRVS)) ambiente_inst;

    // Definición de la interface a la que se conectará el DUT
    virtual dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) vif_test_fifo_dut;

    // definición de las condiciones iniciales del test
    function new();
        // instanciación de los mailboxes
        test_agent_mbx = new();

        // Definición y conexión del driver
        ambiente_inst = new();
        ambiente_inst.vif_ambiente_fifo_dut = vif_test_fifo_dut;
        ambiente_inst.test_agent_mbx = test_agent_mbx;
        ambiente_inst.agent_inst.test_agent_mbx = test_agent_mbx;
        ambiente_inst.agent_inst.num_transacciones = num_transacciones;
        ambiente_inst.agent_inst.max_retardo = max_retardo;
        
    endfunction

    task run;
        $display("[%g] El Test fue inicializado", $time);
        fork
            ambiente_inst.run();
        join_none


        vif_test_fifo_dut.reset = 1;
        #30;
        vif_test_fifo_dut.reset = 0;

        instr_agent = init;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Comenzando la inicializacion", $time);
        
        #1000;

        instr_agent = send_random_payload_legal_id;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada la primera instruccion al agente llenado aleatorio con num_transacciones %g", $time,num_transacciones);

        #20000
        $display("[%g] Test: Se alcanza el tiempo limite de la prueba", $time);
        #20
        $finish;
    endtask
endclass