module shift_register_tb();
	reg PCLK,PRESET_n,ss_i,send_data_i,lsbfe_i,cpha_i,cpol_i,miso_receive_sclk_i,miso_receive_sclk0_i,mosi_send_sclk_i,mosi_send_sclk0_i,miso_i,receive_data_i;
	reg[7:0]data_mosi_i;
	wire mosi_o;
	wire [7:0]data_miso_o;
	reg sclk_o;
	reg [2:0]sppr_i,spr_i;
	reg [1:0]spi_mode_i;
	wire [11:0]baudratedivisor_o;
	reg [11:0]count_s;
	wire pre_sclk_s; 
	reg spiswai_i;
	reg miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o;
	integer i;
	shift_register DUT (PCLK,PRESET_n,ss_i,send_data_i,lsbfe_i,cpha_i,cpol_i,miso_receive_sclk_i,miso_receive_sclk0_i,mosi_send_sclk_i,mosi_send_sclk0_i,miso_i,receive_data_i,data_mosi_i,mosi_o,data_miso_o);
	assign miso_receive_sclk0_i=miso_receive_sclk0_o;
	assign miso_receive_sclk_i=miso_receive_sclk_o;
	assign mosi_send_sclk0_i=mosi_send_sclk0_o;
	assign mosi_send_sclk_i=mosi_send_sclk_o;
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
					miso_receive_sclk0_o<=1'b0;
					miso_receive_sclk_o<=1'b0;
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
					mosi_send_sclk0_o<=1'b0;
					mosi_send_sclk_o<=1'b0;
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

	//shift_register DUT (PCLK,PRESET_n,ss_i,send_data_i,lsbfe_i,cpha_i,cpol_i,miso_receive_sclk_i,miso_receive_sclk0_i,mosi_send_sclk_i,mosi_send_sclk0_i,miso_i,receive_data_i,data_mosi_i,mosi_o,data_miso_o);
	initial
		begin
			PCLK=1'b0;
			forever #10 PCLK=~PCLK;
		end
	task reset;
		begin
			PRESET_n=1'b0;
			#10;
			PRESET_n=1'b1; 
			#10;
		end
	endtask
	task initialize;
		begin
			cpha_i=1'b0;
			cpol_i=1'b0;
			ss_i=1'b0;
			send_data_i=1'b0;
			lsbfe_i=1'b1;
			data_mosi_i=1'b0;
			sppr_i=3'b000;
			spr_i=3'b010;
			spi_mode_i=2'b00;
			spiswai_i=1'b0;
			receive_data_i=1'b0;
		end
	endtask
	task stimulus(input x,y);
		begin
			cpha_i=x;
			cpol_i=y;
		end
	endtask
	task transmit(input[7:0]a);
		begin
			@(negedge PCLK)
			send_data_i=1'b1;
			data_mosi_i=a;
		end
	endtask
	
	task receive (input b,c);
		begin
			receive_data_i=b;
			miso_i=c;
		end
	endtask
	task miso_in(input[7:0]m);
		begin
			lsbfe_i=1'b1;
			ss_i=1'b0;
			//
			miso_i=m[0];
			for(i=0;i<8;i=i+1)
				begin
				@(posedge sclk_o)
					miso_i=m[i];
				end
				@(posedge sclk_o)
				ss_i=1'b1;
				//  receive_data_i=1'b0;
				receive(1'b1,1'b1);
		end
	endtask	
	initial
		begin
			@(negedge PCLK) 
			initialize;
			reset;
			 // #40;
			ss_i=0;
			stimulus(1'b0,1'b0);
			fork
				begin
					transmit(8'b00110111);
					//receive(1'b1,1'b1);
					miso_in(8'b11100001);
				end
			join
			#2000 $finish;
		
		end
	initial
		$monitor("cpha_i=%b,cpol_i=%b,ss_i=%b,lsbfe_i=%b,PCLK=%b,PRESET_n=%b",cpha_i,cpol_i,ss_i,lsbfe_i,PCLK,PRESET_n);
endmodule
		
			