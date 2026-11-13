module apb_slave_interface(
	input PCLK,PRESET_n,PWRITE_i,PSEL_i,PENABLE_i,ss_i,receive_data_i,tip_i,
	input [7:0]PWDATA_i,
	input [2:0]PADDR_i,
	input [7:0]miso_data_i,
	output mstr_o,cpol_o,cpha_o,lsbfe_o,
	output spiswai_o,PREADY_o,PSLVERR_o,
	output reg send_data_o,spi_interrupt_request_o,
	output reg [7:0]PRDATA_o,
	output [2:0]sppr_o,
	output [2:0]spr_o,
	output reg [7:0]mosi_data_o,
	output reg[1:0]spi_mode_o);
	reg [7:0]SPI_BR;
	reg [7:0]SPI_CR1;
	reg [7:0]SPI_CR2;
	reg [7:0]SPI_DR;
	wire [7:0]SPI_SR;
	wire sptef;
	wire spif;
	wire spe;
	wire modf;
	wire modfen;
	wire ssoe;
	wire wr_enb;
	wire rd_enb;
	wire spie;
	wire sptie;
	parameter cr2_mask=8'b00011011;
	parameter br_mask=8'b01110111;
	parameter spi_run=2'b00;
	parameter spi_wait=2'b01;
	parameter spi_stop=2'b10;
	reg [1:0]next_mode;
	reg [1:0]state,next_state;
	parameter IDLE=2'b00;
	parameter SETUP=2'b01;
	parameter ENABLE=2'b10;
	wire o;
	//APB_MODE 
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				state <= IDLE;
			else
				state <= next_state;
		end
	always@(*)
		begin
			next_state = IDLE;
			case(state)
				IDLE:if(PSEL_i&&!PENABLE_i)
						next_state=SETUP;
					 else
						next_state=IDLE;
				SETUP:
					  if(PSEL_i&&PENABLE_i)
						next_state=ENABLE;
					  else
						next_state=SETUP;
				ENABLE:if(PSEL_i)
						next_state=SETUP;
				default:next_state=IDLE;
			endcase			   
		end
	assign o=(state==ENABLE)?1'b1:1'b0;
	assign spif=(SPI_DR!=8'b00000000)?1'b1:1'b0;
	assign modf=(!ss_i && mstr_o && modfen && ssoe);
	assign sptef=(SPI_DR==8'b00000000)?1'b1:1'b0;
	assign wr_enb=(PWRITE_i&&(state==ENABLE))?1'b1:1'b0;
	assign rd_enb=(!PWRITE_i&&(state==ENABLE))?1'b1:1'b0;
	assign PREADY_o=(state==ENABLE)?1'b1:1'b0;
	assign PSLVERR_o=(state==ENABLE)?~tip_i:1'b0;
	assign SPI_SR=(PRESET_n)?8'b00100000:{spif,1'b0,sptef,modf,4'b0};
	//spi modes
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				spi_mode_o<=spi_run;
			else
				spi_mode_o<=next_mode;
		end
	always@(*)
		begin
			case(spi_mode_o)
				
					spi_run:if(!spe)
								next_mode=spi_wait;
					spi_wait:if(spiswai_o)
								next_mode=spi_stop;
							else if(spe)
								next_mode=spi_run;
							else
								next_mode=spi_wait;
					spi_stop:if(!spiswai_o)
								next_mode=spi_wait;
							else if(spe)
								next_mode=spi_run;
					default:next_mode=spi_run;
				
			endcase
		end
	assign lsbfe_o=SPI_CR1[0];
	assign ssoe=SPI_CR1[1];
	assign cpha_o=SPI_CR1[2];
	assign cpol_o=SPI_CR1[3];
	assign mstr_o=SPI_CR1[4];
	assign sptie=SPI_CR1[5];
	assign spe=SPI_CR1[6];
	assign spie=SPI_CR1[7];
	assign spiswai_o=SPI_CR2[1];
	assign modfen=SPI_CR2[4];
	assign spr_o=SPI_BR[2:0];
	assign sppr_o=SPI_BR[6:4];
	//CR1
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				SPI_CR1<=8'h04;
			else if(wr_enb && PADDR_i==3'b000)
				begin
						SPI_CR1<=PWDATA_i;
					
				end
			else
				SPI_CR1<=SPI_CR1;
		end
		//cr2
	always@(posedge PCLK  or negedge PRESET_n)
		begin
			if(!PRESET_n)
				SPI_CR2<=8'h00;
			else if(wr_enb)
				begin
					if(PADDR_i==3'b001)
						SPI_CR2<=(PWDATA_i&cr2_mask);
					else
						SPI_CR2<=SPI_CR2;
				end
			else
				SPI_CR2<=SPI_CR2;
		end
		//br
	always@(posedge PCLK  or negedge PRESET_n)
		begin
			if(!PRESET_n)
				SPI_BR<=8'h00;
			else if(wr_enb)
				begin
					if(PADDR_i==3'b010)
						SPI_BR<=(PWDATA_i& br_mask);
					else
						SPI_BR<=SPI_BR;
				end
			else
				SPI_BR<=SPI_BR;
		end
	//SPI_DR
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				SPI_DR<=8'h00;
			else if(wr_enb)
				begin
					if(PADDR_i==3'b101)
						SPI_DR<=PWDATA_i;
					else
						SPI_DR<=SPI_DR;
				end
			else if(!wr_enb)
				begin
					if((SPI_DR==PWDATA_i)&&(SPI_DR!=miso_data_i)&&((spi_mode_o==spi_run)||(spi_mode_o==spi_wait)))
						SPI_DR<=8'h00;
					else
						begin
							if(receive_data_i&&((spi_mode_o==spi_run)||(spi_mode_o==spi_wait)))
								SPI_DR<=miso_data_i;
							else
								SPI_DR<=SPI_DR;
						end	
						
				end
		end
		//send_data
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				send_data_o<=1'b0;
			else if(!wr_enb&&((SPI_DR==PWDATA_i)&&(SPI_DR!=miso_data_i)&&((spi_mode_o==spi_run)||(spi_mode_o==spi_wait))))
				send_data_o<=1'b1;
			else
				send_data_o<=1'b0;
		end
		//mosi_data
	always@(posedge PCLK or negedge PRESET_n)
		begin
			if(!PRESET_n)
				mosi_data_o<=8'h00;
			else if((SPI_DR==PWDATA_i)&&(SPI_DR!=miso_data_i)&&((spi_mode_o==spi_run)||(spi_mode_o==spi_wait)))
				mosi_data_o<=SPI_DR;
			else
				mosi_data_o<=mosi_data_o;
		end
	//spi_interrupt_request_o
	always@(*)
		begin
			if(!spie && !sptie)
				spi_interrupt_request_o=1'b0;
			else if(!sptie && spie)
				spi_interrupt_request_o=(spif|modf);
			else if(!spie && sptie)
				spi_interrupt_request_o=sptef;
			else
				spi_interrupt_request_o=(spif|modf|sptef);
		end
	//PRDATA_o
	always@(*)
		begin
			if(rd_enb)
				begin
					case(PADDR_i)
						
							3'b000:PRDATA_o=SPI_CR1;
							3'b001:PRDATA_o=SPI_CR2;
							3'b010:PRDATA_o=SPI_BR;
							3'b011:PRDATA_o=SPI_SR;
							3'b101:PRDATA_o=SPI_DR;
							default:PRDATA_o=8'h00;
						
					endcase
				end
			else
			PRDATA_o=8'h00;
		end
endmodule