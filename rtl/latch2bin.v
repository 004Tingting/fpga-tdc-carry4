module latch2bin#(
	parameter GAP_BITS 					 = 8

)(
	input wire 							clk_bufg,
	input wire 							reset,
	input wire 							valid,
	input wire  [(2**GAP_BITS)-1:0]     value_latch,
	output reg                          bin_cs,
	output reg [GAP_BITS-1:0]			bin		
);

(* dont_touch="true" *)reg [(2**GAP_BITS)-2:0] decoding [0:GAP_BITS-4];

(* dont_touch="true" *)reg [GAP_BITS:0] binary [0:GAP_BITS-3];

(* dont_touch="true" *)reg [GAP_BITS-2:0] data_valid;

(* dont_touch="true" *)reg [15:0] decode_final;

(* dont_touch="true" *)reg [GAP_BITS-1:0] bin_final;

(* dont_touch="true" *)reg [3:0] ones;

(* dont_touch="true" *)reg [GAP_BITS:0] binary_r;

always@(*) begin
    decoding[0] = value_latch[(2**GAP_BITS)-2:0];
    data_valid[0] <= valid;
end

genvar i;
generate
	for (i = 0; i <= GAP_BITS-5; i = i+1) begin
        always@(posedge clk_bufg) begin
            if(reset) begin
                decoding[i+1] <= 'd0;
                binary[i+1] <= 1'b0;
                data_valid[i+1] <= 1'b0;
            end
            else begin
                binary[i+1][GAP_BITS:GAP_BITS-1-i] <= {binary[i][GAP_BITS:GAP_BITS-i],decoding[i][((2**(GAP_BITS-i))-2)/2]};    
                data_valid[i+1] <= data_valid[i];
                if(decoding[i][((2**(GAP_BITS-i))-2)/2]==1'b1) begin
					decoding[i+1][((2**(GAP_BITS-i))-2)/2-1:0] <= decoding[i][((2**(GAP_BITS-i))-2):((2**(GAP_BITS-i))-2)/2+1];
				end
				else begin
					decoding[i+1][((2**(GAP_BITS-i))-2)/2-1:0]	<= decoding[i][((2**(GAP_BITS-i))-2)/2-1:0];
				end
			end
		end
	end
endgenerate

always@(posedge clk_bufg) begin
    if(reset) begin
        ones <= 4'd0;
        data_valid[GAP_BITS-3] <= 1'b0;
        binary[GAP_BITS-3] <= 'd0;
        bin_final <= 'd0;
    end
    else begin
        ones <= 
        decoding[GAP_BITS-4][0] + decoding[GAP_BITS-4][1] + decoding[GAP_BITS-4][2] + decoding[GAP_BITS-4][3] +
        decoding[GAP_BITS-4][4] + decoding[GAP_BITS-4][5] + decoding[GAP_BITS-4][6] + decoding[GAP_BITS-4][7] +
        decoding[GAP_BITS-4][8] + decoding[GAP_BITS-4][9] + decoding[GAP_BITS-4][10] + decoding[GAP_BITS-4][11] +
        decoding[GAP_BITS-4][12] + decoding[GAP_BITS-4][13] + decoding[GAP_BITS-4][14] + decoding[GAP_BITS-4][15];
        
        data_valid[GAP_BITS-3] <= data_valid[GAP_BITS-4];
        binary[GAP_BITS-3] <= {binary[GAP_BITS-4][GAP_BITS-1:4],4'b0};
        
        data_valid[GAP_BITS-2] <= data_valid[GAP_BITS-3];
        bin_final <= {binary[GAP_BITS-3][GAP_BITS-1:4],ones[3:0]};
    end
end

always@(posedge clk_bufg) begin
    if(reset) begin
        bin_cs <= 1'b0;
        bin <= 'b0;
    end
    else begin
        if(data_valid[GAP_BITS-2] == 1'b1) begin
            bin_cs <= 1'b1;
            bin <= bin_final;
        end
        else begin
            bin_cs <= 1'b0;
            bin <= 'b0;
        end
    end
end

endmodule

