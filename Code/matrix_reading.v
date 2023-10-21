module matrix_reading 
#(
parameter MEMORY_HEIGHT = 4000)
(
input clk,
output wire [$clog2(MEMORY_HEIGHT >> 1):0] write_add_row1_2,
output reg write_enable_1_2,
output reg [31:0] write_data_00
);

reg [31:0]counter=0;
reg [31:0] x=1;
reg [31:0] y=1;
reg [100:0] line;
reg [$clog2(MEMORY_HEIGHT >> 1):0] current_location;
integer fd=0;
integer row1=0;
integer joint=0;
integer col2=0;
reg is_ready=0;
reg is_done_matrix1 =0;
reg zero_y_state=0;
reg zero_x_state=0;
reg [31:0] x_to_check;
reg [31:0] y_to_check;
initial begin 
fd = $fopen("matrices.txt","r");  
$fscanf(fd,"%d %d %d",row1,joint,col2);
x_to_check = row1;
y_to_check = joint;
is_ready <=1;
write_enable_1_2 <=1;
current_location <=-1;
end

always @(posedge clk)begin
if(is_ready ==0) begin write_enable_1_2 <=0;end

else begin 
    if(y == y_to_check+1 && x == x_to_check+1 && is_ready==1) begin
       if(is_done_matrix1==0) begin 
           y <=1;
           x <=1;
           is_done_matrix1 <=1;
           x_to_check = joint;
           y_to_check = col2;
           counter <= 0;
       end
       else begin is_ready <=0; $fclose("matrices.txt"); write_enable_1_2 <=0; end
    end
    else if(zero_y_state==1 && is_ready==1) begin
           zero_y_state <= 0;
           write_data_00 <= 0;
           current_location <= current_location+1;
           if(x!= x_to_check)x <= x+1;
           else begin
             if(x%2==0) begin y = y_to_check+1 ; x = x_to_check+1; end
             else begin   
                zero_x_state<=1;
             end
	   end
         end
     else if(zero_x_state==1 && is_ready==1) begin
           write_data_00 <=0;           
           counter <= counter +1;
           current_location <= current_location+1;
           if( y_to_check%2==0 && counter == y_to_check-1) begin zero_x_state <=0; x=x_to_check+1; y=y_to_check+1; end           
           else if(y_to_check%2==1 && counter == y_to_check)  begin zero_x_state <=0; x=x_to_check+1; y=y_to_check+1; end
           counter <= counter +1;
      end

     else if(y_to_check >= y && x!=x_to_check) begin 
          $fscanf(fd,"%d",write_data_00);
           current_location <= current_location+1;
           if(y == y_to_check) begin
             if(y%2==1) begin  y<=1; zero_y_state=1; end
             else  begin y<=1; x<= x+1; end
           end
           else y <= y+1;
     end
     else if(x_to_check ==x) begin
         if(y_to_check > y) begin 
          $fscanf(fd,"%d",write_data_00);
           y <= y+1;
           current_location <= current_location+1;
	 end
         else if(y_to_check ==y) begin 
           $fscanf(fd,"%d",write_data_00);
	   current_location <= current_location+1;
           //if(y%2==1) begin current_location <= current_location+1; end
           if(y%2==1) begin zero_y_state=1; $display("%s","rezaaaaaaaaa"); end
           else begin
             if(x%2==0) begin y = y_to_check+1 ; x = x_to_check+1; end
             else begin   
		zero_x_state <=1;
             end
           end
	 end           
     end
end
end


assign write_add_row1_2=current_location;

endmodule
