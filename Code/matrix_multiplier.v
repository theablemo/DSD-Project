module matrix_multiplier(
								first_matrix_row_1_address,
								first_matrix_row_2_address,
								
								first_matrix_input_00,
								first_matrix_input_01,
								first_matrix_input_10,
								first_matrix_input_11,
								
								second_matrix_row_1_address,
								second_matrix_row_2_address,
		
								second_matrix_input_00,
								second_matrix_input_01,
								second_matrix_input_10,
								second_matrix_input_11,
								
								write_enable,
								
								result_matrix_row_1_address,
								result_matrix_row_2_address,
								
								result_matrix_output_00,
								result_matrix_output_01,
								result_matrix_output_10,
								result_matrix_output_11,
								
								rstN,
								clk,
								done
								);

parameter   LEFT_SIZE = 4;
parameter COMMON_SIZE = 4;
parameter  RIGHT_SIZE = 4;

//starts from zero
parameter LEFT_SIZE_COUNT   =   ((LEFT_SIZE + 1) >> 1) - 1;
parameter COMMON_SIZE_COUNT = ((COMMON_SIZE + 1) >> 1) - 1;
parameter RIGHT_SIZE_COUNT  =  ((RIGHT_SIZE + 1) >> 1) - 1;

parameter MEMORY_HEIGHT = 4000;

parameter MEMORY_HEIGHT_SIZE = $clog2(MEMORY_HEIGHT);

output wire[MEMORY_HEIGHT_SIZE-1:0] first_matrix_row_1_address;
output wire[MEMORY_HEIGHT_SIZE-1:0] first_matrix_row_2_address;

output wire[MEMORY_HEIGHT_SIZE-1:0] second_matrix_row_1_address;
output wire[MEMORY_HEIGHT_SIZE-1:0] second_matrix_row_2_address;

output wire[MEMORY_HEIGHT_SIZE-1:0] result_matrix_row_1_address;
output wire[MEMORY_HEIGHT_SIZE-1:0] result_matrix_row_2_address;


wire [MEMORY_HEIGHT_SIZE-1:0] first_core_matrix_1_row_1_address;
wire [MEMORY_HEIGHT_SIZE-1:0] first_core_matrix_1_row_2_address;
wire [MEMORY_HEIGHT_SIZE-1:0] first_core_matrix_2_row_1_address;
wire [MEMORY_HEIGHT_SIZE-1:0] first_core_matrix_2_row_2_address;

wire [MEMORY_HEIGHT_SIZE-1:0] second_core_matrix_1_row_1_address;
wire [MEMORY_HEIGHT_SIZE-1:0] second_core_matrix_1_row_2_address;
wire [MEMORY_HEIGHT_SIZE-1:0] second_core_matrix_2_row_1_address;
wire [MEMORY_HEIGHT_SIZE-1:0] second_core_matrix_2_row_2_address;


output [31:0] result_matrix_output_00;
output [31:0] result_matrix_output_01;
output [31:0] result_matrix_output_10;
output [31:0] result_matrix_output_11;

output wire write_enable;

output done;

input [31:0] first_matrix_input_00;
input [31:0] first_matrix_input_01;
input [31:0] first_matrix_input_10;
input [31:0] first_matrix_input_11;

input [31:0] second_matrix_input_00;
input [31:0] second_matrix_input_01;
input [31:0] second_matrix_input_10;
input [31:0] second_matrix_input_11;

input rstN;
input clk;


//inner vriables

//first core variables
reg [31:0] first_core_matrix_1 [3:0];
reg [31:0] first_core_matrix_2 [3:0];

reg [$clog2(LEFT_SIZE_COUNT+1):0] first_core_matrix_1_row_counter = 0;
reg [$clog2(COMMON_SIZE_COUNT+1):0] first_core_matrix_1_col_counter = 0;
reg [$clog2(COMMON_SIZE_COUNT+1):0] first_core_matrix_2_row_counter = 0;
reg [$clog2(RIGHT_SIZE_COUNT+1):0] first_core_matrix_2_col_counter = 0;

reg [2:0] core_1_state = 3'b000;


//second core variables
reg [31:0] second_core_matrix_1 [3:0];
reg [31:0] second_core_matrix_2 [3:0];


reg [$clog2(LEFT_SIZE_COUNT + 1):0] second_core_matrix_1_row_counter = 1;
reg [$clog2(COMMON_SIZE_COUNT + 1):0] second_core_matrix_1_col_counter = 1;
reg [$clog2(COMMON_SIZE_COUNT + 1):0] second_core_matrix_2_row_counter = 0;
reg [$clog2(RIGHT_SIZE_COUNT + 1):0] second_core_matrix_2_col_counter = 0;


reg [2:0] core_2_state = 3'b000;

//block register
reg core_1_is_reading;
reg core_2_is_reading;


reg end_core_1 = 0;
reg end_core_2 = 0;
/*
multiplier core_1_multiplier;
multiplier core_2_multiplier;
*/


