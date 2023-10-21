module test_bench();

parameter MEMORY_HEIGHT = 4000;
parameter MEMORY_HEIGHT_SIZE = $clog2(MEMORY_HEIGHT);

wire[MEMORY_HEIGHT_SIZE-1:0] first_matrix_row_1_address;
wire[MEMORY_HEIGHT_SIZE-1:0] first_matrix_row_2_address;

wire[MEMORY_HEIGHT_SIZE-1:0] second_matrix_row_1_address;
wire[MEMORY_HEIGHT_SIZE-1:0] second_matrix_row_2_address;

wire[MEMORY_HEIGHT_SIZE-1:0] result_matrix_row_1_address;
wire[MEMORY_HEIGHT_SIZE-1:0] result_matrix_row_2_address;

wire[31:0] temp[7:0];
wire[31:0] temp_res[3:0];

reg clock;
reg rstN;
wire write_enable_1 = 0;
wire write_enable_2 = 0;
wire done;
wire write_add_data_done;
wire add_data_ack;

wire temp_1;
wire temp_2;

assign temp_1 = write_enable_1;
assign temp_2 = write_enable_2;

wire [MEMORY_HEIGHT_SIZE-1:0] write_add_row1_2;
wire write_enable_1_2;
wire [31:0] write_data_00;


always begin
	clock = 1'b0; #10;
	clock = 1'b1; #10;
end

initial begin
	rstN <= 1'b1;
	#45;
	rstN <= 1'b0;
	#2;
	rstN <= 1'b1;
end

matrix_reading reader(
							.clk(clock),
							.write_add_row1_2(address),
							.write_enable_1_2(),
							.write_data_00()
							);



matrix_multiplier mm(
							.first_matrix_row_1_address(first_matrix_row_1_address),
							.first_matrix_row_2_address(first_matrix_row_2_address),
								
							.first_matrix_input_00(temp[0]),
							.first_matrix_input_01(temp[1]),
							.first_matrix_input_10(temp[2]),
							.first_matrix_input_11(temp[3]),
								
							.second_matrix_row_1_address(second_matrix_row_1_address),
							.second_matrix_row_2_address(second_matrix_row_2_address),
		
							.second_matrix_input_00(temp[4]),
							.second_matrix_input_01(temp[5]),
							.second_matrix_input_10(temp[6]),
							.second_matrix_input_11(temp[7]),
								
							.write_core_1(write_enable_1),
							.write_core_2(write_enable_2),
							.write_add_data_done(write_add_data_done),
							.add_data_ack(add_data_ack),
								
							.result_matrix_row_1_address(result_matrix_row_1_address),
							.result_matrix_row_2_address(result_matrix_row_2_address),
								
							.result_matrix_output_00(temp_res[0]),
							.result_matrix_output_01(temp_res[1]),
							.result_matrix_output_10(temp_res[2]),
							.result_matrix_output_11(temp_res[3]),
								
							.rstN(rstN),
							.clk(clock),
							.done(done)
							);

Memory mem(
				.address_one_row1_2(first_matrix_row_1_address),
				.address_one_row3_4(first_matrix_row_2_address),
				.address_two_row1_2(second_matrix_row_1_address),
				.address_two_row3_4(second_matrix_row_2_address),
				.write_enable_1_2(0),
				.write_enable_3_4(0),
				.write_data_00(0),
				.write_data_01(0),
				.write_data_10(0),
				.write_data_11(0),
				.write_add_row1_2(result_matrix_row_1_address),
				.write_add_row3_4(result_matrix_row_2_address),
				.clock(clock),
				
				
				.write_add_data_00(temp_res[0]),
				.write_add_data_01(temp_res[1]),
				.write_add_data_10(temp_res[2]),
				.write_add_data_11(temp_res[3]),
				.write_add_data_enable_1(temp_1),
				.write_add_data_enable_2(temp_2),
				.write_add_data_done(write_add_data_done),
				.add_data_ack(add_data_ack),
				
				
				.matrix_one_00(temp[0]),
				.matrix_one_01(temp[1]),
				.matrix_one_10(temp[2]),
				.matrix_one_11(temp[3]),
				.matrix_two_00(temp[4]),
				.matrix_two_01(temp[5]),
				.matrix_two_10(temp[6]),
				.matrix_two_11(temp[7])
				);

								
endmodule
