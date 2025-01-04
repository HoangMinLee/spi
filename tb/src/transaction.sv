`ifndef my_transaction
`define my_transaction
class transaction;
  randc bit [7:0] i_data_p;
  randc bit [7:0] i_data_s;
  bit [31:0] data_config;
  bit trans_en;
  bit interupt_request;
  bit [7:0] o_data_p;
  bit [7:0] o_data_s;
  bit SCK;
  bit SS;

  function void display(string tag = "");
    $display("time: %0t [%s] i_data_p: %h, i_data_s: %h, o_data_p: %h, o_data_s: %h", $time, tag,
             i_data_p, i_data_s, o_data_p, o_data_s);

  endfunction
  function transaction copy_data();
    transaction trans;
    trans = new();
    trans.i_data_p = this.i_data_p;
    trans.i_data_s = this.i_data_s;
    trans.data_config = this.data_config;
    trans.o_data_p = this.o_data_p;
    trans.o_data_s = this.o_data_s;
    return trans;
  endfunction



endclass
`endif
