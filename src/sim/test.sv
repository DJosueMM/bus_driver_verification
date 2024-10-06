class test #(parameter width = 16, parameter DRVS = 8);

    mbx_test_agent test_agent_mbx;
    mbx_test_sb    test_sb_mbx;

    parameter num_transacciones = 200;
    parameter max_retardo = 10;

    instrucciones_agente instr_agent;
    consulta_sb consulta_test_sb;

    // Definición del ambiente de la prueba
    ambiente #(.width(width),.DRVS(DRVS)) ambiente_inst;

    // Definición de la interface a la que se conectará el DUT
    virtual dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) vif_test_fifo_dut;

    // definición de las condiciones iniciales del test
    function new();
        // instanciación de los mailboxes
        test_agent_mbx = new();
        test_sb_mbx    = new();
        // Definición y conexión del driver
        ambiente_inst = new();
        ambiente_inst.sb_inst.test_sb_mbx = test_sb_mbx;
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
        
        //inicializacion del dut

        vif_test_fifo_dut.reset = 1;
        #30;
        vif_test_fifo_dut.reset = 0;

        instr_agent = init;
        test_agent_mbx.put(instr_agent);
        $display("\n[%g] Test: Comenzando la inicializacion", $time);
        
        #1000;

        //envios random, para comprobar el funcionamiento general del dut

        instr_agent = send_random_payload_legal_id;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada instruccion al agente send_random_payload_legal_id con num_transacciones %g", $time, num_transacciones);
        

        //comprobacion de transacciones con destinos inexistentes
        #2550;

        instr_agent = send_random_payload_ilegal_id;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada instruccion al agente send_random_payload_ilegal_id con num_transacciones %g", $time, num_transacciones);

        //comprobacion de autosend para correcto descarte
        #2550;

        instr_agent = auto_send_random;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada instruccion al agente auto_send_random con num_transacciones %g", $time, num_transacciones);


        //comprobacion de rafaga de send de un solo driver
        #2550;

        instr_agent = consecutive_send;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada instruccion al agente consecutive_send con num_transacciones %g", $time, num_transacciones);


        //todos le envian a uno solo
        #2550;

        instr_agent = all_for_one;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada instruccion al agente all_for_one con num_transacciones %g", $time, num_transacciones);

        //todos enviando random
        #2550;

        instr_agent = all_sending_random;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada instruccion al agente all_sending_random con num_transacciones %g", $time, num_transacciones);


        //todos hacen broadcast
        #2550;

        instr_agent = all_broadcast;
        test_agent_mbx.put(instr_agent);
        $display("[%g] Test: Enviada instruccion al agente all_broadcast con num_transacciones %g", $time, num_transacciones);
        
    
        
        #300000;
        $display("\n////////////////////////////////////////////////////////////////////////////////////////");
        $display("[%g] Test: para finalizar la prueba, se envia tarea de comprobacion final al checker", $time);
        $display("////////////////////////////////////////////////////////////////////////////////////////\n");
        ambiente_inst.checker_inst.revisar_datos_descartados();
        consulta_test_sb = complete_report;
        test_sb_mbx.put(consulta_test_sb);
        $display("[%g] Test: Se alcanza el tiempo limite de la prueba", $time);
        ambiente_inst.sb_inst.close_csv();
        #20
        $finish;
    endtask
endclass