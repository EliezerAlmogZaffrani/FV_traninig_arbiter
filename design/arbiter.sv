module arbiter
    #(
        parameter NUM=3
    )
    (
        input clk, 
        input rst,
        input [$clog2(NUM):0] bid,
        output logic [$clog2(NUM):0] win
    );

    integer i1, i2;
    logic [$clog2(NUM):0] last_win;
    logic [$clog2(NUM):0] win_index;
    logic won;
    
    always_comb begin
        win[last_win] = 0;
        won = 1'b0;
        win_index = last_win;
        
        for (i1 = 0; i1 < NUM; i1++) begin
           if (bid[(last_win + i1)%NUM] && !won) begin
               win[(last_win + i1)%NUM] = 1;
               won = 1'b1;
               win_index = (last_win + i1)%NUM;
           end 
        end
 
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            last_win <= 0;
        end
        else
            last_win <= win_index;
    end
    
endmodule 
