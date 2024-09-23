`timescale 1ns/1ps
`include "../rtl/Library.sv"
`include "interface_transactions.sv"
`include "driver.sv"
`include "monitor.sv"
//`include "checker.sv"
//`include "score_board.sv"
`include "agent.sv"
`include "ambiente.sv"
`include "test.sv"

//-----------------------------------------------//
// Modulo para correr la prueba //
//-----------------------------------------------//

module test_bench;

  logic clk = 0;
  parameter width = 16;
  parameter DRVS  = 8;

  test #( .depth(depth), .width(width) ) test_0;

  dut_compl_if #(.width(width), .drvrs(DRVS)) _if(.clk(clk));
  
  always #10 clk = ~clk;

    //BUS DRIVER    
    bs_gnrtr_n_rbtr #(.pckg_sz(width), .drvs(DRVS)) DUT (
        .clk      (clk),
        .reset    (),
        .pndng    (_if.pndng),
        .push     (_if.push),
        .pop      (_if.pop),
        .D_pop    (_if.D_pop),
        .D_push   (_if.D_push)
    );

  initial begin
    clk = 0;
    test_0 = new();
    test_0._if = _if;
    test_0.ambiente_inst.driver_inst.vif = _if;
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