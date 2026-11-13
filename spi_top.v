module spi_top(input PCLK,PRESET_n,PWRITE_i,PSEL_i,PENABLE_i,miso_i,
	input [2:0]PADDR_i,
	input[7:0]PWDATA_i,
	output ss_o,sclk_o,spi_interrupt_request_o,mosi_o,
	output PREADY_o,PSLVERR_o,
	output [7:0]PRDATA_o);
	wire [1:0]spi_mode;
	wire cpol,cpha;
	wire [2:0]spr,sppr;
	wire spiswai;
	wire miso_receive_sclk,miso_receive_sclk0,mosi_send_sclk,mosi_send_sclk0;
	wire [11:0]baudratedivisor;
	//reg[11:0]count_s;
	//wire pre_sclk;
	wire send_data;
	wire lsbfe;
	wire receive_data;
	wire [7:0]mosi_data;
	wire [7:0]miso_data;
	//wire [7:0]shift_reg,temp_reg;
	//wire [2:0]count,count1,count2,count3;
	wire tip;
	wire mstr;
	wire ssoe;
	//wire sptef;
	//wire spif;
	//wire spe;
	//wire modf;
	//wire modfen;
	
	/*wire wr_enb;
	wire rd_enb;
	wire spie;
	wire sptie;
	reg [7:0]SPI_BR;
	reg [7:0]SPI_CR1;
	reg [7:0]SPI_CR2;
	reg [7:0]SPI_DR;
	reg [7:0]SPI_SR;
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
	reg [15:0]count;
	reg  rcv;
	wire [15:0] target;*/
	
	serial_clock_gen s1 (
        .PCLK                 (PCLK),
        .PRESET_n             (PRESET_n),
        .cpol_i               (cpol),
        .cpha_i               (cpha),
        .ss_i                 (ssoe),
        .spiswai_i           (spiswai),
        .spr_i                (spr),
        .sppr_i               (sppr),
        .spi_mode_i           (spi_mode),
        .sclk_o               (sclk_o),
        .miso_receive_sclk_o  (miso_receive_sclk),
        .miso_receive_sclk0_o (miso_receive_sclk0),
        .mosi_send_sclk_o     (mosi_send_sclk),
        .mosi_send_sclk0_o    (mosi_send_sclk0),
        .baudratedivisor_o    (baudratedivisor)
    );
	shift_register s2 (
        .PCLK                 (PCLK),
        .PRESET_n             (PRESET_n),
        .ss_i                 (ssoe),
        .send_data_i          (send_data),
        .lsbfe_i              (lsbfe),
        .cpha_i               (cpha),
        .cpol_i               (cpol),
        .miso_receive_sclk_i  (miso_receive_sclk),
        .miso_receive_sclk0_i (miso_receive_sclk0),
        .mosi_send_sclk_i     (mosi_send_sclk),
        .mosi_send_sclk0_i    (mosi_send_sclk0),
        .miso_i               (miso_i),
        .receive_data_i       (receive_data),
        .data_mosi_i          (mosi_data),
        .mosi_o               (mosi_o),
        .data_miso_o          (miso_data)
    );
	apb_slave_interface apb (
        .PCLK                 (PCLK),
        .PRESET_n             (PRESET_n),
        .PWRITE_i             (PWRITE_i),
        .PSEL_i               (PSEL_i),
        .PENABLE_i            (PENABLE_i),
        .ss_i                 (ssoe),
        .receive_data_i       (receive_data),
        .tip_i                (tip),
        .PWDATA_i             (PWDATA_i),
        .PADDR_i              (PADDR_i),
        .miso_data_i          (miso_data),
        .mstr_o               (mstr),
        .cpol_o               (cpol),
        .cpha_o               (cpha),
        .lsbfe_o              (lsbfe),
        .spiswai_o           (spiswai),
        .PREADY_o             (PREADY_o),
        .PSLVERR_o            (PSLVERR_o),
        .send_data_o          (send_data),
        .spi_interrupt_request_o (spi_interrupt_request_o),
        .PRDATA_o             (PRDATA_o),
        .sppr_o               (sppr),
        .spr_o                (spr),
        .mosi_data_o          (mosi_data),
        .spi_mode_o           (spi_mode)
    );
	spi_slave_control ssc (
        .PCLK                 (PCLK),
        .PRESET_n             (PRESET_n),
        .mstr_i               (mstr),
        .spiswai_i           (spiswai),
        .send_data_i          (send_data),
        .baudratedivisor_i    (baudratedivisor),
        .spi_mode_i           (spi_mode),
        .tip_o                (tip),
        .receive_data_o       (receive_data),
        .ss_o                 (ssoe)
    );
	assign ss_o=ssoe;
	
endmodule