//status parameters
parameter s_SET_ADDRESS_FIRST_CORE  = 3'b000;
parameter s_SET_ADDRESS_SECOND_CORE = 3'b000;
parameter s_READ_FIRST_CORE_INPUTS  = 3'b001;
parameter s_READ_SECOND_CORE_INPUTS = 3'b001;
parameter s_MULTIPLY_FIRST_CORE     = 3'b010;
parameter s_MULTIPLY_SECOND_CORE    = 3'b010;
parameter s_ADD_FIRST_CORE          = 3'b011;
parameter s_ADD_SECOND_CORE         = 3'b011;
parameter s_PUT_FIRST_CORE          = 3'b100;
parameter s_PUT_SECOND_CORE         = 3'b100;
parameter s_FIRST_INCREASE_COUNTER  = 3'b101;
parameter s_SECOND_INCREASE_COUNTER = 3'b101;
parameter s_FIRST_WAIT					= 3'b110;
parameter s_SECOND_WAIT					= 3'b110;
parameter s_END_FIRST_CORE          = 3'b111;
parameter s_END_SECOND_CORE         = 3'b111;



parameter MATRIX_1_ROW_SIZE    = COMMON_SIZE % 2 ? COMMON_SIZE + 1 : COMMON_SIZE;
parameter MATRIX_1_COL_SIZE    = LEFT_SIZE % 2 ? LEFT_SIZE + 1 : LEFT_SIZE;
parameter MATIRX_1_CHANGE_ROW_PADDING = MATRIX_1_ROW_SIZE * 2;


parameter MATRIX_2_ROW_SIZE           = RIGHT_SIZE % 2 ? RIGHT_SIZE + 1 : RIGHT_SIZE;
parameter MATRIX_2_CHANGE_ROW_PADDING = MATRIX_2_ROW_SIZE * 2;
parameter MATRIX_2_ADDITIONAL_ROW_PADDING = COMMON_SIZE % 2 ? RIGHT_SIZE : 0;

parameter RESULT_MATRIX_PADDING = (MATRIX_1_ROW_SIZE * MATRIX_1_COL_SIZE) + (MATRIX_1_COL_SIZE * MATRIX_2_ROW_SIZE);
 
parameter ADDRESS_STEP = 2;

assign first_core_matrix_1_row_1_address  = (ADDRESS_STEP * first_core_matrix_1_col_counter) +
												 (MATIRX_1_CHANGE_ROW_PADDING * first_core_matrix_1_row_counter);
												 
assign first_core_matrix_1_row_2_address  = first_core_matrix_1_row_1_address +
												 MATRIX_1_ROW_SIZE;

												 
assign first_core_matrix_2_row_1_address = (MATRIX_1_COL_SIZE * MATRIX_1_ROW_SIZE) +
												 (ADDRESS_STEP * first_core_matrix_2_col_counter) + 
												 (MATRIX_2_CHANGE_ROW_PADDING * first_core_matrix_2_row_counter);
												 
assign first_core_matrix_2_row_2_address = first_core_matrix_2_row_1_address + 
												 MATRIX_2_ROW_SIZE;

												 
assign second_core_matrix_1_row_1_address = (ADDRESS_STEP * second_core_matrix_1_col_counter) +
												 (MATIRX_1_CHANGE_ROW_PADDING * second_core_matrix_1_row_counter);
												 
assign second_core_matrix_1_row_2_address  = second_core_matrix_1_row_1_address +
												 MATRIX_1_ROW_SIZE;

												 
assign second_core_matrix_2_row_1_address = (MATRIX_1_COL_SIZE * MATRIX_1_ROW_SIZE) +
												 (ADDRESS_STEP * second_core_matrix_2_col_counter) + 
												 (MATRIX_2_CHANGE_ROW_PADDING * second_core_matrix_2_row_counter);
												 
assign second_core_matrix_2_row_2_address = second_core_matrix_2_row_1_address + 
												 MATRIX_2_ROW_SIZE;


												 
assign done = (end_core_1 & end_core_2);

reg get_address = 0;

assign first_matrix_row_1_address  = get_address ? first_core_matrix_1_row_1_address : second_core_matrix_1_row_1_address;
assign first_matrix_row_2_address  = get_address ? first_core_matrix_1_row_2_address : second_core_matrix_1_row_2_address;
assign second_matrix_row_1_address = get_address ? first_core_matrix_2_row_1_address : second_core_matrix_2_row_1_address;
assign second_matrix_row_2_address = get_address ? first_core_matrix_2_row_2_address : second_core_matrix_2_row_2_address;

reg input_a_stb;
reg input_b_stb;
wire input_a_ack[7:0];
wire input_b_ack[7:0];

wire [31:0] output_z [7:0];

reg [31:0] save_z [7:0];

wire output_z_stb[7:0];
reg output_z_ack;

wire core_1_stb;
assign core_1_stb = (output_z_stb[0] & output_z_stb[1] & output_z_stb[2] & output_z_stb[3] & output_z_stb[4] & output_z_stb[5] & output_z_stb[6] & output_z_stb[7]);

reg clock;

always begin
	clock = 1'b0; #4;
	clock = 1'b1; #4;
end

reg reset;

single_multiplier core_1_1(
        .input_a(first_core_matrix_1[0]),
        .input_b(first_core_matrix_2[0]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[0]),
        .output_z_stb(output_z_stb[0]),
        .input_a_ack(input_a_ack[0]),
        .input_b_ack(input_b_ack[0])
		  );
		  
single_multiplier core_1_2(
        .input_a(first_core_matrix_1[0]),
        .input_b(first_core_matrix_2[1]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[1]),
        .output_z_stb(output_z_stb[1]),
        .input_a_ack(input_a_ack[1]),
        .input_b_ack(input_b_ack[1])
		  );
		  
		  
single_multiplier core_1_3(
        .input_a(first_core_matrix_1[2]),
        .input_b(first_core_matrix_2[0]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[2]),
        .output_z_stb(output_z_stb[2]),
        .input_a_ack(input_a_ack[2]),
        .input_b_ack(input_b_ack[2])
		  );
		  
		 
