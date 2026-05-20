//////////////////////////////
// bridge_fsm.v  (FIXED)
//////////////////////////////
// 
// WHY we add WDATA_WAIT state:
//   For writes: valid_req fires when address is captured.
//               But HWDATA arrives ONE cycle later.
//               We must wait one cycle before going to SETUP.
//
// WHY we add prdata_reg:
//   PRDATA from APB slave is combinational.
//   The moment PSEL/PENABLE drop, PRDATA goes to 0.
//   We MUST register PRDATA at the moment PREADY fires,
//   before APB signals drop.
//
// WHY HREADYOUT goes high in ACCESS (not DONE):
//   The AHB master samples HRDATA when HREADYOUT=1.
//   If we wait for DONE state to raise HREADYOUT, 
//   we've already killed PSEL/PENABLE and PRDATA is 0.
//   We must raise HREADYOUT and capture PRDATA simultaneously
//   in the ACCESS state when PREADY=1.

module bridge_fsm (

    input             HCLK,
    input             HRESETn,

    input             valid_req,
    input             write_reg,      // 1=write, 0=read — needed to steer FSM
    input             PREADY,
    input      [31:0] PRDATA,         // we register this here

    output reg [2:0]  state,
    output reg        HREADYOUT,
    output reg        HRESP,
    output reg [31:0] hrdata_reg      // registered read data for AHB master

);

// FSM states
parameter IDLE         = 3'b000;
parameter WDATA_WAIT   = 3'b001;  // NEW: wait one cycle for HWDATA to arrive
parameter SETUP        = 3'b010;  // APB SETUP phase: PSEL=1, PENABLE=0
parameter ACCESS       = 3'b011;  // APB ACCESS phase: PSEL=1, PENABLE=1
parameter DONE         = 3'b100;  // APB complete, release AHB

always @(posedge HCLK or negedge HRESETn)
begin
    if (!HRESETn) begin
        state       <= IDLE;
        HREADYOUT   <= 1'b1;
        HRESP       <= 1'b0;
        hrdata_reg  <= 32'd0;
    end
    else begin
        case (state)

            // -----------------------------------------------
            IDLE:
            // -----------------------------------------------
            // Bus is idle. HREADYOUT=1 so master can transact.
            // When valid_req fires, address is captured.
            // We must stall the AHB master (HREADYOUT=0) because
            // the APB transaction takes multiple cycles.
            begin
                HREADYOUT <= 1'b1;
                HRESP     <= 1'b0;

                if (valid_req) begin
                    HREADYOUT <= 1'b0;  // stall AHB master immediately
                    
                    if (write_reg) begin
                        // Write: HWDATA not ready yet, wait one cycle
                        state <= WDATA_WAIT;
                    end
                    else begin
                        // Read: no HWDATA needed, go straight to APB SETUP
                        state <= SETUP;
                    end
                end
            end

            // -----------------------------------------------
            WDATA_WAIT:
            // -----------------------------------------------
            // We arrive here one cycle after address phase for writes.
            // By now, HWDATA has been captured into wdata_reg
            // in ahb_slave_if. Safe to proceed to APB SETUP.
            begin
                state <= SETUP;
            end

            // -----------------------------------------------
            SETUP:
            // -----------------------------------------------
            // APB SETUP phase:
            //   PSEL=1, PENABLE=0
            //   Slave sees address, prepares for transfer.
            //   We always proceed to ACCESS next cycle.
            //   (PENABLE goes high in ACCESS)
            begin
                state <= ACCESS;
            end

            // -----------------------------------------------
            ACCESS:
            // -----------------------------------------------
            // APB ACCESS phase:
            //   PSEL=1, PENABLE=1
            //   Slave completes the transfer.
            //   PREADY=1 means slave is done.
            //
            // CRITICAL for reads:
            //   PRDATA is valid RIGHT NOW (PSEL=1, PENABLE=1, PREADY=1).
            //   We must register it NOW, before we leave ACCESS.
            //   The moment PENABLE drops (in DONE/IDLE), PRDATA→0.
            //
            // CRITICAL for HREADYOUT:
            //   We release HREADYOUT=1 here so AHB master can
            //   sample HRDATA in this same cycle (or next, see DONE).
            begin
                if (PREADY) begin
                    hrdata_reg <= PRDATA;    // capture read data NOW
                    state      <= DONE;
                end
                // else stay in ACCESS (slave is inserting wait states)
            end

            // -----------------------------------------------
            DONE:
            // -----------------------------------------------
            // APB transaction complete.
            // HREADYOUT goes high here.
            // AHB master samples HRDATA = hrdata_reg.
            // hrdata_reg still holds the captured PRDATA safely.
            // APB signals drop (PSEL=0) but we don't care —
            // we're serving HRDATA from the register.
            begin
                HREADYOUT <= 1'b1;
                state     <= IDLE;
            end

        endcase
    end
end

endmodule