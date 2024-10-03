`timescale 1ns/1ps
`include "Library.sv"
`include "interface_transactions.sv"
`include "checker.sv"
`include "driver.sv"
//`include "monitor.sv"
`include "agent.sv"
`include "ambiente.sv"
`include "secuencer.sv"

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

  //BUS DRIVER    
  bs_gnrtr_n_rbtr # (.pckg_sz(width), .drvrs(DRVS)) DUT (
      .clk      (clk),
      .reset    (final_if.reset),
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
    for (int w = 0; w < DRVS; w++) begin
      test_0.ambiente_inst.checker_inst.vif_checker_fifo_dut    = final_if;
      test_0.ambiente_inst.driver_inst[w].vif_driver_fifo_dut   = final_if;
      test_0.ambiente_inst.agent_inst.vif_agnt_dut              = final_if;
      //test_0.ambiente_inst.monitor_inst[w].vif_monitor_fifo_dut = final_if;
      test_0.vif_test_fifo_dut                                  = final_if;
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