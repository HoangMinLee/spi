//=======================================================
// Coppyright (c) 2024 by FPT Semiconductor JSC 
// Project: Design and Verification SPI IP core in ASIC
// Function: All functions refer to SPI Block Guide
//					 by Motorola, Inc., 2001.
// Author	: Vu Tuan Truong, Uyen Phan Tran Minh 
// Intial Date: 03-11-2024
//-------------------------------------------------------
// Code Revision History:
//-------------------------------------------------------
// Ver: | Author |Mod.Date |Changes Made:
// V1.1 | T.Vu   |28/11/24 |Change blocking assignment
//												 |to nonblocking assignment.
//												 |Removed unnecessary code.
// V1.2 | T.Vu   |24/12/24 |Change "cal" variable to  
//												 |wire instead of reg. 
//												 |Add header to this file. 
//												 |Add more explanation to
//												 |code the lines.
//=======================================================

module spi_module (
    input i_sys_clk,
    input i_sys_rst,
    input [31:0] i_data_config,
    input i_trans_en,
    input [7:0] i_data,
    output [7:0] o_data,
    output o_interrupt,
    inout io_SCK,
    inout io_MOSI,
    inout io_MISO,
    inout io_SS
);

  //=====================================================================
  // 		REGISTER CONFIG MASTER - SLAVE 
  //=====================================================================
  reg [7:0] R_SPI_CONTROL_1;
  reg [7:0] R_SPI_CONTROL_2;
  reg [7:0] R_SPI_STATUS;
  reg [7:0] R_SPI_BAUD_RATE;
  reg [7:0] R_SPI_DATA_SHIFT;
  reg [7:0] R_SPI_DATA;


  reg [3:0] counter_i;
  //DIV FREQUENCE CLOCK WITH 
  reg [11:0] R_counter_div;
  reg M_SCK;
  reg M_SS;
  reg [11:0] cal;

  always @(posedge i_sys_clk) begin
    cal <= (R_SPI_BAUD_RATE[6:4] + 1) * (2 ** R_SPI_BAUD_RATE[2:0]) - 1;
    if (!i_sys_rst) begin
      R_counter_div <= 12'b0;
      cal <= 12'b0;
      M_SCK <= 0;
    end
		else if((R_SPI_CONTROL_1[4])&&(R_SPI_CONTROL_1[6]==1)&&(R_SPI_CONTROL_2[1]==0)) begin
      //MASTER - ENABLE SYS - INTERUP EN - CHECK INTERUP - CONDITION COUNTER
      if (!M_SS) begin
        R_counter_div <= R_counter_div + 1'b1;
        if (R_counter_div == cal) begin
          R_counter_div <= 0;
          M_SCK <= !M_SCK; 
        end
      end else M_SCK <= R_SPI_CONTROL_1[3];
    end
  end
  assign io_SCK = (R_SPI_CONTROL_1[4]) ? M_SCK : 1'bZ;




  //=========================================================================
  //		CONFIG MODE MASTER OR SLAVE FOR MODULE
  //=========================================================================
  parameter IDLE = 2'b00;
  parameter MASTER = 2'b01;
  parameter SLAVE = 2'b10;

  reg [1:0] STATUS;

  always @(posedge i_sys_clk) begin
    if (!i_sys_rst) begin
      R_SPI_CONTROL_1 <= 8'b0000100;
      R_SPI_CONTROL_2 <= 8'b0;
      R_SPI_STATUS <= 8'b0010000;
      R_SPI_BAUD_RATE <= 8'b0;
      R_SPI_DATA_SHIFT <= 8'b0;
      R_SPI_DATA <= 8'b0;
      STATUS <= IDLE;
    end else if (STATUS == IDLE) begin  // should be <= instead of =
      R_SPI_CONTROL_1 <= i_data_config[31:24];
      R_SPI_CONTROL_2 <= i_data_config[23:16];
      R_SPI_STATUS <= i_data_config[15:8];
      R_SPI_BAUD_RATE <= i_data_config[7:0];
    end
    if (R_SPI_CONTROL_1[4]) begin
      STATUS <= MASTER;
    end else if (!R_SPI_CONTROL_1[4]) begin
      STATUS <= SLAVE;
    end

  end
  //reg [31:0]reg_data_config;



  //==========================================================
  //	INTERUPT REQUEST IF CONFIG CHANGE AND INTERUPT EN
  //==========================================================
  always @(posedge i_sys_clk) begin
    if (STATUS != IDLE) begin
      if((R_SPI_CONTROL_1 != i_data_config[31:24]) || (R_SPI_CONTROL_2 != i_data_config[23:16]) || (R_SPI_BAUD_RATE != i_data_config[7:0])) begin
        if (R_SPI_CONTROL_1[7] == 0)  //SPIE = 0		
          STATUS <= IDLE;
        else begin
          R_SPI_STATUS[4] <= 1'b1;  //MODF = 1
          R_SPI_CONTROL_1[6] <= 1'b0;  //SPE = 0
        end
      end
    end
  end



  //==========================================================
  //			 MASTER MODE
  // =========================================================
  reg M_MOSI;

  always @(posedge i_sys_clk) begin
    if (!i_sys_rst) begin
      counter_i <= 4'b0;
      M_MOSI <= 1'b0;
      M_SS <= 1'b1;
    end
  end

  always @(posedge i_trans_en) begin
    if (STATUS == MASTER) begin
      M_SS <= 1'b0;
    end
  end


  // DETECTED MODE - DON'T RUN
  // always @(posedge SCK) begin
  //     if((R_SPI_CONTROL_1[6])&&(STATUS == MASTER)) begin
  //         if(R_SPI_CONTROL_2[4]&&(!R_SPI_CONTROL_1[1]))begin //check master detecting erro master
  //             R_SPI_CONTROL_1[4] <= 1'b0;
  //             STATUS <= SLAVE;
  //             R_SPI_STATUS[4] <= 1'b1;
  //         end
  //     end
  // end

  assign io_SS = ((STATUS == MASTER) && (R_SPI_CONTROL_1[1])) ? M_SS : 1'bz;

  //MASTER TRANS
  always @(negedge io_SS) begin
    if (STATUS == MASTER) begin
      counter_i <= 4'b0;
      R_SPI_DATA_SHIFT <= i_data;
      R_SPI_STATUS[7] <= 1'b0;
    end
  end

  always @(posedge io_SS) begin
    if (STATUS == MASTER) begin
      R_SPI_DATA <= R_SPI_DATA_SHIFT;
      R_SPI_STATUS[7] <= 1'b1;
    end
  end

  always @(posedge M_SCK) begin
    if ((!R_SPI_CONTROL_2[0]) && (STATUS == MASTER) && (R_SPI_CONTROL_1[6])) begin  //checl SPC0
      if ((R_SPI_CONTROL_1[2])) begin  // CPHA
        if (R_SPI_CONTROL_1[0] == 1'b1) begin  //LSBFEN = 1
          M_MOSI <= R_SPI_DATA_SHIFT[7];
        end else begin
          M_MOSI <= R_SPI_DATA_SHIFT[0];
        end
      end
    end
  end

  always @(negedge M_SCK) begin
    if ((!R_SPI_CONTROL_2[0]) && (STATUS == MASTER) && (R_SPI_CONTROL_1[6])) begin  //checl SPC0
      if ((R_SPI_CONTROL_1[2]) && (!R_SPI_STATUS[7])) begin  // CPHA
        if (R_SPI_CONTROL_1[0] == 1'b1) begin
          R_SPI_DATA_SHIFT <= {R_SPI_DATA_SHIFT[6:0], io_MISO};
        end else begin
          R_SPI_DATA_SHIFT <= {io_MISO, R_SPI_DATA_SHIFT[7:1]};
        end
        counter_i <= counter_i + 1;
        if (counter_i == 7) begin
          M_SS <= 1'b1;
          counter_i <= 0;
        end
      end
    end
  end

  assign o_interrupt = (R_SPI_CONTROL_1[7] && R_SPI_STATUS[4]) ? 1'b1 : 1'b0;
  assign io_MOSI = ((!R_SPI_STATUS[7]) && (STATUS == MASTER)) ? M_MOSI : 1'bz;
  assign o_data = R_SPI_DATA;

  //==========================================================
  // 		SLAVE MODE
  //==========================================================
  wire S_CLK;
  assign S_CLK = io_SCK;
  reg S_MISO;

  always @(negedge io_SS) begin
    if (STATUS == SLAVE) begin
      R_SPI_DATA_SHIFT <= i_data;
      R_SPI_STATUS[7]  <= 1'b0;
    end
  end

  always @(posedge io_SS) begin
    if (STATUS == SLAVE) begin
      R_SPI_DATA <= R_SPI_DATA_SHIFT;
      R_SPI_STATUS[7] <= 1'b1;
    end
  end


  always @(posedge i_sys_clk) begin
    if (!i_sys_rst) begin
      S_MISO <= 1'b0;
    end
  end

  // SLAVE TRANS
  always @(posedge io_SCK) begin

    if ((!R_SPI_CONTROL_2[0]) && (STATUS == SLAVE) && (R_SPI_CONTROL_1[6])) begin  //check SPC0
      if ((R_SPI_CONTROL_1[2]) && (!R_SPI_STATUS[7]) && (!io_SS)) begin  // CPHA
        if (R_SPI_CONTROL_1[0] == 1'b1) S_MISO <= R_SPI_DATA_SHIFT[7];
        else S_MISO <= R_SPI_DATA_SHIFT[0];
      end
    end
  end

  always @(negedge io_SCK) begin
    if ((!R_SPI_CONTROL_2[0]) && (STATUS == SLAVE) && (R_SPI_CONTROL_1[6])) begin  //checl SPC0
      if ((R_SPI_CONTROL_1[2]) && (!R_SPI_STATUS[7]) && (!io_SS)) begin  // CPHA
        if (R_SPI_CONTROL_1[0] == 1'b1) R_SPI_DATA_SHIFT <= {R_SPI_DATA_SHIFT[6:0], io_MOSI};
        else R_SPI_DATA_SHIFT <= {io_MOSI, R_SPI_DATA_SHIFT[7:1]};
      end
    end
  end

  assign io_MISO = ((STATUS == SLAVE) && (!R_SPI_STATUS[7])) ? S_MISO : 1'bz;

endmodule
//=========================EoF==========================


