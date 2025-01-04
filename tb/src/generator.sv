`include "transaction.sv"
class generator;
  rand transaction trans, tr;
  int repeat_count;
  mailbox gen2driv;
  event ended;
  function new(mailbox gen2driv, event ended);
    this.gen2driv = gen2driv;
    this.ended = ended;
    trans = new();
  endfunction

  task main();
    repeat (repeat_count) begin
      if (!trans.randomize()) begin
        $fatal("trans randomize is failed");
      end 
      tr = trans.copy_data();
      gen2driv.put(tr);

    end
    ->ended;  
  endtask

endclass
