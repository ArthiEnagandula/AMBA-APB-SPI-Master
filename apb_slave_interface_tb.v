module apb_slave_interface_tb();

    reg         PCLK;
    reg         PRESET_n;
    reg [2:0]   PADDR_i;
    reg         PWRITE_i;
    reg         PSEL_i;
    reg         PENABLE_i;
    reg [7:0]   PWDATA_i;

    reg         ss_i;
    reg [7:0]   miso_data_i;
    reg         receive_data_i;
    reg         tip_i;

    wire [7:0]  PRDATA_o;
    wire        mstr_o;
    wire        cpol_o;
    wire        cpha_o;
    wire        lsbfe_o;
    wire        spiswai_o;
    wire [2:0]  sppr_o;
    wire [2:0]  spr_o;
    wire        spi_interrupt_request_o;
    wire        PREADY_o;
    wire        PSLVERR_o;
    wire        send_data_o;
    wire [7:0]  mosi_data_o;
    wire [1:0]  spi_mode_o;


    apb_slave_interface DUT (

        .PCLK                     (PCLK),
        .PRESET_n                 (PRESET_n),

        .PADDR_i                  (PADDR_i),
        .PWRITE_i                 (PWRITE_i),
        .PSEL_i                   (PSEL_i),
        .PENABLE_i                (PENABLE_i),
        .PWDATA_i                (PWDATA_i),

        .ss_i                     (ss_i),
        .miso_data_i              (miso_data_i),
        .receive_data_i           (receive_data_i),
        .tip_i                    (tip_i),

        .PRDATA_o                 (PRDATA_o),
        .mstr_o                   (mstr_o),
        .cpol_o                   (cpol_o),
        .cpha_o                   (cpha_o),
        .lsbfe_o                  (lsbfe_o),
        .spiswai_o                (spiswai_o),
        .sppr_o                   (sppr_o),
        .spr_o                    (spr_o),
        .spi_interrupt_request_o  (spi_interrupt_request_o),
        .PREADY_o                 (PREADY_o),
        .PSLVERR_o                (PSLVERR_o),
        .send_data_o              (send_data_o),
        .mosi_data_o              (mosi_data_o),
        .spi_mode_o               (spi_mode_o)
    );


    initial begin
        PCLK = 1'b0;
        forever #5 PCLK = ~PCLK;
    end


    task initialize;
     begin

        PRESET_n        = 1'b0;

        PADDR_i         = 3'b000;
        PWRITE_i        = 1'b0;
        PSEL_i          = 1'b0;
        PENABLE_i       = 1'b0;
        PWDATA_i        = 8'h00;

        ss_i            = 1'b1;
        miso_data_i     = 8'h00;
        receive_data_i  = 1'b0;
        tip_i           = 1'b0;

      end
    endtask
	
     task reset;
	begin
		PRESET_n = 1'b0;
		#20 PRESET_n = 1'b1;
	end
      endtask

	
task stimulus;
	begin
		@(negedge PCLK)
		//spiswai_i = 1'b0;
		ss_i = 1'b0;
		tip_i = 1'b1;
		#20;
	end
endtask
		
    task apb_write(input [2:0] addr, input [7:0] data);
	  begin

            // IDLE 
            @(negedge PCLK);

            PADDR_i   = addr;
            PWDATA_i  = data;
            PWRITE_i  = 1'b1;
            PSEL_i    = 1'b0;
            PENABLE_i = 1'b0;

            // SETUP 
            @(negedge PCLK);
    	    PSEL_i    = 1'b1;
            PENABLE_i = 1'b0;
          

            // ENABLE
            @(negedge PCLK);
			PADDR_i   = addr;
            PWDATA_i  = data;
            PWRITE_i  = 1'b1;
			PSEL_i    = 1'b1;
            PENABLE_i = 1'b1;

        end

    endtask
	
      task apb_read(input [2:0]addr);
         begin
            // IDLE -> SETUP
            @(negedge PCLK);

            PADDR_i   = addr;
            PWRITE_i  = 1'b0;
            PSEL_i    = 1'b0;
            PENABLE_i = 1'b0;

      	    
            // SETUP -> ENABLE
            @(negedge PCLK);
    	    PSEL_i    = 1'b1;
            PENABLE_i = 1'b0;
          

            // ENABLE
            @(negedge PCLK);
			PADDR_i   = addr;
			PWRITE_i  = 1'b0;
			PSEL_i    = 1'b1;
            PENABLE_i = 1'b1;

        end
    endtask

    initial
      begin
        initialize;
	reset;

        stimulus;

        apb_write(3'b000, 8'b1101_1101);

        #20;
        apb_read(3'b000);

        #20;
        apb_write(3'b001, 8'b1111_1111);

        #20;
        apb_read(3'b001);

        #20;
        apb_write(3'b010, 8'b1111_1111);

        #20;
        apb_read(3'b010);

        #20;
        apb_write(3'b101, 8'hA5);

        #20;
        apb_read(3'b101);

        #20;
        receive_data_i = 1'b1;
        miso_data_i    = 8'h5A;

        @(posedge PCLK);

        receive_data_i = 1'b0;

        #20;
	$finish;
	end
endmodule