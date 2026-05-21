module ahb_slave_if (
    input               HCLK,
    input               HRESETn,
    input      [31:0]   HADDR,
    input      [31:0]   HWDATA,
    input               HWRITE,
    input      [1:0]    HTRANS,
    input               HREADY,
    input               bridge_busy,   // NEW: 1 when FSM is not IDLE

    output reg [31:0]   addr_reg,
    output reg [31:0]   wdata_reg,
    output reg          write_reg,
    output reg          valid_req
);

// Only accept new transaction when:
//   - HREADY=1 (bus is free from master side)
//   - HTRANS=NONSEQ (master is starting a transfer)
//   - bridge NOT busy (we have room to accept)
wire addr_phase_valid = HREADY && (HTRANS == 2'b10) && !bridge_busy;

reg pending_write;

always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        addr_reg      <= 32'd0;
        wdata_reg     <= 32'd0;
        write_reg     <= 1'b0;
        valid_req     <= 1'b0;
        pending_write <= 1'b0;
    end
    else begin
        if (addr_phase_valid) begin
            addr_reg      <= HADDR;
            write_reg     <= HWRITE;
            pending_write <= HWRITE;
            valid_req     <= 1'b1;
        end
        else begin
            valid_req     <= 1'b0;
            pending_write <= 1'b0;
        end

        if (pending_write)
            wdata_reg <= HWDATA;
    end
end

endmodule
