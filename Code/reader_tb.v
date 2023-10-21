module test;

parameter MEMORY_HEIGHT = 4000;
reg [10:0] line;
integer fd;

reg clk;
wire [$clog2(MEMORY_HEIGHT >> 1):0] write_add_row1_2;
wire write_enable_1_2;
wire [31:0] write_data_00;

always begin
	clk = 1'b0; #10;
	clk = 1'b1; #10;
end

initial begin
end


matrix_reading #(MEMORY_HEIGHT) MR(clk,write_add_row1_2,write_enable_1_2,write_data_00);







endmodule
