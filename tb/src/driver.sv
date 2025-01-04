`include "transaction.sv"
`define DRIV_ITF i_spi.DRIVER.driver_cb
class driver;
  int no_transaction;
  virtual itf_spi_env i_spi;
  mailbox gen2driv;
  function new(virtual itf_spi_env i_spi, mailbox gen2driv);
    this.i_spi = i_spi;
    this.gen2driv = gen2driv;
  endfunction
  // reset
  task reset;
    wait (i_spi.rst);
    `DRIV_ITF.i_data_p  <= 8'bz;
    `DRIV_ITF.io_miso_s <= 8'bz;
    `DRIV_ITF.io_mosi_s <= 8'bz;
    `DRIV_ITF.trans_en  <= 1'b0;
    wait (!i_spi.rst);
  endtask

  task driver;
    transaction trans;
    gen2driv.get(trans);

    @(posedge i_spi.DRIVER.clk);
    `DRIV_ITF.data_config <= trans.data_config;
    if (trans.data_config[28] == 1) begin
	if(trans.data_config[7:0] >= 8'h37) begin
      	repeat (1200) @(i_spi.DRIVER.clk);
	end else begin
	 repeat (10) @(i_spi.DRIVER.clk);
	end
      `DRIV_ITF.i_data_p  <= trans.i_data_p;
      `DRIV_ITF.trans_en  <= 1'b1;
      `DRIV_ITF.io_miso_s <= 8'b0;
      if (trans.data_config[24] == 0) begin
        for (int i = 0; i < 8; i++) begin
          @(posedge i_spi.SCK) `DRIV_ITF.io_miso_s <= trans.i_data_s[7-i];
        end
      end else begin
        for (int i = 0; i < 8; i++) begin
          @(posedge i_spi.SCK) `DRIV_ITF.io_miso_s <= trans.i_data_s[i];
        end
      end
      trans.interupt_request = `DRIV_ITF.interupt_request;
	if(trans.data_config[7:0] >= 8'h37) begin
      	repeat (1200) @(i_spi.DRIVER.clk);
	end else begin
	 repeat (10) @(i_spi.DRIVER.clk);
	end
      `DRIV_ITF.trans_en <= 1'b0;
      no_transaction++;
    end else begin  //slave
      `DRIV_ITF.SS <= 1'b1;
      repeat (10) @(i_spi.DRIVER.clk);
      `DRIV_ITF.io_mosi_s <= 1'b0;
      `DRIV_ITF.i_data_p <= trans.i_data_p;
      `DRIV_ITF.SS <= 1'b0;
      for (int i = 0; i < 8; i++) begin
        `DRIV_ITF.SCK <= 1'b0;
        @(posedge i_spi.DRIVER.clk);
        @(posedge i_spi.DRIVER.clk);
        `DRIV_ITF.SCK <= 1'b1;
        if (trans.data_config[24] == 0) begin  // trans msb or lsb  
          `DRIV_ITF.io_mosi_s <= trans.i_data_s[7-i];
        end else begin
          `DRIV_ITF.io_mosi_s <= trans.i_data_s[i];
        end
        @(posedge i_spi.DRIVER.clk);
        @(posedge i_spi.DRIVER.clk);

      end
      `DRIV_ITF.SCK <= 1'b0;
      #20;
      `DRIV_ITF.SS <= 1'b1;
      no_transaction++;
    end

  endtask
  task main;
    fork
      begin
        wait (i_spi.rst);
      end
      begin
        forever driver();
      end

    join_any
  endtask
endclass

