module serial_clock_gen_tb();
	reg PCLK,PRESET_n,cpol_i,cpha_i,ss_i,spiswai_i;
	reg [2:0]spr_i,sppr_i;
	reg [1:0]spi_mode_i;
	wire sclk_o,miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o;
	wire[11:0]baudratedivisor_o;
	serial_clock_gen DUT(PCLK,PRESET_n,cpol_i,cpha_i,ss_i,spiswai_i,spr_i,sppr_i,spi_mode_i,sclk_o,miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o,baudratedivisor_o);
	initial
		begin
			PCLK=1'b0;
			forever #10 PCLK=~PCLK;
		end
	task reset;
		begin
		
			PRESET_n=1'b0;
			#30;
			PRESET_n=1'b1;
			#20;
		end
	endtask
	task initialize;
		begin
			spiswai_i=1'b0;

			cpol_i=1'b0;
			cpha_i=1'b0;
			//spr_i=3'b000;
			//sppr_i=3'b000;
			ss_i=1'b0;
			spi_mode_i=2'b00;
		end
	endtask
	task stimulus(input x,y);
		begin
			spi_mode_i=2'b00;
			cpha_i=x;
			cpol_i=y;
		end
	endtask
	initial
		begin
			 initialize;
			 reset;

        // CPHA = 0, CPOL = 1
			 @(negedge PCLK)
			 stimulus(1'b0,1'b1);

        // Apply reset after inputs have valid values
			 reset;
			 spr_i=3'b010;
			 sppr_i=3'b000;
			 @(negedge PCLK)
			 stimulus(1'b0,1'b1);

        // Run
			 #500;

			$finish;

		end
	initial
		
		$display("baudratedivisor=%b,sclk_o=%b,miso_receive_sclk_o=%b,miso_receive_sclk0_o=%b,mosi_send_sclk_o=%b,mosi_send_sclk0_o=%b",baudratedivisor_o,sclk_o,miso_receive_sclk_o,miso_receive_sclk0_o,mosi_send_sclk_o,mosi_send_sclk0_o);
	
endmodule
	