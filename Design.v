`timescale 1ns/1ps

module UART_Segment7(
    input Clk,
    input reset,
    input [2:0] baud_select,
    
  	//transmitter side
  	input Tx_WR,
  	input Tx_EN,
  	input [7:0] System_Data,
  
  	//Receiver side
  	input Rx_EN,
  
    //transmitter side
    output wire Tx_BUSY,
  
    //Receiver side

    output wire Rx_VALID,
    
  
  //7 Segment Display side
  
  output wire [6:0] Led_Disp,
  output wire [3:0] anode

);
  
  
  wire Rx_FERROR;
  wire Rx_PERROR;
  wire [7:0] Rx_DATA;
  wire [3:0] digit1;
  wire [3:0] digit2;
  wire [3:0] digit3;
  wire [3:0] digit4;
  
  wire TxD;
  wire RxD;
  
  wire [7:0] Tx_DATA;
  
  encoder encoder_instance(System_Data , Tx_DATA);
  
  digit_producer digit_producer_instance(Rx_DATA, Rx_FERROR, Rx_PERROR, digit1 , digit2, digit3, digit4);
  
  TOP TOP_instance(digit1, digit2, digit3, digit4, Clk, reset, Led_Disp, anode);
  
  channel channel_instance(TxD, RxD);
  
  UART_Transmitter UART_Transmitter_Instance(Clk, reset, Tx_WR, Tx_EN, Tx_DATA,
                                             baud_select, Tx_BUSY, TxD);
  
  
  
  UART_Receiver tb_uart_receiver_instance(RxD, Rx_EN, baud_select, Clk, reset,
                                         Rx_PERROR, Rx_FERROR,Rx_VALID,Rx_DATA);
  
endmodule





module channel(
  input TxD,
  output reg RxD  = 1
);
  
  
  always @(TxD)
    begin
      RxD <= TxD;
      
    end
  
endmodule



module parity_generator(
  input [7:0] Data ,
  output reg parity_bit = 0
);
  integer i;
  integer ones;
  // When Number of data equal to 1 is odd, parity_bit = 1
  always@(Data)
    begin
      ones = 0; // Keeps track of number of 1s in Data
      for(i=0; i<8; i = i+1)
        begin
          if (Data[i] == 1)
      ones = ones + 1;
        end
     
     
      if(ones % 2 == 1)
        begin
    parity_bit<=1;
        end
   else begin
    parity_bit<=0;
      end
    end
endmodule



module encoder(
  input [7:0] System_Data,
  output reg [7:0] Tx_DATA = 8'bzzzzzzzz
);
  
  reg [3:0] crypt1 = 4'bzzzz;
  reg [3:0] crypt2 = 4'bzzzz;
  reg [7:0] crypt_packet = 8'bzzzzzzzz;
  integer i = 0;
  
  always @(System_Data)
  	begin
      
      for(i = 0; i < 4; i = i + 1)
        begin
          crypt1[i] = System_Data[i];
          crypt2[i] = System_Data[i+4];
        end
      
       crypt1 = crypt1 + 3;
       crypt2 = crypt2 + 3;
      
         for(i = 0; i < 4; i = i + 1)
        	begin
         	 crypt_packet[i] = crypt1[i];
             crypt_packet[i + 4] = crypt2[i];
        end
      
      Tx_DATA = crypt_packet;
    
  end
    
    
endmodule




module Rx_baud_rate_generator(
  input Clk, //50MHz
  input reset,
  input [2:0] baud_select,
  output reg RX_sample_ENABLE = 0
);

integer counter = 0;
integer baud_rate = 0;
integer max_counter = 0;
  
  
  always @ (baud_select)
    begin 
      case (baud_select)
        3'b000 : baud_rate = 300; 
        3'b001 : baud_rate = 1200;
        3'b010 : baud_rate = 4800;
        3'b011 : baud_rate = 9600;
        3'b100 : baud_rate = 19200; 
        3'b101 : baud_rate = 38400;
        3'b110 : baud_rate = 57600;
        3'b111 : baud_rate = 115200;
        default : baud_rate = 0;
      endcase
    end

  
  
  
  always @ (baud_rate)
    begin
      case (baud_rate)
        //(Tsc = 1/16*baud_rate)
        300    : max_counter = 10416; // 166666/16 rounded down
    
        1200   : max_counter = 2604; //41666/16 rounded down
        
        4800   : max_counter = 651; //10416/16 rounded down
  
        9600   : max_counter = 325; //5208/16 rounded down
      
        19200  : max_counter = 162; //2604/16 rounded down
       
        38400  : max_counter = 81; //1302/16 rounded down
      
        57600  : max_counter = 54; // 828/16 rounded down
        
        115200 : max_counter = 27; // 434/16 rounded down
      
        default : max_counter = 0;
      endcase
    end
  
  
  
  
  always @(posedge Clk or negedge reset)
      begin 
        if (reset == 0)
          begin
            counter <= 0;
            RX_sample_ENABLE <= 0;
          end
        else if (counter == max_counter - 1)
          begin
            RX_sample_ENABLE <= 1;
            counter <= 0;
          end
        else if (counter == 0)
          begin
            RX_sample_ENABLE <= 0;
            counter <= counter + 1;
          end
        else
          counter <= counter + 1;
      end
  
  
  
  
  
  endmodule







module Rx_data_extraction(
  
  input [10:0] packet,
  input packet_completion,
  
  output reg original_parity_bit = 0, //The parity bit which was calculated during the transmission.
  output reg [7:0] Data = 0
  
);
  
  integer i = 0;
  always @ (posedge packet_completion) 
    begin
        original_parity_bit <= packet[9];
        for(i = 0 ; i<8 ; i = i + 1)
           begin
             Data[i] = packet[i + 1]; // Data extraction.
           end      
    end
endmodule



module Rx_data_reception(
  input RxD,
  input Rx_EN,
  input RX_sample_ENABLE,
  output reg [10:0] packet = 11'bzzzzzzzzzzz,
  output reg start_bit_sync = 0,
  
  output reg packet_completion = 0 //Updates to 1 when packet is ready.
);
  integer duration_counter = 0; // Duration of the packet transfer.
  
  integer iteration = 0; //Runs through the packet Array.
  integer sync_counter = 1; //Used to check sampling synchronization
  
  
  integer ones = 0;
  integer zeroes = 0;

      always @(posedge RX_sample_ENABLE)
        begin    
                  
          if(RxD != 1 || duration_counter != 0) // Sampling on the arrival of packet
            begin
              
               if(sync_counter == 1)
                begin
                  zeroes = 0;
                  ones = 0;
                end            

              if(RxD == 1) // Responsible for noise tracking.
               begin 
                ones = ones + 1;
               end
              else
                begin
                  zeroes = zeroes + 1;
                end
              

              if (sync_counter == 16) //8
               begin
                 if(zeroes > ones) // Checking the real value of RxD, despite noise.
                   begin
                     packet[iteration] <= 0;
                   end
                 else
                   begin
                     packet[iteration] <= 1;
                   end
                  iteration = iteration + 1;
                  sync_counter = 0; // Sampling will continue after 16 cycles.
               end



             if (iteration == 11)
              begin
                packet_completion = 1; //Packet has been formed!
                iteration = 0;
                packet_completion = 0;
              end


              if(duration_counter == 16 && RxD ==0) 
                // Ensures that start_bit has arrived!
                begin
                  if (zeroes + ones +15 == duration_counter)
                    // No framing error.
                    begin
                		start_bit_sync <= 1;
                      // At the 8th Rx_sample_Enable beat, the start bit and then 	the whole packet gets sampled.
                    end
                end

              if(duration_counter == 176) 
                // Duration counter will count until the 16th Rx_sample_ENABLE beat  of the 11th bit, which indicates the end of the packet. 
                begin
                  duration_counter = 0;

                  // Resets, in order to start counting for the next packet.

                  start_bit_sync = 0 ;
                  // Resets to zero until the next packet comes. 
                  
                  zeroes = 0; //Reset value for the arrival of the next packet.
                  ones = 0;
                end


              sync_counter = sync_counter +1;
              duration_counter = duration_counter + 1;
            end
        end
   
    
endmodule





module Rx_framing_control(
	input start_bit_sync,
  	output reg Rx_FERROR = 0
);
  
  always @(start_bit_sync)
    begin
      if(start_bit_sync == 1)
        begin
          Rx_FERROR <= 0; // Synchronization is successful.
        end
    end
  
endmodule




module Rx_parity_comparison(
  input original_parity_bit,
  input parity_bit,
  output reg Rx_PERROR = 0
);
  
  always @ (original_parity_bit or parity_bit)
  begin
    if (original_parity_bit == parity_bit)
    begin
      Rx_PERROR <= 0; // No error.
    end
    
    else Rx_PERROR <=1; // Something went wrong
  end
    
  
endmodule




module Rx_validation_control(
  input Rx_FERROR,
  input Rx_PERROR,
  input [7:0] Data,
  output reg [7:0] Rx_DATA = 8'bzzzzzzzz,
  output reg Rx_VALID = 0 
);
  
  
  always @(Data)
    begin
      if(Rx_FERROR == 0 && Rx_PERROR == 0 && Data!=0)
        begin
          Rx_DATA = Data;
          Rx_VALID = 1;
          #20 Rx_VALID = 0;
        end
      
      else
        begin
          Rx_VALID = 0;
        end
    end
  
endmodule


module Tx_baud_rate_generator(
  input Clk, //50MHz
  input reset,
  input [2:0] baud_select,
  output reg TX_sample_ENABLE = 0
);

integer counter = 0;

always @ (posedge Clk or negedge reset)
    begin
      TX_sample_ENABLE <= 0;
     
      if (!reset)
        counter = 0 ;
     
      else
        begin
        case (baud_select)    
          3'b000:
            if (counter == 166666)
              begin
                  TX_sample_ENABLE <= 1;
                  counter = 0;
              end
            else begin
              counter = counter + 1;
            end

          3'b001:
            if (counter == 41666)
              begin
                TX_sample_ENABLE <= 1;
                counter = 0;
              end
            else begin
              counter = counter + 1;
            end
          3'b010:
            if (counter == 10416)
              begin
                TX_sample_ENABLE <= 1;
                counter = 0;
              end
            else begin
              counter = counter + 1;
            end

          3'b011:
            if (counter == 5208)
              begin
                TX_sample_ENABLE <= 1;
                counter <= 0;
              end
            else begin
              counter = counter + 1;
            end

          3'b100:
            if (counter == 2604)
              begin
                TX_sample_ENABLE <= 1;
                counter = 0;
              end
            else begin
              counter = counter + 1;
            end

            3'b101:
              if (counter == 1302)
                 begin
                TX_sample_ENABLE <= 1;
                  counter = 0;
                 end
              else begin
                counter = counter + 1;
              end

          3'b110:
            if (counter == 868)
              begin
                TX_sample_ENABLE <= 1;
                counter = 0;
              end
            else begin
              counter = counter + 1;
            end
         
          3'b111:
            if (counter == 434)
              begin
                TX_sample_ENABLE <= 1;
                counter = 0;
              end
            else begin
              counter = counter + 1;
            end
        endcase
        end
    end
 
 
  endmodule





module Tx_data_reception(
  input Tx_EN,
  input Tx_WR,
  input [7:0] Tx_DATA,
  output reg [7:0] Data = 0
);
 
 
  always@(Tx_WR)
    begin
      if (Tx_EN == 1 && Tx_WR == 1)
        begin
         Data <= Tx_DATA;
      end
    end
 
endmodule



module Tx_packet_creator(
  input parity_bit,
  input [7:0] Data,
  output reg [10:0] packet = 0
);
 
  integer i;
  always@(Data or parity_bit)
    begin
      packet = 0; // Fill the packet with zeroes
      packet[0] <= 0; // Start bit
     
      for(i=0; i<8 ; i=i+1)
        packet[i+1] <= Data[i]; // Insert data
     
      packet[9] = parity_bit; // Parity bit
      packet[10] = 1; // Stop bit

    end
 
endmodule




module Tx_transmission(
  input [10:0]packet,
  input TX_sample_ENABLE,
  output reg TxD = 1'bz,
  output reg Tx_BUSY = 0
);
 
  integer counter = 0;
  //integer counter = 10;
  always@(posedge TX_sample_ENABLE)
    begin
      if (packet != 0) // Packet has arrived
        begin
        if(TX_sample_ENABLE == 1)
          begin
          TxD <= packet[counter];
          end

          if(counter == 10)
          begin
          counter = 0;
          Tx_BUSY <= 0;
          end
           
        else
          begin
          counter = counter + 1;
          Tx_BUSY <= 1;
          end
        end
    end
endmodule




module UART_Receiver(
  input RxD,
  input Rx_EN,
  input [2:0] baud_select,
  input Clk,
  input reset,
  output wire Rx_PERROR,
  output wire Rx_FERROR, 
  output wire Rx_VALID,
  output wire [7:0] Rx_DATA
  
);
  
  wire Rx_Sample_ENABLE;
  wire [10:0] packet;
  wire start_bit_sync;
  wire original_parity_bit;
  wire [7:0] Data;
  wire parity_bit;
  
  wire packet_completion;
  
  Rx_baud_rate_generator Rx_baud_rate_generator_instance(Clk, reset, baud_select, Rx_Sample_ENABLE);
  
  Rx_data_reception Rx_data_reception_instance(RxD, Rx_EN, Rx_Sample_ENABLE, packet, start_bit_sync, packet_completion);
  
  Rx_data_extraction Rx_data_extraction_instance(packet,packet_completion, original_parity_bit, Data);
  
  parity_generator Rx_parity_generator_instance(Data, parity_bit);
  
  Rx_parity_comparison Rx_parity_comparison_instance(original_parity_bit, parity_bit, Rx_PERROR);
  
  Rx_framing_control Rx_framing_control_instance(start_bit_sync, Rx_FERROR);
  
  Rx_validation_control Rx_validation_control_instance(Rx_FERROR, Rx_PERROR, Data, Rx_DATA, Rx_VALID);
  
endmodule


module UART_Transmitter(
input Clk,
  input reset,
  input Tx_WR,
  input Tx_EN,
    input [7:0] Tx_DATA,
    input [2:0] baud_select,
output wire Tx_BUSY,
  output wire TxD
);
 
  wire [7:0] Data;
  wire parity_bit;
  wire [10:0] packet;
  wire Tx_Sample_ENABLE;
 
  Tx_baud_rate_generator Tx_baud_rate_generator_instance(Clk, reset, baud_select, Tx_Sample_ENABLE);
  Tx_data_reception Tx_data_reception_instance(Tx_EN, Tx_WR, Tx_DATA, Data);
  parity_generator Tx_parity_generator_instance(Data, parity_bit);
  Tx_packet_creator Tx_packet_creator_instance(parity_bit, Data, packet);
  Tx_transmission Tx_transmission_instance(packet, Tx_Sample_ENABLE, TxD, Tx_BUSY);
 
endmodule



// counter based
module clock_divider(
  input Clk , //50MHz
  input reset,
  output reg [3:0] anode,
  output reg [3:0] anode2
);
  

  reg [3:0 ]counter = 4'b1100;

  always @ (posedge Clk or negedge reset)
    begin 
      if (!reset)
        counter <= 4'b1100 ;
      else
        if (counter == 16)
          counter <= 0;
      else counter <= counter + 1;
    end
  
 
  always @ (counter)
    	begin
          case(counter)
          4'b0001 : anode = 4'b0111;  
          4'b0101 : anode = 4'b1011;
          4'b1001 : anode = 4'b1101;     
          4'b1101 : anode = 4'b1110; 
          
          default: anode = 4'b1111;
          endcase
          
        
          case(counter)
          4'b1111 : anode2 = 4'b0111;
          4'b0011 : anode2 = 4'b1011;
          4'b0111 : anode2 = 4'b1101;
          4'b1011 : anode2 = 4'b1110;
            
            
          default: anode2 = 4'b1111;
                 
          endcase 
          
   
        end
          
endmodule

//Verilog module.
module segment7(
     input [3:0] bcd,
  output reg [6:0] seg =0
    );
  
  reg [3:0] decrypt = 4'bzzzz;
     
//always block for converting bcd digit into 7 segment format
  always @(bcd)
    begin
     decrypt = bcd - 3;
      case (decrypt) //case statement
            0 : seg = 7'b0000001;
            1 : seg = 7'b1001111;
            2 : seg = 7'b0010010;
            3 : seg = 7'b0000110;
            4 : seg = 7'b1001100;
            5 : seg = 7'b0100100;
            6 : seg = 7'b0100000;
            7 : seg = 7'b0001111;
            8 : seg = 7'b0000000;
            9 : seg = 7'b0000100;
          	10: seg = 7'b1111110;
          	11: seg = 7'b0111000;
            //switch off 7 segment character when the bcd digit is not a decimal number.
            default : seg = 7'b1111111;
        endcase
    end
    
endmodule

module digit_producer(
  input [7:0] Rx_DATA,
  input Rx_FERROR,
  input Rx_PERROR,
  output reg [3:0] digit1,
  output reg [3:0] digit2,
  output reg [3:0] digit3,
  output reg [3:0] digit4
);
  
  integer rx_data_counter = -1; // Rx_DATA arrival counter
  integer error_counter = 0;   // Error counter
  integer i = 0;
  integer completion = 0; // All is set.
  
  reg [3:0] sub1 = 4'bzzzz; //Assistance variables
  reg [3:0] sub2 = 4'bzzzz;
  reg [3:0] sub3 = 4'bzzzz;
  reg [3:0] sub4 = 4'bzzzz;
  
  always@(Rx_DATA)
  	begin
      
      if(rx_data_counter == 0) // Arrival of first packet
        begin
          if(Rx_PERROR == 0 && Rx_FERROR == 0) // No errors.
            begin
              for(i=0;i<4;i=i+1)
                begin
                  sub1[i]<=Rx_DATA[i];
                  sub2[i]<=Rx_DATA[i+4];
                end
            end
        end
      
      else if(rx_data_counter == 1) //Arrival of second packet.
        begin
          if(Rx_PERROR == 0 && Rx_FERROR == 0) // no errors.
            begin
                i = 0;
		    for(i=0;i<4;i=i+1)
                begin
                  sub3[i]=Rx_DATA[i];
                  sub4[i]=Rx_DATA[i+4];
                end
		  rx_data_counter =-1;
              completion = 1;
            end
        end
      
      if(Rx_PERROR == 1 || Rx_FERROR == 1) // Checks if errors occured!
        begin
          error_counter = 1;
        end
      
      if(error_counter ==1 && rx_data_counter == 1) //Display F
        begin
                  digit1<=1011; //F
                  digit2<=1011; //F
                  digit3<=1011; //F
                  digit4<=1011; //F
                  
                  error_counter=0;
                  rx_data_counter= -1;
                  completion =0;
            end
      
      if(completion ==1) //Display the full information
        begin
          digit2<= sub1;
          digit1<= sub2;
          digit4<= sub3;
          digit3<= sub4;
          
          completion = 0;
        end
      rx_data_counter = rx_data_counter + 1;
    end
  
  
endmodule



module TOP(
  input [3:0] digit1,
  input [3:0] digit2,
  input [3:0] digit3,
  input [3:0] digit4,
  input Clk,
  input reset,
  output wire [6:0] Led_Disp,
  output wire [3:0] anode
);
  
  wire [3:0]anode2; 
  wire [3:0] ONE_DIGIT;
  clock_divider C_D(Clk, reset, anode, anode2);
  bcd_control bcdc(digit1, digit2, digit3, digit4, anode2, ONE_DIGIT);
  segment7 decoder(ONE_DIGIT,Led_Disp);
  
  
endmodule


module bcd_control(
  input [3:0] digit1, //right digit
  input [3:0] digit2, // tens
  input [3:0] digit3, // hundreds
  input [3:0] digit4, // thousands
  input [3:0] anode2,
  output reg[3:0] ONE_DIGIT = 0 // choose which digit is to be displayed
);
  
  
  always @ (anode2)
  begin
    case(anode2)
	  4'b0111:
		  ONE_DIGIT = digit1; //digit 1 value (right digit)
	  4'b1011:
		  ONE_DIGIT = digit2; // digit 2 value
	  4'b1101:
		  ONE_DIGIT = digit3; // digit 3 value
	  4'b1110:
		  ONE_DIGIT = digit4; // digit 4 value (left digit)
	endcase
  end
  
endmodule