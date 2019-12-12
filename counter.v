module counter (EN,Clock,Reset_n,Q,Cout);
		parameter n = 4;
		parameter k = 67108863;
		input EN,Clock, Reset_n;
		output [n-1:0] Q;
		reg [n-1:0] Q;
		output Cout;
		reg Cout;
		always @(posedge Clock or negedge Reset_n)
			begin
				if (!Reset_n)
					Q <= 1'd0;
				else
					if(Q == k -1)
					begin
						Q <= 1'd0;
						Cout <= 1'd1;
					end
					else
						if(EN)
						begin
							Q <= Q + 1'b1;
							Cout <= 1'd0;
						end
			end
endmodule