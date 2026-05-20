//////////////////////////////
// tb_ahb_apb_bridge.v — SIGNIFICANT FIX
//////////////////////////////
//
// ROOT CAUSE OF TESTBENCH BUG:
//
// The pattern:
//     @(posedge HCLK);
//     wait(HREADYOUT == 1);
//     @(posedge HCLK);
//     $display(HRDATA);
//
// Is BROKEN because if HREADYOUT is already 1 when the
// @(posedge HCLK) fires, the wait() passes through instantly.
// The following @(posedge HCLK) then fires ONE cycle too early,
// before the FSM has completed the current transaction.
//
// CORRECT PATTERN: Sample HREADYOUT synchronously on clock edges.
// Poll at each posedge: if HREADYOUT=1, transaction complete, read data.
// This is how a real AHB master works — it checks HREADYOUT
// at every clock edge, not with asynchronous wait().

`timescale 1ns/1ps

module tb_ahb_apb_bridge;

reg        HCLK;
reg        HRESETn;
reg [31:0] HADDR;
reg [31:0] HWDATA;
reg        HWRITE;
reg [1:0]  HTRANS;
reg        HREADY;

wire [31:0] HRDATA;
wire        HREADYOUT;
wire        HRESP;

ahb_apb_bridge_top DUT (
    .HCLK(HCLK), .HRESETn(HRESETn),
    .HADDR(HADDR), .HWDATA(HWDATA),
    .HWRITE(HWRITE), .HTRANS(HTRANS), .HREADY(HREADY),
    .HRDATA(HRDATA), .HREADYOUT(HREADYOUT), .HRESP(HRESP)
);

initial begin
    HCLK = 0;
    forever #5 HCLK = ~HCLK;
end

//------------------------------------------------------------
// reset_dut
//------------------------------------------------------------
task reset_dut;
begin
    HRESETn = 0;
    HADDR   = 0;
    HWDATA  = 0;
    HWRITE  = 0;
    HTRANS  = 2'b00;
    HREADY  = 1;
    repeat(4) @(posedge HCLK);
    HRESETn = 1;
    repeat(2) @(posedge HCLK);
end
endtask

//------------------------------------------------------------
// ahb_write
//------------------------------------------------------------
// Correct AHB-Lite write sequence:
//
//  Clk:  __|‾|__|‾|__|‾|__|‾|__|‾|__
//          T1   T2   T3   T4   T5
//
//  T1: Drive HADDR, HWRITE=1, HTRANS=NONSEQ  (address phase)
//  T2: Drive HWDATA                           (data phase, AHB pipeline)
//      HTRANS=IDLE
//  T3..Tn: Poll HREADYOUT at each posedge
//          When HREADYOUT=1, write is done
//
// We sample HREADYOUT AFTER the posedge (NBA settling).
// We do this by checking it after @(posedge HCLK) — meaning
// we look at the value clocked in at that edge.
//------------------------------------------------------------
task ahb_write;
    input [31:0] addr;
    input [31:0] data;
    integer done;
begin
    done = 0;

    // T1: Address phase
    @(posedge HCLK);
    #1;                    // small delay to let NBA settle before we drive
                           // ensures we don't overlap with DUT's NBA updates
    HADDR  = addr;         // blocking assignments in testbench after #1
    HWRITE = 1'b1;         // avoids NBA race with DUT sampling
    HTRANS = 2'b10;
    HREADY = 1'b1;

    // T2: Data phase — HWDATA now valid, one cycle after address
    @(posedge HCLK);
    #1;
    HWDATA = data;
    HTRANS = 2'b00;        // no next transfer
    HWRITE = 1'b0;

    // T3+: Wait for HREADYOUT=1 (synchronous polling at each clock edge)
    // A real master checks HREADYOUT at every posedge.
    // We do the same here.
    while (!done) begin
        @(posedge HCLK);
        #1;                // let NBA settle
        if (HREADYOUT)
            done = 1;
    end

    $display("WRITE DONE: ADDR=%h  DATA=%h", addr, data);
end
endtask

//------------------------------------------------------------
// ahb_read
//------------------------------------------------------------
// Correct AHB-Lite read sequence:
//
//  Clk:  __|‾|__|‾|__|‾|__|‾|__|‾|__
//          T1   T2   T3..  Tn
//
//  T1: Drive HADDR, HWRITE=0, HTRANS=NONSEQ  (address phase)
//  T2: HTRANS=IDLE
//  T3..Tn: Poll HREADYOUT
//          When HREADYOUT=1, HRDATA is valid — sample it NOW
//
// KEY POINT: HRDATA (= hrdata_reg) is valid at the SAME posedge
// where HREADYOUT=1, because both are registered outputs of the FSM.
// We read HRDATA immediately after the #1 settle at that posedge.
//------------------------------------------------------------
task ahb_read;
    input [31:0] addr;
    integer done;
begin
    done = 0;

    // T1: Address phase
    @(posedge HCLK);
    #1;
    HADDR  = addr;
    HWRITE = 1'b0;
    HTRANS = 2'b10;
    HREADY = 1'b1;

    // T2: Go idle
    @(posedge HCLK);
    #1;
    HTRANS = 2'b00;

    // T3+: Synchronous polling — sample HREADYOUT at each posedge
    while (!done) begin
        @(posedge HCLK);
        #1;                // let NBA settle
        if (HREADYOUT) begin
            done = 1;
            // HRDATA is valid right now — hrdata_reg was loaded
            // at the ACCESS posedge and is stable
            $display("READ  DONE: ADDR=%h  DATA=%h", addr, HRDATA);
        end
    end
end
endtask

//------------------------------------------------------------
// Main test
//------------------------------------------------------------
initial begin
    reset_dut;

    ahb_write(32'h0000_0000, 32'hAABBCCDD);
    ahb_write(32'h0000_0004, 32'h11223344);
    ahb_write(32'h0000_0008, 32'hDEADBEEF);

    repeat(2) @(posedge HCLK);

    ahb_read(32'h0000_0000);
    ahb_read(32'h0000_0004);
    ahb_read(32'h0000_0008);

    repeat(5) @(posedge HCLK);
    $finish;
end

initial begin
    $dumpfile("bridge.vcd");
    $dumpvars(0, tb_ahb_apb_bridge);
end

endmodule