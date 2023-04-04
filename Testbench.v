// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module tb_uart_Communication;
  
  reg Clk; // 50 MHz
  reg reset;
  reg [2:0] baud_select = 3'b011;
  reg Tx_WR; 
  reg Tx_EN = 1;
  //reg [7:0] Tx_DATA = 8'b10001010; //8-
  
  reg [7:0] System_Data = 8'b10001010; //8-
  //reg [7:0] Tx_DATA = 8'b01010001;
  
  wire Tx_BUSY;
  reg RxD = 1'bz;
  
  integer Tx_BUSY_counter = 0;
   reg Rx_EN = 1;
   //wire Rx_PERROR;
   //wire Rx_FERROR;
   wire Rx_VALID;
   //wire [7:0] Rx_DATA;
  
  wire [6:0] Led_Disp;
  wire [3:0] anode;
  
  
  UART_Segment7 UART_Segment7_instance(Clk, reset, baud_select, Tx_WR, Tx_EN, System_Data, Rx_EN, Tx_BUSY, Rx_VALID, Led_Disp, anode);
  
  initial 
   begin
       $dumpfile("dump.vcd"); $dumpvars;
     Clk = 1'b0;
     Tx_WR = 1'b1;
   reset = 1;
     #10 reset = 0;
     #10 reset = 1;
     #20 Tx_WR <= 0;
   end
	
  always
    begin
      #10 Clk = ~Clk;
    end
  
  always@(Tx_BUSY)
    begin      
      if (Tx_BUSY_counter ==1)
        begin
          System_Data <= 8'b11111111; 
        end
      
      if(Tx_BUSY_counter == 2)
        begin
          Tx_WR = 1'b1;
          #20 Tx_WR <= 0;
        end
        Tx_BUSY_counter  = Tx_BUSY_counter +1; 
    end
  
  
  initial
  #10000000 $finish;
  
endmodule