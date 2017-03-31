module FinalProject
	(
		CLOCK_50,
		KEY,
		SW,
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		VGA_CLK,
		VGA_HS,
		VGA_VS,
		VGA_BLANK_N,
		VGA_SYNC_N,
		VGA_R,
		VGA_G,
		VGA_B
	);
	
	input CLOCK_50;
	input [3:0] KEY;	// Movements
	input [9:0] SW;		// only use SW[9] to reset counter
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	
	wire clock = CLOCK_50;
	
	wire button_left;
	wire button_right;
	wire button_up;
	wire button_down;
	assign button_left = KEY[3];
	assign button_right = KEY[2];
	assign button_up = KEY[1];
	assign button_down = KEY[0];
	
	// Number of moves
	reg [15:0] num_moves = 16'b0000000000000000;

	// Color switches
	wire [2:0] colour;
	assign colour = SW[2:0];

	// Switch to create dotted lines
	wire dot;
	assign dot = SW[3];

	// Reset switch
	wire reset;
	assign reset = SW[9];
	
	// Variable to enable movement
	reg [18:0] move_counter;

	// x and y coordinates for the cursor
	reg [8:0] cursor_x = 8'b00000110;
	reg [7:0] cursor_y = 7'b0000111; 

	wire writeEn = 1'b1;
	
	vga_adapter cursor(
			.resetn(1'b1),
			.clock(CLOCK_50),
			.colour(colour),
			.x(cursor_x),
			.y(cursor_y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam cursor.RESOLUTION = "160x120";
		defparam cursor.MONOCHROME = "FALSE";
		defparam cursor.BITS_PER_COLOUR_CHANNEL = 1;
		defparam cursor.BACKGROUND_IMAGE = "black.mif";

	always@(posedge clock) 
	begin
		move_counter = move_counter + 1;
		if(move_counter == 0 && reset == 0)
		begin
			// Perform movement
			if(~button_left) 
			begin
				cursor_x = (cursor_x - 3'b001 - dot);
				num_moves = num_moves + 1;
			end
			if(~button_right)
			begin
				cursor_x = (cursor_x + 3'b001 + dot);
				num_moves = num_moves + 1;
			end
			if(~button_up) 
			begin
				cursor_y = (cursor_y - 3'b001 - dot);
				num_moves = num_moves + 1;
			end
			if(~button_down) 
			begin
				cursor_y = (cursor_y + 3'b001 + dot);
				num_moves = num_moves + 1;
			end
		end
		// Reset
		else if (reset == 1)
		begin
			num_moves = 16'b0000000000000000;

//			Here we tried to reset the entire screen to black by changing
//			the cursor to black and moving it across the screen.

//			cursor_x = 8'b00000000;
//			cursor_y = 7'b0000000;
//			// Somehow change square to black (colour <= 0)?
////			assign colour = 3'b000;
//			if (cursor_x != 8'b01010000)
//			begin 
//				cursor_x = cursor_x + 1'b1;
//			end
//			else
//			begin
//				cursor_y = cursor_y + 1'b1;
//				cursor_x = 8'b00000000;
//			end
//			// Center the cursor when it reaches bottom right corner.
//			if (cursor_y == 7'b1111000 && cursor_x == 8'b10100000)
//			begin
//				cursor_x = 8'b01010000;
//				cursor_y = 7'b0111100; 
//			end
		end
	end
	// Show the number of moves in hexadecimal with four hex displays.
	hex_decoder h0(.hex_digit(num_moves[3:0]), .segments(HEX0));
	hex_decoder h1(.hex_digit(num_moves[7:4]), .segments(HEX1));
	hex_decoder h2(.hex_digit(num_moves[11:8]), .segments(HEX2));
	hex_decoder h3(.hex_digit(num_moves[15:12]), .segments(HEX3));
	
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
    
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule