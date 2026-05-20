//////////////////////////////
// ahb_slave_if.v  (FIXED)
//////////////////////////////
// KEY INSIGHT: AHB is pipelined.
//   Address phase: HADDR, HWRITE, HTRANS are valid NOW
//   Data phase:    HWDATA is valid ONE CYCLE LATER (for writes)
//
// So we must:
//   Cycle N   → capture addr, hwrite, htrans (address phase)
//   Cycle N+1 → capture HWDATA (data phase, for writes only)
//
// This module captures address-phase signals into registers.
// HWDATA is handled separately (captured on the next cycle).

module ahb_slave_if (

    input               HCLK,
    input               HRESETn,

    input      [31:0]   HADDR,
    input      [31:0]   HWDATA,
    input               HWRITE,
    input      [1:0]    HTRANS,
    input               HREADY,

    output reg [31:0]   addr_reg,
    output reg [31:0]   wdata_reg,   // captured one cycle after addr
    output reg          write_reg,
    output reg          valid_req

);

// AHB HTRANS encoding
// 2'b00 = IDLE
// 2'b10 = NONSEQ  <- only type we handle in v1

// Wire to detect a valid AHB transfer in the address phase.
// HREADY=1 means the PREVIOUS transfer is done (bus is free),
// and HTRANS=NONSEQ means master is starting a new transfer.
wire addr_phase_valid = HREADY && (HTRANS == 2'b10);

// We need to remember if the captured transfer was a write,
// so we can decide whether to grab HWDATA on the next cycle.
reg pending_write;

always @(posedge HCLK or negedge HRESETn)
begin
    if (!HRESETn) begin
        addr_reg      <= 32'd0;
        wdata_reg     <= 32'd0;
        write_reg     <= 1'b0;
        valid_req     <= 1'b0;
        pending_write <= 1'b0;
    end
    else begin
        // -------------------------------------------------
        // STEP 1: Address phase — capture control signals
        // -------------------------------------------------
        // On every valid address phase, latch HADDR and HWRITE.
        // Do NOT latch HWDATA here — it isn't valid yet for writes.
        // For reads, HWDATA doesn't matter at all.
        
        if (addr_phase_valid) begin
            addr_reg      <= HADDR;
            write_reg     <= HWRITE;
            pending_write <= HWRITE;  // remember for next cycle
            valid_req     <= 1'b1;
        end
        else begin
            valid_req     <= 1'b0;
            pending_write <= 1'b0;
        end

        // -------------------------------------------------
        // STEP 2: Data phase — capture HWDATA for writes
        // -------------------------------------------------
        // HWDATA is valid exactly one cycle after the address phase.
        // pending_write tells us the previous cycle was a write address phase.
        // For reads, we skip this — HWDATA is irrelevant.
        
        if (pending_write) begin
            wdata_reg <= HWDATA;
        end
    end
end

endmodule