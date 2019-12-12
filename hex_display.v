module hex_display(binary_input, hex_output);
  input [4:0] binary_input;
  output reg [6:0] hex_output;
// Hiển thị LED dưới dạng mã HEX 16 giá trị từ 0 - 15
  always begin
    case(binary_input)
      0:hex_output=7'b1000000;
      1:hex_output=7'b1111001;
      2:hex_output=7'b0100100;
      3:hex_output=7'b0110000;
      4:hex_output=7'b0011001;
      5:hex_output=7'b0010010;
      6:hex_output=7'b0000010;
      7:hex_output=7'b1111000;
      8:hex_output=7'b0000000;
      9:hex_output=7'b0010000;
      10:hex_output=7'b0001000;
      11:hex_output=7'b0000011;
      12:hex_output=7'b1000110;
      13:hex_output=7'b0100001;
      14:hex_output=7'b0000110;
      15:hex_output=7'b0001110;
    endcase
  end
endmodule
