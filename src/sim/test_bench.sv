`timescale 1ns/1ps
`include "Library.sv"
`include "interface_transactions.sv"
`include "driver.sv"
//`include "monitor.sv"
`include "agent.sv"
`include "ambiente.sv"
`include "secuencer.sv"
//`include "checker.sv"
//`include "score_board.sv"

//-----------------------------------------------//
// Modulo para correr la prueba //
//-----------------------------------------------//

module test_bench;

  logic     clk   = 0;
  parameter width = 16;
  parameter DRVS  = 8;
  

  secuencer    # (.width(width), .DRVS(DRVS)) test_0;
  dut_compl_if # (.width(width), .drvs(DRVS), .bits(1)) final_if (.clk(clk));
  fifo_if_out  # (.width(width))  _driver_dut_if  [DRVS - 1 : 0] (.clk(clk));
  //fifo_if_in   #(.width(width)) _dut_monitor_if     [DRVS - 1 : 0] (.clk(clk));

  //BUS DRIVER    
  bs_gnrtr_n_rbtr # (.pckg_sz(width), .drvrs(DRVS)) DUT (
      .clk      (clk),
      .reset    (1'b0),
      .pndng    (final_if.pndng),
      .push     (final_if.push),
      .pop      (final_if.pop),
      .D_pop    (final_if.D_pop),
      .D_push   (final_if.D_push)
  );
  
  always #10 clk = ~clk;

  initial begin

    clk    = 0;
    test_0 = new();

    test_0._if = final_if;
        
    for (int d = 0; d < DRVS; d++) begin
      
      automatic int a = d;
      //test_0._driver_dut_if[a] = _driver_dut_if[a];
      //interfases individuales al la interfaz completa
      test_0.ambiente_inst._compl_dut_if_.pndng[0][a] = test_0.ambiente_inst._driver_dut_if [a].pndg;
      //test_0.ambiente_inst._compl_dut_if_.push [0][a] = test_0.ambiente_inst._dut_monitor_if[a].push;
      test_0.ambiente_inst._compl_dut_if_.pop  [0][a] = test_0.ambiente_inst._driver_dut_if [a].pop;
      //test_0.ambiente_inst._compl_dut_if_.dpush[0][a] = test_0.ambiente_inst._dut_monitor_if[a].dpush;
      test_0.ambiente_inst._compl_dut_if_.D_pop [0][a] = test_0.ambiente_inst._driver_dut_if [a].dpop;
    end
    fork
      test_0.run();
    join_none
  
  end

  always @(posedge clk) begin
    if ($time > 100000) begin
      $display("Test_bench: Tiempo límite de prueba en el test_bench alcanzado");
      $finish;
    end
  end

endmodule