single_multiplier core_1_4(
        .input_a(first_core_matrix_1[2]),
        .input_b(first_core_matrix_2[1]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[3]),
        .output_z_stb(output_z_stb[3]),
        .input_a_ack(input_a_ack[3]),
        .input_b_ack(input_b_ack[3])
		  );
	
single_multiplier core_1_5(
        .input_a(first_core_matrix_1[1]),
        .input_b(first_core_matrix_2[2]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[4]),
        .output_z_stb(output_z_stb[4]),
        .input_a_ack(input_a_ack[4]),
        .input_b_ack(input_b_ack[4])
		  );
		 
		
single_multiplier core_1_6(
        .input_a(first_core_matrix_1[1]),
        .input_b(first_core_matrix_2[3]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[5]),
        .output_z_stb(output_z_stb[5]),
        .input_a_ack(input_a_ack[5]),
        .input_b_ack(input_b_ack[5])
		  );
		
single_multiplier core_1_7(
        .input_a(first_core_matrix_1[3]),
        .input_b(first_core_matrix_2[2]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[6]),
        .output_z_stb(output_z_stb[6]),
        .input_a_ack(input_a_ack[6]),
        .input_b_ack(input_b_ack[6])
		  );
		
single_multiplier core_1_8(
        .input_a(first_core_matrix_1[3]),
        .input_b(first_core_matrix_2[3]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z(output_z[7]),
        .output_z_stb(output_z_stb[7]),
        .input_a_ack(input_a_ack[7]),
        .input_b_ack(input_b_ack[7])
		  );		
		  

reg adder_reset[1:0];	  
reg load[1:0];
reg result_ack[3:0];
wire [31:0] result[3:0];
wire result_ready[3:0];

wire core_1_adder_ready;
assign core_1_adder_ready = (result_ready[0] & result_ready[1] & result_ready[2] & result_ready[3]);

adder adder_core_1_1 
	 (
    .clk(clock),
    .reset(adder_reset[0]),
    .load(load[0]),
    .Number1(save_z[0]),
    .Number2(save_z[4]),
    .result_ack(result_ack[0]),
    .Result(result[0]),
    .result_ready(result_ready[0])
	 );
	 
adder adder_core_1_2 
	 (
    .clk(clock),
    .reset(adder_reset[0]),
    .load(load[0]),
    .Number1(save_z[1]),
    .Number2(save_z[5]),
    .result_ack(result_ack[1]),
    .Result(result[1]),
    .result_ready(result_ready[1])
	 );
	 
adder adder_core_1_3 
	 (
    .clk(clock),
    .reset(adder_reset[0]),
    .load(load[0]),
    .Number1(save_z[2]),
    .Number2(save_z[6]),
    .result_ack(result_ack[2]),
    .Result(result[2]),
    .result_ready(result_ready[2])
	 );
	 
adder adder_core_1_4 
	 (
    .clk(clock),
    .reset(adder_reset[0]),
    .load(load[0]),
    .Number1(save_z[3]),
    .Number2(save_z[7]),
    .result_ack(result_ack[3]),
    .Result(result[3]),
    .result_ready(result_ready[3])
	 );
	 
reg [31:0] core_1_adder_result [3:0];
reg [31:0] core_2_adder_result [3:0];

reg get_result = 1;

assign result_matrix_output_00 = get_result ? core_1_adder_result[0] : core_2_adder_result[0];
assign result_matrix_output_01 = get_result ? core_1_adder_result[1] : core_2_adder_result[1];
assign result_matrix_output_10 = get_result ? core_1_adder_result[2] : core_2_adder_result[2];
assign result_matrix_output_11 = get_result ? core_1_adder_result[3] : core_2_adder_result[3];




wire [MEMORY_HEIGHT_SIZE-1:0] core_1_result_matrix_row_1_address;
wire [MEMORY_HEIGHT_SIZE-1:0] core_1_result_matrix_row_2_address;

wire [MEMORY_HEIGHT_SIZE-1:0] core_2_result_matrix_row_1_address;
wire [MEMORY_HEIGHT_SIZE-1:0] core_2_result_matrix_row_2_address;


assign core_1_result_matrix_row_1_address = RESULT_MATRIX_PADDING + (first_core_matrix_1_row_counter * MATRIX_1_COL_SIZE) +
															(first_core_matrix_2_col_counter * ADDRESS_STEP);

assign core_1_result_matrix_row_2_address = core_1_result_matrix_row_1_address + MATRIX_1_COL_SIZE;


assign core_2_result_matrix_row_1_address = RESULT_MATRIX_PADDING + (second_core_matrix_1_row_counter * MATRIX_1_COL_SIZE * 2) +
															(second_core_matrix_2_col_counter * ADDRESS_STEP);

assign core_2_result_matrix_row_2_address = core_2_result_matrix_row_1_address + MATRIX_1_COL_SIZE;


assign result_matrix_row_1_address = get_result ? core_1_result_matrix_row_1_address : core_2_result_matrix_row_1_address;
assign result_matrix_row_2_address = get_result ? core_1_result_matrix_row_2_address : core_2_result_matrix_row_2_address;







/////////////
reg input_a_stb_2;
reg input_b_stb_2;
wire input_a_ack_2[7:0];
wire input_b_ack_2[7:0];

wire [31:0] output_z_2 [7:0];

reg [31:0] save_z_2 [7:0];

wire output_z_stb_2[7:0];
reg output_z_ack_2;

wire core_1_stb_2;
assign core_1_stb_2 = (output_z_stb_2[0] & output_z_stb_2[1] & output_z_stb_2[2] & output_z_stb_2[3] & output_z_stb_2[4] & output_z_stb_2[5] & output_z_stb_2[6] & output_z_stb_2[7]);


reg reset_2;
/////////////
single_multiplier core_2_1(
        .input_a(second_core_matrix_1[0]),
        .input_b(second_core_matrix_2[0]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[0]),
        .output_z_stb(output_z_stb_2[0]),
        .input_a_ack(input_a_ack_2[0]),
        .input_b_ack(input_b_ack_2[0])
		  );
		  
single_multiplier core_2_2(
        .input_a(second_core_matrix_1[0]),
        .input_b(second_core_matrix_2[1]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[1]),
        .output_z_stb(output_z_stb_2[1]),
        .input_a_ack(input_a_ack_2[1]),
        .input_b_ack(input_b_ack_2[1])
		  );
		  
		  
single_multiplier core_2_3(
        .input_a(second_core_matrix_1[2]),
        .input_b(second_core_matrix_2[0]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[2]),
        .output_z_stb(output_z_stb_2[2]),
        .input_a_ack(input_a_ack_2[2]),
        .input_b_ack(input_b_ack_2[2])
		  );
		  
		 
single_multiplier core_2_4(
        .input_a(second_core_matrix_1[2]),
        .input_b(second_core_matrix_2[1]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[3]),
        .output_z_stb(output_z_stb_2[3]),
        .input_a_ack(input_a_ack_2[3]),
        .input_b_ack(input_b_ack_2[3])
		  );
	
single_multiplier core_2_5(
        .input_a(second_core_matrix_1[1]),
        .input_b(second_core_matrix_2[2]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[4]),
        .output_z_stb(output_z_stb_2[4]),
        .input_a_ack(input_a_ack_2[4]),
        .input_b_ack(input_b_ack_2[4])
		  );
		 
		
single_multiplier core_2_6(
        .input_a(second_core_matrix_1[1]),
        .input_b(second_core_matrix_2[3]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[5]),
        .output_z_stb(output_z_stb_2[5]),
        .input_a_ack(input_a_ack_2[5]),
        .input_b_ack(input_b_ack_2[5])
		  );
		
single_multiplier core_2_7(
        .input_a(second_core_matrix_1[3]),
        .input_b(second_core_matrix_2[2]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[6]),
        .output_z_stb(output_z_stb_2[6]),
        .input_a_ack(input_a_ack_2[6]),
        .input_b_ack(input_b_ack_2[6])
		  );
		
single_multiplier core_2_8(
        .input_a(second_core_matrix_1[3]),
        .input_b(second_core_matrix_2[3]),
        .input_a_stb(input_a_stb_2),
        .input_b_stb(input_b_stb_2),
        .output_z_ack(output_z_ack_2),
        .clk(clock),
        .rst(reset_2),
        .output_z(output_z_2[7]),
        .output_z_stb(output_z_stb_2[7]),
        .input_a_ack(input_a_ack_2[7]),
        .input_b_ack(input_b_ack_2[7])
		  );		
		  
		  
		  
		  
/////////


reg result_ack_2[3:0];
wire [31:0] result_2[3:0];
wire result_ready_2[3:0];

wire core_2_adder_ready;
assign core_2_adder_ready = (result_ready_2[0] & result_ready_2[1] & result_ready_2[2] & result_ready_2[3]);

adder adder_core_2_1 
	 (
    .clk(clock),
    .reset(adder_reset[1]),
    .load(load[1]),
    .Number1(save_z_2[0]),
    .Number2(save_z_2[4]),
    .result_ack(result_ack_2[0]),
    .Result(result_2[0]),
    .result_ready(result_ready_2[0])
	 );
	 
adder adder_core_2_2 
	 (
    .clk(clock),
    .reset(adder_reset[1]),
    .load(load[1]),
    .Number1(save_z_2[1]),
    .Number2(save_z_2[5]),
    .result_ack(result_ack_2[1]),
    .Result(result_2[1]),
    .result_ready(result_ready_2[1])
	 );
	 
adder adder_core_2_3 
	 (
    .clk(clock),
    .reset(adder_reset[1]),
    .load(load[1]),
    .Number1(save_z_2[2]),
    .Number2(save_z_2[6]),
    .result_ack(result_ack_2[2]),
    .Result(result_2[2]),
    .result_ready(result_ready_2[2])
	 );
	 
adder adder_core_2_4 
	 (
    .clk(clock),
    .reset(adder_reset[1]),
    .load(load[1]),
    .Number1(save_z_2[3]),
    .Number2(save_z_2[7]),
    .result_ack(result_ack_2[3]),
    .Result(result_2[3]),
    .result_ready(result_ready_2[3])
	 );
	

/*		  
single_multiplier core_1_1(
        .input_a(first_core_matrix_1[0]),
        .input_b(first_core_matrix_2[0]),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clock),
        .rst(reset),
        .output_z,(output_z),
        .output_z_stb(output_z_stb),
        .input_a_ack(input_a_ack),
        .input_b_ack(input_b_ack)
		  );
*/


reg write_core_1 =0;
reg write_core_2 =0;

assign write_enable = (write_core_1 | write_core_2);


												 
always @(posedge clk or negedge rstN) begin
		if(rstN == 0) begin
			core_1_state = s_SET_ADDRESS_FIRST_CORE;
			first_core_matrix_1_row_counter <= 0;
			first_core_matrix_1_col_counter <= 0;
			first_core_matrix_2_row_counter <= 0;
			first_core_matrix_2_col_counter <= 0;
			core_1_is_reading <= 0;
			get_address <= 1;
			reset <= 1;
			input_a_stb = 0;
			input_b_stb = 0;
			adder_reset[0] <= 1;
			write_core_1 <= 0;
		end else begin
		case(core_1_state) 
			s_SET_ADDRESS_FIRST_CORE: begin
				result_ack[0] = 0;
				result_ack[1] = 0;
				result_ack[2] = 0;
				result_ack[3] = 0;
				get_result = 0;
				write_core_1 = 0;
				core_1_is_reading = 1;
				if(first_core_matrix_2_col_counter > RIGHT_SIZE_COUNT) begin
					first_core_matrix_2_col_counter = 0;
					first_core_matrix_1_row_counter = first_core_matrix_1_row_counter + 2;
					if(first_core_matrix_1_row_counter > LEFT_SIZE_COUNT) begin
						first_core_matrix_1_row_counter = 0;
						first_core_matrix_1_col_counter = first_core_matrix_1_col_counter + 1;
						first_core_matrix_2_row_counter = first_core_matrix_2_row_counter + 1;
						if(first_core_matrix_1_col_counter > COMMON_SIZE_COUNT) begin
							core_1_state = s_END_FIRST_CORE;
							core_1_is_reading = 0;
						end
					end
				end
				
				get_address = 1;
				if(core_1_state == s_END_FIRST_CORE) begin
					//do nothing
				end else begin
					core_1_state = s_READ_FIRST_CORE_INPUTS;
				end
			end
		
			s_READ_FIRST_CORE_INPUTS: begin
				if(core_2_is_reading == 0) begin
					first_core_matrix_1[0] <= first_matrix_input_00;
					first_core_matrix_1[1] <= first_matrix_input_01;
					first_core_matrix_1[2] <= first_matrix_input_10;
					first_core_matrix_1[3] <= first_matrix_input_11;
				
					first_core_matrix_2[0] <= second_matrix_input_00;
					first_core_matrix_2[1] <= second_matrix_input_01;
					first_core_matrix_2[2] <= second_matrix_input_10;
					first_core_matrix_2[3] <= second_matrix_input_11;
		
					core_1_state <= s_MULTIPLY_FIRST_CORE;
					input_a_stb = 1;
					input_b_stb = 1;
					output_z_ack = 0;
					reset = 0;
				end
			end
			
			s_MULTIPLY_FIRST_CORE: begin
				core_1_is_reading = 0;
				get_address = 0;
				if(core_1_stb == 1) begin
					save_z[0] = output_z[0];
					save_z[1] = output_z[1];
					save_z[2] = output_z[2];
					save_z[3] = output_z[3];
					save_z[4] = output_z[4];
					save_z[5] = output_z[5];
					save_z[6] = output_z[6];
					save_z[7] = output_z[7];
					output_z_ack = 1;
					reset = 1;
					adder_reset[0] = 0;
					core_1_state = s_ADD_FIRST_CORE;
				end
			end
			
			s_ADD_FIRST_CORE: begin
				adder_reset[0] = 1;
				load[0] = 1;
				if(core_1_adder_ready == 1) begin
					core_1_adder_result[0] = result[0];
					core_1_adder_result[1] = result[1];
					core_1_adder_result[2] = result[2];
					core_1_adder_result[3] = result[3];
					core_1_state = s_PUT_FIRST_CORE;
					get_result = 1;
					result_ack[0] = 1;
					result_ack[1] = 1;
					result_ack[2] = 1;
					result_ack[3] = 1;
					end
			end
			
			s_PUT_FIRST_CORE: begin
				//put result
				if(write_core_2 ==0) begin
					write_core_1 = 1;
					core_1_state = s_FIRST_INCREASE_COUNTER;
				end
			end
			
			s_FIRST_INCREASE_COUNTER: begin
				//here
				get_result = 0;
				write_core_1 = 0;
				core_1_state = s_FIRST_WAIT;
			end
			
			s_FIRST_WAIT: begin
				core_1_state = s_SET_ADDRESS_FIRST_CORE;
				first_core_matrix_2_col_counter = first_core_matrix_2_col_counter + 1;
			end
			
			s_END_FIRST_CORE: begin
				//
				end_core_1 = 1;
			end
		endcase
		end
end


always @(posedge clk or negedge rstN) begin

		if(rstN == 0) begin
			core_2_state = s_SET_ADDRESS_SECOND_CORE;
			second_core_matrix_1_row_counter <= 1;
			second_core_matrix_1_col_counter <= 0;
			second_core_matrix_2_row_counter <= 0;
			second_core_matrix_2_col_counter <= 0;
			core_2_is_reading <= 0;
			reset_2 <= 1;
			input_a_stb_2 = 0;
			input_b_stb_2 = 0;
			adder_reset[1] <= 1;
			write_core_2 <= 0;
			
		end else begin
		case(core_2_state) 
			s_SET_ADDRESS_SECOND_CORE: begin
				if(core_1_is_reading == 0) begin
					result_ack_2[0] = 0;
					result_ack_2[1] = 0;
					result_ack_2[2] = 0;
					result_ack_2[3] = 0;
					core_2_is_reading = 1;
					if(second_core_matrix_2_col_counter > RIGHT_SIZE_COUNT) begin
						second_core_matrix_2_col_counter = 0;
						second_core_matrix_1_row_counter = second_core_matrix_1_row_counter + 2;
						if(second_core_matrix_1_row_counter > LEFT_SIZE_COUNT) begin
								second_core_matrix_1_row_counter = 1;
								second_core_matrix_1_col_counter = second_core_matrix_1_col_counter + 1;
								second_core_matrix_2_row_counter = second_core_matrix_2_row_counter + 1;
							if(second_core_matrix_1_col_counter > COMMON_SIZE_COUNT) begin
								core_2_state = s_END_SECOND_CORE;
								core_2_is_reading = 0;
							end
						end
					end
					if(core_2_state == s_END_SECOND_CORE) begin
					//do nothing
					end else begin
						core_2_state = s_READ_SECOND_CORE_INPUTS;
					end
				end
			end
			
			s_READ_SECOND_CORE_INPUTS: begin
				if(core_1_is_reading == 0) begin
					second_core_matrix_1[0] = first_matrix_input_00;
					second_core_matrix_1[1] = first_matrix_input_01;
					second_core_matrix_1[2] = first_matrix_input_10;
					second_core_matrix_1[3] = first_matrix_input_11;				
				
					second_core_matrix_2[0] = second_matrix_input_00;
					second_core_matrix_2[1] = second_matrix_input_01;
					second_core_matrix_2[2] = second_matrix_input_10;
					second_core_matrix_2[3] = second_matrix_input_11;
					
					core_2_state = s_MULTIPLY_SECOND_CORE;
					input_a_stb_2 = 1;
					input_b_stb_2 = 1;
					output_z_ack_2 = 0;
					reset_2 = 0;
				end
			end
			
			s_MULTIPLY_SECOND_CORE: begin
				core_2_is_reading = 0;
				if(core_1_stb_2 == 1) begin
					save_z_2[0] = output_z_2[0];
					save_z_2[1] = output_z_2[1];
					save_z_2[2] = output_z_2[2];
					save_z_2[3] = output_z_2[3];
					save_z_2[4] = output_z_2[4];
					save_z_2[5] = output_z_2[5];
					save_z_2[6] = output_z_2[6];
					save_z_2[7] = output_z_2[7];
					output_z_ack_2 = 1;
					reset_2 = 1;
					adder_reset[1] = 0;
					core_2_state <= s_ADD_SECOND_CORE;
				end
			end
			
			s_ADD_SECOND_CORE: begin
				adder_reset[1] = 1;
				load[1] = 1;
				if(core_2_adder_ready == 1) begin
					core_2_adder_result[0] = result_2[0];
					core_2_adder_result[1] = result_2[1];
					core_2_adder_result[2] = result_2[2];
					core_2_adder_result[3] = result_2[3];
					core_2_state = s_PUT_SECOND_CORE;
					result_ack_2[0] = 1;
					result_ack_2[1] = 1;
					result_ack_2[2] = 1;
					result_ack_2[3] = 1;
					end
			end
			
			s_PUT_SECOND_CORE: begin
				if(write_core_1 == 0) begin
					write_core_2 = 1;
					core_2_state <= s_SECOND_INCREASE_COUNTER;
				end
				
			end
			
			s_SECOND_INCREASE_COUNTER: begin
				write_core_2 = 0;
				core_2_state <= s_SECOND_WAIT;
			end
			
			s_SECOND_WAIT: begin
				core_2_state <= s_SET_ADDRESS_SECOND_CORE;
				second_core_matrix_2_col_counter <= second_core_matrix_2_col_counter + 1;
			end
			
			s_END_SECOND_CORE: begin
				end_core_2 = 1;
			end
		endcase
		end
end

endmodule

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
  
  input [31:0] write_add_date_00,
  input [31:0] write_add_date_01,
  input [31:0] write_add_date_10,
  input [31:0] write_add_date_11,
  input write_add_date_enable,
  output reg write_add_data_done,
  input add_data_ack,
  
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
	 
	 
	 
	 
	 reg do = 0;
    reg [31:0] save_add [3:0];
always @(posedge write_add_date_enable) begin
	reset = 0;
	write_add_data_done <= 0;
	do <= 1;
	save_add[0] <= write_add_date_00;
	save_add[1] <= write_add_date_01;
	save_add[2] <= write_add_date_10;
	save_add[3] <= write_add_date_11;
end

always @(posedge clk) begin
	if(do) begin
		if(reset) begin
			load = 1;
			if(result_stb) begin
				load = 0;
				write_add_data_done = 1;
				main_memory[write_add_row1_2] = result[0];
				main_memory[write_add_row1_2+1] = result[1];
				main_memory[write_add_row3_4] = result[2];
				main_memory[write_add_row3_4+1] = result[3];
				if(add_data_ack) begin
					result_ack[1] = 1;
					result_ack[1] = 1;
					result_ack[1] = 1;
					result_ack[1] = 1;
				end
			end
		end else begin
			reset = 1;
		end
	end else begin
		result_ack[1] = 0;
		result_ack[1] = 0;
		result_ack[1] = 0;
		result_ack[1] = 0;
	end
end

//////////////
reg clk;
reg reset;
reg load;
reg result_ack[3:0];
reg [31:0] result[3:0];
reg result_ready[3:0];
wire result_stb;
assign result_stb = (result_ready[0] & result_ready[1] & result_ready[2] & result_ready[3]);


always begin
	clk = 1'b0; #4;
	clk = 1'b1; #4;
end

adder mem_1
	 (
    .clk(clk),
    .reset(reset),
    .load(load),
    .Number1(save_add[0]),
    .Number2(main_memory[write_add_row1_2]),
    .result_ack(result_ack[0]),
    .Result(result[0]),
    .result_ready(result_ready[0])
	 );
	 
adder mem_2 
	 (
    .clk(clk),
    .reset(reset),
    .load(load),
    .Number1(save_add[1]),
    .Number2(main_memory[write_add_row1_2+1]),
    .result_ack(result_ack[0]),
    .Result(result[0]),
    .result_ready(result_ready[0])
	 );
	 
adder mem_3 
	 (
    .clk(clk),
    .reset(reset),
    .load(load),
    .Number1(save_add[2]),
    .Number2(main_memory[write_add_row3_4]),
    .result_ack(result_ack[0]),
    .Result(result[0]),
    .result_ready(result_ready[0])
	 );
	 
adder mem_4 
	 (
    .clk(clk),
    .reset(reset),
    .load(load),
    .Number1(save_add[3]),
    .Number2(main_memory[write_add_row3_4+1]),
    .result_ack(result_ack[0]),
    .Result(result[0]),
    .result_ready(result_ready[0])
	 );
	     
initial begin
	main_memory[0] = 32'h40A00000;
	main_memory[1] = 32'h40A00000;
	main_memory[2] = 32'h40A00000;
	main_memory[3] = 32'h40A00000;
	main_memory[4] = 32'h40A00000;
	main_memory[5] = 32'h40A00000;
	main_memory[6] = 32'h40A00000;
	main_memory[7] = 32'h40A00000;
	main_memory[8] = 32'h40A00000;
	main_memory[9] = 32'h40A00000;
	main_memory[10] = 32'h40A00000;
	main_memory[11] = 32'h40A00000;
	main_memory[12] = 32'h40A00000;
	main_memory[13] = 32'h40A00000;
	main_memory[14] = 32'h40A00000;
	main_memory[15] = 32'h40A00000;
	main_memory[16] = 32'h40A00000;
	main_memory[17] = 32'h40A00000;
	main_memory[18] = 32'h40A00000;
	main_memory[19] = 32'h40A00000;
	main_memory[20] = 32'h40A00000;
	main_memory[21] = 32'h40A00000;
	main_memory[22] = 32'h40A00000;
	main_memory[23] = 32'h40A00000;
	main_memory[24] = 32'h40A00000;
	main_memory[25] = 32'h40A00000;
	main_memory[26] = 32'h40A00000;
	main_memory[27] = 32'h40A00000;
	main_memory[28] = 32'h40A00000;
	main_memory[29] = 32'h40A00000;
	main_memory[30] = 32'h40A00000;
	main_memory[31] = 32'h40A00000;
/*
	main_memory[32] = 1;
	main_memory[33] = 1;
	main_memory[34] = 1;
	main_memory[35] = 0;
	main_memory[36] = 1;
	main_memory[37] = 1;
	main_memory[38] = 1;
	main_memory[39] = 0;
	main_memory[40] = 1;
	main_memory[41] = 1;
	main_memory[42] = 1;
	main_memory[43] = 0;
	main_memory[44] = 1;
	main_memory[45] = 1;
	main_memory[46] = 1;
	main_memory[47] = 0;
	main_memory[48] = 1;
	main_memory[49] = 1;
	main_memory[50] = 1;
	main_memory[51] = 0;
	main_memory[52] = 1;
	main_memory[53] = 1;
	main_memory[54] = 1;
	main_memory[55] = 0;
	main_memory[56] = 1;
	main_memory[57] = 1;
	main_memory[58] = 1;
	main_memory[59] = 0;
	main_memory[60] = 0;
	main_memory[61] = 0;
	main_memory[62] = 0;
	main_memory[63] = 0;
	main_memory[64] = 1;
	main_memory[65] = 1;
	main_memory[66] = 1;
	main_memory[67] = 1;
	main_memory[68] = 1;
	main_memory[69] = 1;
	main_memory[70] = 1;
	main_memory[71] = 1;
	main_memory[72] = 1;
	main_memory[73] = 1;
	main_memory[74] = 1;
	main_memory[75] = 1;
	main_memory[76] = 1;
	main_memory[77] = 1;
	main_memory[78] = 1;
	main_memory[79] = 1;
	*/
end		 

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


module adder(
input clk,
input reset, 
input load,
input [31:0]Number1, 
input [31:0]Number2, 
input result_ack,
output [31:0]Result,
output reg result_ready
);
    localparam get_input = 0;
    localparam calculate = 1;
    localparam final = 2;
    
    reg [31:0] number1_copy;
    reg [31:0] number2_copy;
    reg start = 0;
    reg [1:0] state;
    reg    [31:0] Num_shift_80; 
    reg    [7:0]  Larger_exp_80,Final_expo_80;
    reg    [22:0] Small_exp_mantissa_80,S_mantissa_80,L_mantissa_80,Large_mantissa_80,Final_mant_80;
    reg    [23:0] Add_mant_80,Add1_mant_80;
    reg    [7:0]  e1_80,e2_80;
    reg    [22:0] m1_80,m2_80;
    reg           s1_80,s2_80,Final_sign_80;
    reg    [3:0]  renorm_shift_80;
    //integer signed   renorm_exp_80;
    reg           renorm_exp_80;
    reg    [31:0] Result_80;

    assign Result = Result_80;


    always @(*) begin
        //stage 1
        if (start) begin
            e1_80 = number1_copy[30:23];
            e2_80 = number2_copy[30:23];
                m1_80 = number1_copy[22:0];
            m2_80 = number2_copy[22:0];
            s1_80 = number1_copy[31];
            s2_80 = number2_copy[31];
                
                if (e1_80  > e2_80) begin
                    Num_shift_80           = e1_80 - e2_80;              // number of mantissa shift
                    Larger_exp_80           = e1_80;                     // store lower exponent
                    Small_exp_mantissa_80  = m2_80;
                    Large_mantissa_80      = m1_80;
                end
                
                else begin
                    Num_shift_80           = e2_80 - e1_80;
                    Larger_exp_80           = e2_80;
                    Small_exp_mantissa_80  = m1_80;
                    Large_mantissa_80      = m2_80;
                end
        
            if (e1_80 == 0 | e2_80 ==0) begin
                Num_shift_80 = 0;
            end
            else begin
                Num_shift_80 = Num_shift_80;
            end
            
            
                
                //stage 2
                //if check both for normalization then append 1 and shift
            if (e1_80 != 0) begin
                    Small_exp_mantissa_80  = {1'b1,Small_exp_mantissa_80[22:1]};
                Small_exp_mantissa_80  = (Small_exp_mantissa_80 >> Num_shift_80);
                end
            else begin
                Small_exp_mantissa_80 = Small_exp_mantissa_80;
            end
        
            if (e2_80!= 0) begin
                    Large_mantissa_80      = {1'b1,Large_mantissa_80[22:1]};
            end
            else begin
                Large_mantissa_80 = Large_mantissa_80;
            end
        
                    //else do what to do for denorm field
                    
        
                //stage 3
                                                            //check if exponent are equal
                    if (Small_exp_mantissa_80  < Large_mantissa_80) begin
                        //Small_exp_mantissa_80 = ((~ Small_exp_mantissa_80 ) + 1'b1);
                //$display("what small_exp:%b",Small_exp_mantissa_80);
                S_mantissa_80 = Small_exp_mantissa_80;
                L_mantissa_80 = Large_mantissa_80;
                    end
                    else begin
                        //Large_mantissa_80 = ((~ Large_mantissa_80 ) + 1'b1);
                //$display("what large_exp:%b",Large_mantissa_80);
                    
                S_mantissa_80 = Large_mantissa_80;
                L_mantissa_80 = Small_exp_mantissa_80;
                     end       
                //stage 4
                //add the two mantissa's
            
            if (e1_80!=0 & e2_80!=0) begin
                if (s1_80 == s2_80) begin
                        Add_mant_80 = S_mantissa_80 + L_mantissa_80;
                end else begin
                    Add_mant_80 = L_mantissa_80 - S_mantissa_80;
                end
            end	
            else begin
                Add_mant_80 = L_mantissa_80;
            end
                 
            //renormalization for mantissa and exponent
            if (Add_mant_80[23]) begin
                renorm_shift_80 = 4'd1;
                renorm_exp_80 = 4'd1;
            end
            else if (Add_mant_80[22])begin
                renorm_shift_80 = 4'd2;
                renorm_exp_80 = 0;		
            end
            else if (Add_mant_80[21])begin
                renorm_shift_80 = 4'd3; 
                renorm_exp_80 = -1;
            end 
            else if (Add_mant_80[20])begin
                renorm_shift_80 = 4'd4; 
                renorm_exp_80 = -2;		
            end  
            else if (Add_mant_80[19])begin
                renorm_shift_80 = 4'd5; 
                renorm_exp_80 = -3;		
            end      
        
            //stage 5
            // if e1==e2, no shift for exp
                Final_expo_80 =  Larger_exp_80 + renorm_exp_80;
            
            Add1_mant_80 = Add_mant_80 << renorm_shift_80;
        
            Final_mant_80 = Add1_mant_80[23:1];  	
        
                
            if (s1_80 == s2_80) begin
                Final_sign_80 = s1_80;
            end 
        
            if (e1_80 > e2_80) begin
                Final_sign_80 = s1_80;	
            end else if (e2_80 > e1_80) begin
                Final_sign_80 = s2_80;
            end
            else begin
        
                if (m1_80 > m2_80) begin
                    Final_sign_80 = s1_80;		
                end else begin
                    Final_sign_80 = s2_80;
                end
            end	
            
            Result_80 = {Final_sign_80,Final_expo_80,Final_mant_80}; 
        end
        else begin
            Result_80 = 0;
        end
    end
    
    always @(posedge clk, negedge reset) begin
            if(!reset) begin
                Num_shift_80 <= #1 0;
                state <= get_input;
                number1_copy <= 0;
                number2_copy <= 0;
                start <= 0;
                result_ready <= 0;
            end
            else begin
                case (state)
                    get_input: begin
                        if (load) begin
                            number1_copy <= Number1;
                            number2_copy <= Number2;
                            state <= calculate;
                        end
                        else begin
                            state <= get_input;
                            start <= 0;
                            result_ready <= 0;
                        end
                    end
                    calculate: begin
                        start <= 1;
                        state <= final;
                    end
                    final: begin
                        result_ready <= 1;
                        if (result_ack) begin
                            state <= get_input;
                            result_ready <= 0;
                            start <= 0;
                        end 
                        else begin
                            state <= final;
                        end
                    end
                endcase
            end
    end
endmodule
