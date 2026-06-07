// fsm has two states walk left and walk right
// walk left represents lemming walking left and walk right represents lemming walking right
// state transitions happen when bumped
module lemmings_1(input clk, areset, bump_left, bump_right, output reg walk_left, walk_right); 
    always @(posedge clk, posedge areset) begin
        if(areset) {walk_left, walk_right} <= 2'b10;
        else begin
            if(walk_left & bump_left) {walk_left, walk_right} <= 2'b01;
            if(walk_right & bump_right) {walk_left, walk_right} <= 2'b10;
        end
    end
endmodule

// fsm has three states- walk left, walk right, and falling
// falling represents state of lemming when there is no ground
module lemmings_2(input clk, areset, bump_left, bump_right, ground, output reg walk_left, walk_right, aaah);
    reg last_dirn;

    always @(posedge clk, posedge areset) begin
        if(areset) {walk_left, walk_right, aaah, last_dirn} <= 4'b1001;
        else if(~ground) {walk_left, walk_right, aaah} <= 3'b001;
        else begin
            if(~walk_left & ~walk_right) {walk_left, walk_right, aaah} <= {last_dirn, ~last_dirn, 1'b0}; 
            if(walk_left & bump_left) {walk_left, walk_right, aaah, last_dirn} <= 4'b0100;
            if(walk_right & bump_right) {walk_left, walk_right, aaah, last_dirn} <= 4'b1001;
        end
    end
endmodule

// fsm has four states- walk left, walk right, falling, and digging
// states are relatively self explanatory- also i changed the code to have actual state parameters because it was getting hard to handle all cases compactly
module lemmings_3(input clk, areset, bump_left, bump_right, ground, dig, output reg walk_left, walk_right, aaah, digging);
    parameter left = 4'b1000, right = 4'b0100, falling = 4'b0010, dgng = 4'b0001;
    reg [3:0] state, last_state;

    always @(posedge clk, posedge areset) begin
        if(areset) {state, last_state} <= {left, left};
        else begin
            case(state)
                left: begin
                    last_state <= left;
                    if(~ground) state <= falling;
                    else if(dig) state <= dgng;
                    else if(bump_left) state <= right;
                end

                right: begin
                    last_state <= right;
                    if(~ground) state <= falling;
                    else if(dig) state <= dgng;
                    else if(bump_right) state <= left;
                end

                falling: if(ground) state <= last_state;
                dgng: if(~ground) state <= falling;
            endcase
        end
        {walk_left, walk_right, aaah, digging} = state;
    end
endmodule

// fsm has five states- the four above states and also dead
// dead is when all outputs are zero
// no state transitions from dead- only way out is reset
module lemmings_4(input clk, areset, bump_left, bump_right, ground, dig, output reg walk_left, walk_right, aaah, digging);
    parameter left = 4'b1000, right = 4'b0100, falling = 4'b0010, dgng = 4'b0001, dead = 4'b0000;
    reg [3:0] state, last_state;
    reg [4:0] counter;

    always @(posedge clk, posedge areset) begin
        if(areset) {state, last_state, counter} <= {left, left, 5'b0};
        else begin
            case(state)
                left: begin
                    last_state <= left;
                    if(~ground) state <= falling;
                    else if(dig) state <= dgng;
                    else if(bump_left) state <= right;
                end

                right: begin
                    last_state <= right;
                    if(~ground) state <= falling;
                    else if(dig) state <= dgng;
                    else if(bump_right) state <= left;
                end

                falling: begin 
                    if(ground) begin
                        state <= last_state;
                        if(counter >= 20) state <= dead;
                        else counter <= 0;
                    end
                    else if(counter < 25) counter <= counter + 1;
                end
                dgng: if(~ground) state <= falling;
            endcase
        end
        {walk_left, walk_right, aaah, digging} = state;
    end
endmodule