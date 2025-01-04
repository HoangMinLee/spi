`include "transaction.sv"

class scoreboard;
  mailbox mon2scb;
  int no_transaction;
  function new(mailbox mon2scb);
    this.mon2scb = mon2scb;
  endfunction
  task main;
    transaction trans;
    forever begin
      mon2scb.get(trans);
          if ((trans.i_data_p == trans.o_data_s) && (trans.i_data_s == trans.o_data_p)) begin
            trans.display("PASSED");
          end else begin
            trans.display("FAILED");
          end
          no_transaction++;
  
      end
  endtask


endclass

