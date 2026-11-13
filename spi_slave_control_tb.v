module spi_slave_control_tb();
	reg PCLK,PRESET_n,mstr_i,spiswai_i,send_data_i;
	reg [11:0] baudratedivisor_i;
	reg [1:0] spi_mode_i;
	wire tip_o;
	wire receive_data_o,ss_o;
	spi_slave_control DUT (PCLK,PRESET_n,mstr_i,spiswai_i,send_data_i,baudratedivisor_i, spi_mode_i,tip_o,receive_data_o,ss_o);
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
			mstr_i=1'b0;
			spiswai_i=1'b0;
			send_data_i=1'b0;
			baudratedivisor_i=12'b0;
			spi_mode_i=2'b00;
		end
	endtask
	task stimulus;
		begin
			@(negedge PCLK)
			spiswai_i=1'b0;
			send_data_i=1'b1;
			mstr_i=1'b1;
			spi_mode_i=2'b00;
			#20;
			@(negedge PCLK)
			send_data_i=1'b0;
		end
	endtask
	initial 
		begin
			initialize;
			reset;
			baudratedivisor_i=12'd4;
			stimulus;
			#5000 $finish;
		end
endmodule
		