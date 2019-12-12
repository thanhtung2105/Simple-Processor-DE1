// Thanh ghi R data_in, L enable
module regn(R,L,Clock,Q);
	parameter n = 8;
	input [n-1:0]R;
	input L,Clock;
	output reg [n-1:0]Q;
	
	always@(posedge Clock)
		if(L)
			Q <= R;
endmodule
