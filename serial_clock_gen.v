module serial_clock_gen(
	input PCLK,PRESET_n,cpol_i,cpha_i,ss_i,spiswai_i,
	input [2:0]spr_i,sppr_i,
	input [1:0]spi_mode_i,
	output reg sclk_o,miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o,
	output[11:0]baudratedivisor_o);
	reg [11:0] count_s;
	wire pre_sclk_s;
	assign baudratedivisor_o=((sppr_i+1)*(2**(spr_i+1)));
	assign pre_sclk_s=cpol_i?1'b1:1'b0;
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				begin	
					count_s<=12'b0;
					sclk_o<=pre_sclk_s;
				end
			else if(!ss_i&&!spiswai_i&&(spi_mode_i==2'b00||spi_mode_i==2'b01))
				begin
					if(count_s==baudratedivisor_o/2-1'b1)
						begin
							count_s<=12'b0;
							sclk_o<=~sclk_o;
						end
					else
						begin
							count_s<=count_s+1'b1;
							sclk_o=sclk_o;
						end
				end
			else
				begin
					sclk_o<=pre_sclk_s;
					count_s<=12'b0;
				end
		end
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				begin
					miso_receive_sclk0_o<=1'b0;
					miso_receive_sclk_o<=1'b0;
				end
			else 
				begin
					if((!cpha_i&&cpol_i)||(cpha_i&&!cpol_i))
						begin
							if(sclk_o)
								begin
									if(count_s==(baudratedivisor_o/2-1'b1))
										begin
											miso_receive_sclk0_o<=1'b1;
										end
									else
										miso_receive_sclk0_o<=1'b0;
								end
							else
								miso_receive_sclk0_o<=1'b0;
						end
					else if((!cpha_i&&!cpol_i)||(cpha_i&&cpol_i))
						begin
							if(!sclk_o)
								begin
									if(count_s==(baudratedivisor_o/2-1'b1))
										begin
											miso_receive_sclk_o<=1'b1;
										end
									else
										miso_receive_sclk_o<=1'b0;
								end
							else 
								miso_receive_sclk_o<=1'b0;
								
						end
				end
		end
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				begin
					mosi_send_sclk0_o<=1'b0;
					mosi_send_sclk_o<=1'b0;
				end
			else 
				begin
					if((!cpha_i&&cpol_i)||(cpha_i&&!cpol_i))
						begin
							if(sclk_o)
								begin
									if(count_s==(baudratedivisor_o/2-2'b10))
										begin
											mosi_send_sclk0_o<=1'b1;
										end
									else
										mosi_send_sclk0_o<=1'b0;
								end
						 
							else
								mosi_send_sclk0_o<=1'b0;
						end
					else if((!cpha_i&&!cpol_i)||(cpha_i&&cpol_i))
						begin
							if(!sclk_o)
								begin
									if(count_s==(baudratedivisor_o/2-2'b10))
										begin
											mosi_send_sclk_o<=1'b1;
										end
									else
										mosi_send_sclk_o<=1'b0;
								end
							else 
								mosi_send_sclk_o<=1'b0;
							
						end
				end
		end
endmodule								
						