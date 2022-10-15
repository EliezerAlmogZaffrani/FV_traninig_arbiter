module fsm(
        input clk, 
        input rstn, 
        input in,
        output logic out
    );
    enum { STATE0=3'b000, STATE1, STATE2, STATE3, 
        STATE4, STATE5, STATE6 } state, next_state;
    
    // next state logic
    always_comb begin
        case(state)
            STATE0: next_state = in ? STATE1 : STATE4;
            STATE1: next_state = in ? STATE2 : STATE4;
            STATE2: next_state = in ? STATE3 : STATE4;
            STATE3: next_state = in ? STATE3 : STATE4;
            STATE4: next_state = in ? STATE5 : STATE4;
            STATE5: next_state = in ? STATE2 : STATE6;
            STATE6: next_state = in ? STATE5 : STATE4;
            endcase
    end
    
    // register
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn)
            state <= STATE0;
        else
            state <= next_state;
    end
    
    // Output logic
    always_comb begin
        case(state)
            STATE0: out = 1'b0;
            STATE1: out = 1'b0;
            STATE2: out = 1'b0;
            STATE3: out = 1'b1;
            STATE4: out = 1'b0;
            STATE5: out = 1'b0;
            STATE6: out = 1'b1;
        endcase
    end
    
    `include "../src/fsm_assert.sva"
    `include "../src/fsm_spec.sva"
    
endmodule

