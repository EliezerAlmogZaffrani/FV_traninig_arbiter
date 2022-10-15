module training_arbiter(
        clk,
        reset_n,
        sp,
        in,
        arb,
        restart,
        restart_in,
        select,
        last
    );

    parameter
    W = 8;

    input clk;
    input reset_n;
    input sp; // switches to strict priority mode
    input [W-1:0] in; // input bus for arbitration
    input arb; // sample select for next arbitration
    input restart; // forces arbiter to use restart bus input as last selection.
    input [W-1:0] restart_in; // input restart bus, used to force RR arbitartion start point.
    output [W-1:0] select; // 1hot output bus arbitration result
    output [W-1:0] last; // sampled last selection vector - informative

    reg [W-1:0] last;
    reg [2*W-1:0] vec[W-1:0];
    reg [W-1:0] vec_inv[2*W-1:0];
    reg [2*W-1:0] mat[W-1:0];
    reg [2*W-1:0] sp_in;
    wire [2*W-1:0] sp_select;
    integer i,j;
    logic [W-1:0] tmp_select;
    logic [W-1:0] last_to_calc;

    parameter
    L = 2048'h0,
    H = 2048'h1;

    wire [W-1:0] base = restart ? {restart_in[W-2:0],restart_in[W-1]} : last_to_calc;

    always @(*) begin
// mat[0] = {{W{1'b0}},{W{1'b1}}};
        mat[0] = {{W-1{1'b0}},{W{1'b1}},1'b0};
        for (i=1;i<W;i=i+1) mat[i] = {mat[i-1][2*W-2:0],1'b0};
        for (i=0;i<W;i=i+1) vec[i] = base[i] ? (mat[i]&{in,in}) : L[2*W-1:0];
        for (j=0;j<W;j=j+1) for (i=0;i<2*W;i=i+1) vec_inv[i][j] = vec[j][i];
        for (i=0;i<2*W;i=i+1) sp_in[i] = sp ? in[i%W] : |vec_inv[i];
    end

    gen_ms1_ls1 #(.W(2*W)) gen_ms1_ls1(
        .ls_mode(1'b1),
        .in(sp_in),
        .select(sp_select)
    );

    wire [W-1:0] select = (restart || !arb) ? tmp_select : (sp_select[2*W-1:W])|(sp_select[W-1:0]);

    always_comb begin
        if (!arb) tmp_select = last;
        if (restart) tmp_select = restart_in;
        
        if (last == '0) last_to_calc = {1,{W-1{1'b0}}};
        else last_to_calc = last;
    end
    // Gali - Changed from:
//    wire [W-1:0] select = (sp_select[2*W-1:W])|(sp_select[W-1:0]);

    always @(posedge clk or negedge reset_n)
    begin
        if (~reset_n) last <= L[W-1:0];
        //Gali - Changed from:
//        if (~reset_n) last <= H[W-1:0];
        else
            if (restart) last <= restart_in; // Gali - Added
            else if (arb) last <= select;
            else last <= last; // Gali - Added
    end

endmodule
