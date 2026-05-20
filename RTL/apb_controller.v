//////////////////////////////
// apb_controller.v  (FIXED)
//////////////////////////////
//
// This module is purely combinational — it translates FSM state
// into APB control signals. No registers needed here.
//
// No functional changes except state width is now 3 bits.
// WDATA_WAIT state maps to IDLE behavior (PSEL=0, PENABLE=0).

module apb_controller (

    input      [31:0]   addr_reg,
    input      [31:0]   wdata_reg,   // renamed from data_reg for clarity
    input               write_reg,
    input      [2:0]    state,       // 3-bit now

    output reg [31:0]   PADDR,
    output reg [31:0]   PWDATA,
    output reg          PWRITE,
    output reg          PSEL,
    output reg          PENABLE

);

parameter IDLE       = 3'b000;
parameter WDATA_WAIT = 3'b001;
parameter SETUP      = 3'b010;
parameter ACCESS     = 3'b011;
parameter DONE       = 3'b100;

always @(*) begin
    // Safe defaults — prevents latches
    PADDR   = 32'd0;
    PWDATA  = 32'd0;
    PWRITE  = 1'b0;
    PSEL    = 1'b0;
    PENABLE = 1'b0;

    case (state)

        IDLE, WDATA_WAIT, DONE: begin
            // APB idle — no transaction
            PSEL    = 1'b0;
            PENABLE = 1'b0;
        end

        SETUP: begin
            // APB SETUP phase
            // PSEL=1, PENABLE=0, address/control valid
            PADDR   = addr_reg;
            PWDATA  = wdata_reg;   // for writes; irrelevant for reads
            PWRITE  = write_reg;
            PSEL    = 1'b1;
            PENABLE = 1'b0;
        end

        ACCESS: begin
            // APB ACCESS phase
            // PSEL=1, PENABLE=1, hold all signals stable
            PADDR   = addr_reg;
            PWDATA  = wdata_reg;
            PWRITE  = write_reg;
            PSEL    = 1'b1;
            PENABLE = 1'b1;
        end

    endcase
end

endmodule