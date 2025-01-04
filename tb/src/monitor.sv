`include "transaction.sv"
class monitor;
  virtual itf_spi_env i_spi;

  mailbox mon2scb;
  function new(virtual itf_spi_env i_spi, mailbox mon2scb);
    this.i_spi   = i_spi;
    this.mon2scb = mon2scb;
  endfunction

  task main;
    forever begin
      transaction trans;
      trans = new();

      @(posedge i_spi.clk);
      wait (!i_spi.SS);
      trans.i_data_p = i_spi.i_data_p;
      trans.data_config = i_spi.data_config;

      if (trans.data_config[28] == 1) begin
        if (trans.data_config[24] == 0) begin
          for (int i = 0; i < 8; i++) begin
            @(posedge i_spi.SCK) trans.o_data_s[i] = i_spi.io_mosi_s;
            #1;
            trans.i_data_s[i] = i_spi.io_miso_s;
          end
        end else begin
          for (int i = 0; i < 8; i++) begin
            @(posedge i_spi.SCK) trans.o_data_s[7-i] = i_spi.io_mosi_s;
            #1;
            trans.i_data_s[7-i] = i_spi.io_miso_s;
          end
        end
      end else begin
        if (trans.data_config[24] == 0) begin
          for (int i = 0; i < 8; i++) begin
            @(posedge i_spi.SCK) trans.o_data_s[i] = i_spi.io_miso_s;
            #1;
            trans.i_data_s[i] = i_spi.io_mosi_s;
          end
        end else begin
          for (int i = 0; i < 8; i++) begin
            @(posedge i_spi.SCK) trans.o_data_s[7-i] = i_spi.io_miso_s;
            #1;
            trans.i_data_s[7-i] = i_spi.io_mosi_s;
          end
        end
      end
      wait (i_spi.SS);
      @(posedge i_spi.clk);
      trans.o_data_p = i_spi.o_data_p;
      @(posedge i_spi.clk);
      mon2scb.put(trans);
    end


  endtask

endclass


