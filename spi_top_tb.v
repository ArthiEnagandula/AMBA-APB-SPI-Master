module spi_top_tb();
	reg PCLK,PRESET_n,PWRITE_i,PSEL_i,PENABLE_i,miso_i;
	reg [2:0]PADDR_i;
	reg[7:0]PWDATA_i;
	wire ss_o,sclk_o,spi_interrupt_request_o,mosi_o;
	wire PREADY_o;
	wire PSLVERR_o;
	wire [7:0]PRDATA_o;
	integer i;
	spi_top DUT(PCLK,PRESET_n,PWRITE_i,PSEL_i,PENABLE_i,
	miso_i,PADDR_i,PWDATA_i,ss_o,sclk_o,
	spi_interrupt_request_o,mosi_o,PREADY_o,
	PSLVERR_o,PRDATA_o);
	initial
		begin
			PCLK = 1'b0;
			forever #10 PCLK = ~PCLK;
		end
	task reset;
		begin
			PRESET_n=1'b0;
			#30;
			PRESET_n=1'b1;
			#20;
		end
	endtask
	/*task initialize;
		begin
			PSEL_i   = 1'b0;
            PENABLE_i= 1'b0;
            PWRITE_i = 1'b0;
            PADDR_i  = 3'b000;
            PWDATA_i = 8'h00;
            miso_i   = 1'b0;
		end
	endtask*/
	task spi_config_reg(input [7:0]data,input [2:0]addr);
		begin
			@(negedge PCLK)
				PADDR_i = addr;
				PWDATA_i = data;
				PSEL_i = 1'b1;
				PENABLE_i = 1'b0;
				PWRITE_i = 1'b1;
			@(negedge PCLK)
				PENABLE_i = 1'b1;
			@(negedge PCLK)
				wait(!PREADY_o)
			@(negedge PCLK)
				PSEL_i = 1'b0;
				PENABLE_i = 1'b0;
				//PADDR_i = 3'd0;
				//PWDATA_i<=8'd0;
			//@(negedge PCLK)
		end
	endtask
	task spi_config_sr(input [2:0]addr);
	begin
			@(negedge PCLK)
			PADDR_i = addr;
			PSEL_i = 1'b1;
			PENABLE_i = 1'b0;
			PWRITE_i = 1'b0;
			@(negedge PCLK)
			PENABLE_i = 1'b1;
			@(negedge PCLK)
			wait(!PREADY_o)
			@(negedge PCLK)
			PSEL_i = 1'b1;
			PENABLE_i = 1'b1;
			//PADDR_i=3'd0;
			//PWDATA_i = 1'd0;
			//@(negedge PCLK)
		end
	endtask
	task serial_input_miso(input[0:7]in);
		begin
			@(negedge sclk_o)
			wait(~ss_o)
			for(i=0;i<8;i=i+1)
				begin
					@(negedge sclk_o)
					miso_i=in[i];
				end
		end
	endtask
	initial
		begin
			serial_input_miso(8'b01110000);
			#5000 $finish;
		end
	initial
		begin
			reset;
			//miso_i=1'b1;
			spi_config_reg(8'b11111100,3'd0); 
			//CR1
			#50;
			spi_config_reg(8'b00010000,3'd1);  //CR2
			#50;
			spi_config_reg(8'b00000010,3'd2);  //brr
			/*apb_read(3'd0);
			apb_read(3'd1);
			apb_read(3'd2);*/
			#50;
			spi_config_sr(3'd0);
			spi_config_sr(3'd1);
			spi_config_sr(3'd2);
			spi_config_sr(3'd3);
			#10;
			spi_config_reg(8'b10100011,3'd5); 
			//dr
			spi_config_sr(3'd5);
			#50;
			#5000 $finish;
		end
endmodule