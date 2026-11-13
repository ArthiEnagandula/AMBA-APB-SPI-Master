module spi_slave_control (input PCLK,PRESET_n,mstr_i,spiswai_i,send_data_i,
	input [11:0] baudratedivisor_i,
	input [1:0] spi_mode_i,
	output tip_o,
	output reg receive_data_o,ss_o);
	parameter spi_run=2'b00;
	parameter spi_wait=2'b01;
	parameter spi_stop=2'b10;
	reg [15:0]count;
	reg  rcv;
	wire [15:0] target;
	assign tip_o=~ss_o;
	assign target=(baudratedivisor_i/2)*16;
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				receive_data_o<=1'b0;
			else
				receive_data_o<=rcv;
		end
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if (!PRESET_n)
				begin
					count<=16'hffff;
					rcv<=1'b0;
					ss_o<=1'b1;
				end
			else if(!spiswai_i&&((spi_mode_i==spi_run)||(spi_mode_i==spi_wait))&&mstr_i)
				begin
					if(send_data_i)
						begin
							count<=16'd0;
							ss_o<=1'b0;
							rcv<=1'b0;
						end
					else
						begin
							if(count<=target-1'b1)
								begin
									count<=count+1'b1;
									ss_o<=1'b0;
									rcv<=(count==target-1'b1)?1'b1:1'b0 ;
								end 
							else
								begin
									count<=16'hffff;
									ss_o<=1'b1;
									rcv<=1'b0;
									
								end
						end
				end
			else
				begin
					count<=16'hffff;
					ss_o<=1'b1;
					rcv<=1'b0;
				end
		end
endmodule
						