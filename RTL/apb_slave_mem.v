//////////////////////////////
// apb_slave_mem.v  (UNCHANGED - correct as-is)
//////////////////////////////
// 
// This module is correct. PRDATA is combinational,
// which is exactly right per APB spec.
// The bridge_fsm now captures PRDATA into hrdata_reg
// at the right moment (ACCESS state, PREADY=1).
// So the slave needs no changes.

module apb_slave_mem (

    input               PCLK,
    input               PRESETn,

    input      [31:0]   PADDR,
    input      [31:0]   PWDATA,
    input               PWRITE,
    input               PSEL,
    input               PENABLE,

    output reg [31:0]   PRDATA,
    output              PREADY

);

reg [31:0] mem [0:15];

assign PREADY = 1'b1;  // always ready (no wait states)

integer i;

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] <= 32'd0;
    end
    else begin
        if (PSEL && PENABLE && PWRITE)
            mem[PADDR[5:2]] <= PWDATA;
    end
end

always @(*) begin
    if (PSEL && PENABLE && !PWRITE)
        PRDATA = mem[PADDR[5:2]];
    else
        PRDATA = 32'd0;
end

endmodule