module tdc_top#(
	parameter STAGE 					 = 200,
	parameter GAP_BITS 					 = 8
)(
	input wire 							sg_start,
	input wire 							clk_sys,
	input wire 							reset    ,
	output wire                         cs_gap,
	output wire [GAP_BITS-1:0]			value_gap		
);

wire clk_bufg;

clk_wiz_0 clk_wiz_0_inst(
	.clk_out1(clk_bufg),
	.clk_in1(clk_sys)
);

wire valid_pre;

wire valid;
wire [STAGE-1:0]					value_latch;

wire bin_cs;
wire [GAP_BITS-1:0] bin;

wire sg_bufr;

BUFR #(
    .BUFR_DIVIDE("BYPASS"),   // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
    .SIM_DEVICE("7SERIES")  // Must be set to "7SERIES" 
 )
BUFR_INST (
    .O(sg_bufr),        // 1-bit output: Clock output port
    .CE(1'b1),          // 1-bit input: Active high, clock enable (Divided modes only)
    .CLR(1'b0),         // 1-bit input: Active high, asynchronous clear (Divided modes only)
    .I(sg_start)        // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
);

FDCE #(
	.INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
) 
FDCE_INST2 (
	.Q(valid_pre),      // 1-bit Data output
	.C(clk_bufg),      	// 1-bit Clock input
	.CE(1'b1),    		// 1-bit Clock enable input
	.CLR(1'b0),  		// 1-bit Asynchronous clear input
	.D(sg_bufr)       	// 1-bit Data input
);

FDCE #(
	.INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
) 
FDCE_INST3 (
	.Q(valid),      // 1-bit Data output
	.C(clk_bufg),      // 1-bit Clock input
	.CE(1'b1),    // 1-bit Clock enable input
	.CLR(1'b0),  // 1-bit Asynchronous clear input
	.D(valid_pre)       // 1-bit Data input
);

line_tdc#(
	.STAGE								(STAGE)

) line_tdc_inst(
	.sg_start 							(sg_bufr),
	.clk_bufg 							(clk_bufg),
	.reset 								(reset),
	.value_latch 						(value_latch)
);



endmodule
