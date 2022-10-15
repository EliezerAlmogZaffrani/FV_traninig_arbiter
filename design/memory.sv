module memory
    #(
        parameter LINES_NUM=8, 
        parameter DATA_WIDTH=4
    )
    (
        input clk, 
        input rst, 
        input wr_en, 
        input rd_en,
        input [DATA_WIDTH-1:0] wr_data,
        input [$clog2(LINES_NUM) : 0] wr_addr, 
        input [$clog2(LINES_NUM) : 0] rd_addr,
        output logic [DATA_WIDTH-1:0] rd_data
    );

    logic [DATA_WIDTH-1:0] mem [LINES_NUM-1:0];
    integer i;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < LINES_NUM; i++)
                mem[i] <= 0;
        end
        
        else begin
            if (wr_en)
                mem[wr_addr] <= wr_data;
        end
    end
    
    always_comb begin
        if (rd_en)
                rd_data = mem[rd_addr];
            else
                rd_data = 0;
    end
    
    `include "../src/memory_assume.sva"
    `include "../src/memory_assert.sva"
    
endmodule 