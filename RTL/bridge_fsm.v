module bridge_fsm (
    input             HCLK,
    input             HRESETn,
    input             valid_req,
    input             write_reg,
    input             PREADY,
    input      [31:0] PRDATA,

    output reg [2:0]  state,
    output reg        HREADYOUT,
    output reg        HRESP,
    output reg [31:0] hrdata_reg,
    output reg        bridge_busy    // NEW: combinational busy flag
);

parameter IDLE       = 3'b000;
parameter WDATA_WAIT = 3'b001;
parameter SETUP      = 3'b010;
parameter ACCESS     = 3'b011;
parameter DONE       = 3'b100;

// Combinational busy: HIGH when FSM is not IDLE
// This is registered in ahb_slave_if on the next cycle,
// which is fine — by then the FSM has moved out of IDLE.
always @(*) begin
    bridge_busy = (state != IDLE);
end

always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        state      <= IDLE;
        HREADYOUT  <= 1'b1;
        HRESP      <= 1'b0;
        hrdata_reg <= 32'd0;
    end
    else begin
        case (state)

            IDLE: begin
                HREADYOUT <= 1'b1;
                HRESP     <= 1'b0;
                if (valid_req) begin
                    HREADYOUT <= 1'b0;
                    state <= write_reg ? WDATA_WAIT : SETUP;
                end
            end

            WDATA_WAIT: begin
                state <= SETUP;
            end

            SETUP: begin
                state <= ACCESS;
            end

            ACCESS: begin
                if (PREADY) begin
                    hrdata_reg <= PRDATA;
                    state      <= DONE;
                end
            end

            DONE: begin
                HREADYOUT <= 1'b1;
                state     <= IDLE;
            end

            default: begin
                state     <= IDLE;
                HREADYOUT <= 1'b1;
            end

        endcase
    end
end

endmodule
