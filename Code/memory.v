module Memory #(parameter MEMORY_HEIGHT = 4000)
(
  input [$clog2(MEMORY_HEIGHT >> 1):0] address_one_row1_2,
  input [$clog2(MEMORY_HEIGHT >> 1):0] address_one_row3_4,
  input [$clog2(MEMORY_HEIGHT >> 1):0] address_two_row1_2,
  input [$clog2(MEMORY_HEIGHT >> 1):0] address_two_row3_4,
  input write_enable_1_2,
  input write_enable_3_4,
  input [31:0] write_data_00,
  input [31:0] write_data_01,
  input [31:0] write_data_10,
  input [31:0] write_data_11,
  input [$clog2(MEMORY_HEIGHT >> 1):0] write_add_row1_2,
  input [$clog2(MEMORY_HEIGHT >> 1):0] write_add_row3_4,
  input clock,
  
  output [31:0] matrix_one_00,
  output [31:0] matrix_one_01,
  output [31:0] matrix_one_10,
  output [31:0] matrix_one_11,
  
  output [31:0] matrix_two_00,
  output [31:0] matrix_two_01,
  output [31:0] matrix_two_10,
  output [31:0] matrix_two_11
);

    reg [31:0] main_memory [MEMORY_HEIGHT-1 : 0];
    
    reg [31:0] mat_one [3:0];
    reg [31:0] mat_two [3:0];
       
    always @(posedge clock) begin
        mat_one[0] <= main_memory[address_one_row1_2];
        mat_one[1] <= main_memory[address_one_row1_2 + 1];
        mat_one[2] <= main_memory[address_one_row3_4];
        mat_one[3] <= main_memory[address_one_row3_4 + 1];
    end
    
    always @(posedge clock) begin
        mat_two[0] <= main_memory[address_two_row1_2];
        mat_two[1] <= main_memory[address_two_row1_2 + 1];
        mat_two[2] <= main_memory[address_two_row3_4];
        mat_two[3] <= main_memory[address_two_row3_4 + 1];
    end
    
    always @(posedge clock) begin
        if(write_enable_1_2) begin
            main_memory[write_add_row1_2]       <= write_data_00;
            main_memory[write_add_row1_2 + 1]   <= write_data_01;
        end
        else begin
            // nothing to do
        end
    end
    
    always @(posedge clock) begin
        if(write_enable_3_4) begin
            main_memory[address_two_row3_4]     <= write_data_10;
            main_memory[address_two_row3_4 + 1] <= write_data_11;
        end
        else begin
            // nothing to do
        end
    end
    
    assign matrix_one_00 = mat_one[0];
    assign matrix_one_01 = mat_one[1];
    assign matrix_one_10 = mat_one[2];
    assign matrix_one_11 = mat_one[3];
    
    assign matrix_two_00 = mat_two[0];
    assign matrix_two_01 = mat_two[1];
    assign matrix_two_10 = mat_two[2];
    assign matrix_two_11 = mat_two[3];
    
endmodule
