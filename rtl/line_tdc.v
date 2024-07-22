module line_tdc#(
	parameter STAGE 					 = 256
)(
	input wire 							sg_start,
	input wire 							clk_bufg,
	input wire 							reset,
	output wire [STAGE - 1:0]			value_latch	
);

wire [STAGE - 1:0] dat_reg0;
wire [STAGE - 1:0] dat_reg1;

genvar i;
generate
	for (i = 0; i <= STAGE/4 - 1; i = i+1) begin
		if(i == 0) begin :carry4_first
			CARRY4 CARRY4_INST (
				.CO				(dat_reg0[3:0]),      			// 4-bit carry out
				.O				(),           				// 4-bit carry chain XOR data out
				.CI				(1'b0),         			// 1-bit carry cascade input
				.CYINIT			(sg_start), 				// 1-bit carry initialization
				.DI				(4'b0000),      			// 4-bit carry-MUX data in
				.S				(4'b1111)       			// 4-bit carry-MUX select input
			);
		end
		if (i > 0) begin :carry4_others
			CARRY4 CARRY4_OTHERS (
				.CO				(dat_reg0[4*(i+1)-1:4*i]),	// 4-bit carry out
				.O				(),           				// 4-bit carry chain XOR data out
				.CI				(dat_reg0[4*i-1]),       	// 1-bit carry cascade input
				.CYINIT			(1'b0), 					// 1-bit carry initialization
				.DI				(4'b0000),      			// 4-bit carry-MUX data in
				.S				(4'b1111)       			// 4-bit carry-MUX select input
			);
		end
	end
endgenerate
   
genvar j;
generate 
	for (j = 0; j <= STAGE - 1; j = j+1) begin:loop_fdre
		FDRE #(
			.INIT				(1'b0) 						// Initial value of register (1'b0 or 1'b1)
		) FDRE_INST0 (			
			.Q					(dat_reg1[j]),   			// 1-bit Data output
			.C					(clk_bufg),      			// 1-bit Clock input
			.CE					(1'b1), 					// 1-bit Clock enable input
			.R					(reset),  					// 1-bit Synchronous reset input
			.D					(dat_reg0[j])    			// 1-bit Data input
		);
		
		FDRE #(
			.INIT				(1'b0) 						// Initial value of register (1'b0 or 1'b1)
		) FDRE_INST1 (		
			.Q					(value_latch[j]),			// 1-bit Data output
			.C					(clk_bufg),      			// 1-bit Clock input
			.CE					(1'b1),    					// 1-bit Clock enable input
			.R					(reset),      				// 1-bit Synchronous reset input
			.D					(dat_reg1[j])       			// 1-bit Data input
		);
	end
endgenerate

endmodule
