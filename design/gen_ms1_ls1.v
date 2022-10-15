module gen_ms1_ls1 #( parameter W = 128 )
(
 input  wire [W-1:0] in,
 output wire [W-1:0] select,
 input  wire ls_mode
);

reg [W-1:0] mat[W-1:0];
reg [W-1:0] select_int;

function [W-1:0] bit_swizzle;
 input [W-1:0] in;
 reg [W-1:0] out;
 integer x;
 begin
  for (x=0;x<W;x=x+1) out[(W-1-x)] = in[x];
  bit_swizzle = out;
 end 
endfunction

integer i,k;

wire [W-1:0] in_int = ls_mode ? bit_swizzle(in) : in;
assign select = ls_mode ? bit_swizzle(select_int) : select_int;

always @* begin
   mat[W-1] = {W{1'b0}};
   for (i=W-2;i>=0;i=i-1) mat[i] = {1'b1,mat[i+1][W-1:1]};
   select_int[W-1] = in_int[W-1];
   for (k=0;k<W;k=k+1) select_int[k] = ~|(mat[k]&in_int)&in_int[k]; // Gali - writes over last assignment
end

endmodule
