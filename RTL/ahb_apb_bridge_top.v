module ahb_apb_bridge_top (
    input               HCLK,
    input               HRESETn,
    input      [31:0]   HADDR,
    input      [31:0]   HWDATA,
    input               HWRITE,
    input      [1:0]    HTRANS,
    input               HREADY,
    output     [31:0]   HRDATA,
    output              HREADYOUT,
    output              HRESP
);

wire [31:0] addr_reg;
wire [31:0] wdata_reg;
wire        write_reg;
wire        valid_req;
wire [2:0]  state;
wire [31:0] PADDR;
wire [31:0] PWDATA;
wire        PWRITE;
wire        PSEL;
wire        PENABLE;
wire [31:0] PRDATA;
wire        PREADY;
wire [31:0] hrdata_reg;
wire        bridge_busy;    // NEW

ahb_slave_if u_ahb_slave_if (
    .HCLK        (HCLK),
    .HRESETn     (HRESETn),
    .HADDR       (HADDR),
    .HWDATA      (HWDATA),
    .HWRITE      (HWRITE),
    .HTRANS      (HTRANS),
    .HREADY      (HREADY),
    .bridge_busy (bridge_busy),    // NEW
    .addr_reg    (addr_reg),
    .wdata_reg   (wdata_reg),
    .write_reg   (write_reg),
    .valid_req   (valid_req)
);

bridge_fsm u_bridge_fsm (
    .HCLK        (HCLK),
    .HRESETn     (HRESETn),
    .valid_req   (valid_req),
    .write_reg   (write_reg),
    .PREADY      (PREADY),
    .PRDATA      (PRDATA),
    .state       (state),
    .HREADYOUT   (HREADYOUT),
    .HRESP       (HRESP),
    .hrdata_reg  (hrdata_reg),
    .bridge_busy (bridge_busy)     // NEW
);

apb_controller u_apb_controller (
    .addr_reg  (addr_reg),
    .wdata_reg (wdata_reg),
    .write_reg (write_reg),
    .state     (state),
    .PADDR     (PADDR),
    .PWDATA    (PWDATA),
    .PWRITE    (PWRITE),
    .PSEL      (PSEL),
    .PENABLE   (PENABLE)
);

apb_slave_mem u_apb_slave_mem (
    .PCLK    (HCLK),
    .PRESETn (HRESETn),
    .PADDR   (PADDR),
    .PWDATA  (PWDATA),
    .PWRITE  (PWRITE),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PRDATA  (PRDATA),
    .PREADY  (PREADY)
);

assign HRDATA = hrdata_reg;

endmodule
