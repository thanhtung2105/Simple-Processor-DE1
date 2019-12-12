module lab9_part1(SW,CLOCK_50,LEDR,LEDG,KEY,HEX1,HEX2,HEX3,HEX0);
	input [9:0]SW;
	input CLOCK_50;
	input [3:0]KEY;
	output [7:0]LEDG;
	output [9:0]LEDR;
	output [6:0]HEX1,HEX2,HEX3,HEX0;
	
	wire Clock,Reset,w,Done;
	wire [25:0]C;
	wire K;
	wire [8:0]BusWire,BusWireReg;
	
	
	counter clk(1'b1,CLOCK_50,Reset,C,K);
		defparam clk.n = 26;
	
	assign Clock = C[25];
	assign Reset = KEY[0];
	assign w = ~KEY[3];
	assign LEDG[7] = SW[9];
	assign LEDG[5] = Clock;
	assign LEDG[0] = Done;
	assign LEDR[8:0] = BusWire;

	wire [8:0]Func,Data;
	
	regn switch1(SW[8:0],1'b1,SW[9],Func);
				defparam switch1.n = 9;

	
	regn switch2(SW[8:0],1'b1,~SW[9],Data);
				defparam switch2.n = 9;
	
	wire [15:0]Result;
	proc2(Data,Reset,w,Clock,Func,Done,BusWire);
	
	regn resultreg(BusWire,Done,Clock,BusWireReg);
		defparam resultreg.n = 9;
	
	
	wire [3:0]h3,h2,h1,h0;
	assign Result = {7'b0,BusWireReg};
	bin2bcd(Result,h3,h2,h1,h0);
	
	hex_display H3(h3,HEX3);
	hex_display	H2(h2,HEX2);
	hex_display	H1(h1,HEX1);
	hex_display	H0(h0,HEX0);
	
endmodule


// 9bit Data ,7 bo nho
module proc2(Data,Reset,w,Clock,Func,Done,BusWire);
	input [8:0]Data;
	input Reset,w,Clock;
	input [8:0]Func;
	output reg [8:0]BusWire;
	output reg Done;
	
	wire [8:0]R0,R1,R2,R3,R4,R5,R6,R7,A,G; // Khai bao cac thanh ghi
	wire [8:0]FuncReg;							// Thanh ghi lưu trữ phương thức Function
	wire [7:0]Xreg,Yreg;							// Thanh ghi luư trữ địa chỉ thanh ghi X và thanh ghi Y 
	
	wire [2:0]I;
	reg [0:7]Rin,Rout;							// Lần lượt là tín hiệu cho phép vao thanh ghi và tín hiệu để đưa ra Bus 
	reg Extern,Ain,Gin,Gout,AddSub,Carry;	// Tin hiệu Data, 2 thanh ghi A và G, tín hiệu công/trừ và nhớ
	reg [8:0]Sum;									// Lưu kết quả
	wire [9:0]MUX;									// Lưu chọn của Mux để đưa dữ liệu ra Bus
	
	parameter T0 = 2'b00,T1 = 2'b01,T2 = 2'b10,T3 = 2'b11;	// 4 Trạng thái của FSM
	
	regn FunctionReg(Func,1'b1,w,FuncReg);		// Khi có tín hiệu vào Function sẽ được nạp và lưu vào bộ nhớ 
		defparam FunctionReg.n = 9;
	
	// Giải mã Function
	assign I = FuncReg[8:6];
	dec3to8 decX(FuncReg[5:3],1'b1,Xreg);
	dec3to8 decY(FuncReg[2:0],1'b1,Yreg);
	
	//Thiet ke bo FMS
	reg [1:0]Step_D,Step_Y;
	
	always@(Step_Y,w)
		case(Step_Y)
						T0:	if(w)	Step_D = T1;		// Khi có tín hiệu Chạy
								else  Step_D = T0;
						T1:		Step_D = T2;
						T2: 		Step_D = T3;
						T3:		Step_D = T0;
		endcase
		
	always@(negedge Reset,posedge Clock)
		if(!Reset) Step_Y <= T0;
		else Step_Y <= Step_D;				// Trạng thái sau lưu bằng trạng thái trước 
		
	
	// Tác vụ ứng với mỗi trạng thái của FSM khi được chạy 
	always@(Step_Y)
	begin
		Extern = 1'b0; Done = 1'b0; Ain = 1'b0; Gin = 1'b0;
		Gout = 1'b0; AddSub = 1'b0; Rin = 8'b0; Rout = 8'b0;
		case(Step_Y)
			T0: ; 									//Step 0
			T1: case(I)								//Step 1
						3'b000: begin
									Extern = 1'b1;	// Nạp dữ liệu ngoài vào Bus
									Rin = Xreg;		// Đưa dữ liệu Bus vào địa chỉ thanh ghi X
									Done = 1'b1;	// Tín hiệu hoàn thành
								end
						3'b001:begin
									Rout = Yreg;	// Nạp dữ liệu thanh ghi Y vào bus 
									Rin = Xreg;		// Nạp dữ liệu Bus vào thanh ghi X
									Done = 1'b1;	// Tín hiệu hoàn thành
								end
						3'b010,3'b011: begin 	// add,sub
									Rout = Xreg;	// Nạp dữ liệu thanh ghi X vào bus
									Ain = 1'b1;		// Nạp dữ liệu Bus vào thanh ghi A
								end
						3'b100:begin				// CheckData
									Rout = Xreg;	// Nạp dữ liệu thanh ghi X vào bus
									Done = 1'b1;	// Tín hiệu hoàn thành
								end
				endcase
			T2:										//Step T2
				case(I)
					3'b010: begin					// Add
						Rout = Yreg;				// Nạp dữ liệu thanh ghi Y vào bus
						Gin = 1'b1; 				// Khi này bộ tính toán sẽ hoạt động cộng 2 dữ liệu và nạp dữ liệu vào thanh ghi G
						end
					3'b011:begin					// Sub
						Rout = Yreg;				// Nạp dữ liệu thanh ghi Y vào bus
						AddSub = 1'b1;				// Bật chế độ Trừ
						Gin = 1'b1;					// Bộ tính toán hoạt động trừ 2 dữ liệu và nạp dữ liệu vào thanh ghi G
						end
					default: ;
				endcase
			T3:	//Step T3
				case(I)
					3'b010,3'b011:begin
						Gout = 1'b1;				// Dua Gia tri G ra bus
						Rin = Xreg; 				// Bus vao tram Rx
						Done = 1'b1;				// Tín hiệu hoàn thành 
						end
				default:;
				endcase
			default:;
			endcase
	end
	
	
	// Nạp dữ liệu từ Bus Wire vào thanh ghi khi có tin hiệu Rin co phép
	
	regn reg_0(BusWire,Rin[0],Clock,R0);
		defparam reg_0.n = 9;
	regn reg_1(BusWire,Rin[1],Clock,R1);
		defparam reg_1.n = 9;
	regn reg_2(BusWire,Rin[2],Clock,R2);
		defparam reg_2.n = 9;
	regn reg_3(BusWire,Rin[3],Clock,R3);
		defparam reg_3.n = 9;
	regn reg_4(BusWire,Rin[4],Clock,R4);
		defparam reg_4.n = 9;
	regn reg_5(BusWire,Rin[5],Clock,R5);
		defparam reg_5.n = 9;
	regn reg_6(BusWire,Rin[6],Clock,R6);
		defparam reg_6.n = 9;
	regn reg_7(BusWire,Rin[7],Clock,R7);
		defparam reg_7.n = 9;
	regn reg_A(BusWire,Ain,Clock,A);
		defparam reg_A.n = 9;
		
	
	
	// Bộ tính toán
	always @(AddSub,A,BusWire)
		begin
			if(!AddSub)
				{Carry,Sum} = A + BusWire;
			else
				{Carry,Sum} = A - BusWire;
		end
	
	// Nạp kết quả vào thanh ghi G khi Gin được bật
	regn reg_G(Sum,Gin,Clock,G);
		defparam reg_G.n = 9;
	


	//Bộ đa hợp quản lý các luồng ra Bus bằng các tính hiệu Rout, Gout và Extern
	assign MUX = {Rout,Gout,Extern};
	
	always@(MUX,R0,R1,R2,R3,R4,R5,R6,R7,Gout,Extern)
	begin
		case(MUX)
			10'b1000000000 : BusWire <= R0;
			10'b0100000000 : BusWire <= R1;
			10'b0010000000 : BusWire <= R2;
			10'b0001000000 : BusWire <= R3;
			10'b0000100000 : BusWire <= R4;
			10'b0000010000 : BusWire <= R5;
			10'b0000001000 : BusWire <= R6;
			10'b0000000100 : BusWire <= R7;
			10'b0000000010 : BusWire <= G;
			10'b0000000001 : BusWire <= Data;
			
			default: ;
		endcase
	end

endmodule

//--------------------------------------------------------------------------------------

module Mux2_1_9bit(A,B,S,F);
	input [8:0]A,B,S;
	output [8:0]F;
	Mux2_1(A[8],B[8],S,F[8]);
	Mux2_1(A[7],B[7],S,F[7]);
	Mux2_1(A[6],B[6],S,F[6]);
	Mux2_1(A[5],B[5],S,F[5]);
	Mux2_1(A[4],B[4],S,F[4]);
	Mux2_1(A[3],B[3],S,F[3]);
	Mux2_1(A[2],B[2],S,F[2]);
	Mux2_1(A[1],B[1],S,F[1]);
	Mux2_1(A[0],B[0],S,F[0]);
	
endmodule

module Mux2_1(a,b,s,f);
	input a, b , s ;
	output f ;
	assign f  = (~s&a)|(s&b);
endmodule
