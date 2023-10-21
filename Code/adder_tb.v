
module adder_tb();
  reg clk=0;
  reg rst=1;
  reg load = 0;
  reg   [31:0] a; 
  reg   [31:0] b;
  wire  [31:0] z;
  reg result_ack = 0;
  wire result_ready;

  always #10 clk=~clk;  // 25MHz
  
  adder add(
    .clk(clk),
    .reset(rst),
    .load(load),
    .Number1(a),
    .Number2(b),
    .result_ack(result_ack),
    .Result(z),
    .result_ready(result_ready)
	 );
	 
  initial begin
    a = 0;
    b = 0;
    rst = 1;
    #30
    rst = 0;
	 #30
	 rst = 1;
    //50 + 0 = 50
    a = 32'h42480000;
    b = 32'h00000000;
	 load = 1;
	 #20
	 load = 0;
    #2000
    result_ack = 1;
	 #50
	 result_ack = 0;
	 ///////
	 rst = 1;
	 #30;
	 rst = 0;
	 #30;
	 rst = 1;
	 //17 + 9 = 26
	 a = 32'h41880000;
	 b = 32'h41100000;
	 load = 1;
	 #20
	 load = 0;
	 #2000
	 result_ack = 1;
    $stop;
  end
endmodule
