module fifo
    #(
        parameter FIFO_SIZE=3, 
        parameter DATA_WIDTH=4
    )
    (
        input clk, 
        input rst, 
        input push, 
        input pop,
        input [DATA_WIDTH-1:0] d_in,
        output logic [DATA_WIDTH-1:0] d_out,
        output logic empty, 
        output logic full
    );

    logic [DATA_WIDTH-1:0] mem [FIFO_SIZE-1:0];
    integer i1,i2,i3;
    logic size, push_index, next_size;
    
    always_comb begin
        next_size = size;
        
        if (push && !full) begin
            next_size = next_size + 1;
        end
        
        if (pop && !empty) begin
            next_size = next_size - 1;
            d_out = mem[(push_index - size)%FIFO_SIZE];
        end
        else
            d_out = 0;
        
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i1 = 0; i1 < FIFO_SIZE; i1++)
                mem[i1] <= 0;
            
            size <= 0;
            push_index <= 0;
            empty <= 1'b1;
            full <= 1'b0;
        end
        
        else begin
            size <= next_size;
            
            if (next_size == 0)
                empty <= 1'b1;
            else
                empty <= 1'b0;
            
            if (next_size == FIFO_SIZE-1)
                full <= 1'b1;
            else
                full <= 1'b0;
            
            if (push && !full) begin
                push_index <= (push_index + 1) % FIFO_SIZE;
                for (i3 = 0; i3 < FIFO_SIZE; i3++)
                    mem[i3] <= mem[i3];
                mem[push_index] <= d_in;
            end
            else begin
                push_index <= push_index;
                for (i2 = 0; i2 < FIFO_SIZE; i2++)
                    mem[i2] <= mem[i2];
            end
                
            
        end
 
    end
    
    `include "../src/fifo_assume.sva"
    `include "../src/fifo_assert.sva"
    
endmodule 