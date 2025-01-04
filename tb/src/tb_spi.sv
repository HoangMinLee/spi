
`include "interface.sv"
`include "test_slave_change_config_interrupt.sv"

module tb_spi;
  bit clk;
  bit rst;

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    #5 rst = 1'b0;
    #13 rst = 1'b1;  
  end
  always #5 clk = ~clk;

  itf_spi_env i_spi (
      clk,
      rst
  );
  test test (i_spi);
  
  spi_module uut (
      .i_sys_clk(i_spi.clk),
      .i_sys_rst(i_spi.rst),
      .i_data(i_spi.i_data_p),
      .io_MISO(i_spi.io_miso_s),
      .i_data_config(i_spi.data_config),
      .i_trans_en(i_spi.trans_en),
      .o_interrupt(i_spi.interupt_request),
      .o_data(i_spi.o_data_p),
      .io_MOSI(i_spi.io_mosi_s),
      .io_SCK(i_spi.SCK),
      .io_SS(i_spi.SS)
  );

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_spi);
  end

endmodule




