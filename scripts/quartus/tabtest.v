
// Timing analysis wrapper：在每個外部 AXI/IRQ pin 與 core 之間插入四級 register。
// 額外 latency 用來隔離 I/O timing；此拓撲供工具量測，不是可正常執行的 AXI system。
module top (
	input clk, io_resetn,
	output io_trap,

	output        io_mem_axi_awvalid,
	input         io_mem_axi_awready,
	output [31:0] io_mem_axi_awaddr,
	output [ 2:0] io_mem_axi_awprot,

	output        io_mem_axi_wvalid,
	input         io_mem_axi_wready,
	output [31:0] io_mem_axi_wdata,
	output [ 3:0] io_mem_axi_wstrb,

	input         io_mem_axi_bvalid,
	output        io_mem_axi_bready,

	output        io_mem_axi_arvalid,
	input         io_mem_axi_arready,
	output [31:0] io_mem_axi_araddr,
	output [ 2:0] io_mem_axi_arprot,

	input         io_mem_axi_rvalid,
	output        io_mem_axi_rready,
	input  [31:0] io_mem_axi_rdata,

	input  [31:0] io_irq,
	output [31:0] io_eoi
);
	wire resetn;
	wire trap;
	wire mem_axi_awvalid;
	wire mem_axi_awready;
	wire [31:0] mem_axi_awaddr;
	wire [2:0] mem_axi_awprot;
	wire mem_axi_wvalid;
	wire mem_axi_wready;
	wire [31:0] mem_axi_wdata;
	wire [3:0] mem_axi_wstrb;
	wire mem_axi_bvalid;
	wire mem_axi_bready;
	wire mem_axi_arvalid;
	wire mem_axi_arready;
	wire [31:0] mem_axi_araddr;
	wire [2:0] mem_axi_arprot;
	wire mem_axi_rvalid;
	wire mem_axi_rready;
	wire [31:0] mem_axi_rdata;
	wire [31:0] irq;
	wire [31:0] eoi;

	delay4 #( 1) delay_resetn          (clk, io_resetn         ,    resetn         );
	delay4 #( 1) delay_trap            (clk,    trap           , io_trap           );
	delay4 #( 1) delay_mem_axi_awvalid (clk,    mem_axi_awvalid, io_mem_axi_awvalid);
	delay4 #( 1) delay_mem_axi_awready (clk, io_mem_axi_awready,    mem_axi_awready);
	delay4 #(32) delay_mem_axi_awaddr  (clk,    mem_axi_awaddr , io_mem_axi_awaddr );
	delay4 #( 3) delay_mem_axi_awprot  (clk,    mem_axi_awprot , io_mem_axi_awprot );
	delay4 #( 1) delay_mem_axi_wvalid  (clk,    mem_axi_wvalid , io_mem_axi_wvalid );
	delay4 #( 1) delay_mem_axi_wready  (clk, io_mem_axi_wready ,    mem_axi_wready );
	delay4 #(32) delay_mem_axi_wdata   (clk,    mem_axi_wdata  , io_mem_axi_wdata  );
	delay4 #( 4) delay_mem_axi_wstrb   (clk,    mem_axi_wstrb  , io_mem_axi_wstrb  );
	delay4 #( 1) delay_mem_axi_bvalid  (clk, io_mem_axi_bvalid ,    mem_axi_bvalid );
	delay4 #( 1) delay_mem_axi_bready  (clk,    mem_axi_bready , io_mem_axi_bready );
	delay4 #( 1) delay_mem_axi_arvalid (clk,    mem_axi_arvalid, io_mem_axi_arvalid);
	delay4 #( 1) delay_mem_axi_arready (clk, io_mem_axi_arready,    mem_axi_arready);
	delay4 #(32) delay_mem_axi_araddr  (clk,    mem_axi_araddr , io_mem_axi_araddr );
	delay4 #( 3) delay_mem_axi_arprot  (clk,    mem_axi_arprot , io_mem_axi_arprot );
	delay4 #( 1) delay_mem_axi_rvalid  (clk, io_mem_axi_rvalid ,    mem_axi_rvalid );
	delay4 #( 1) delay_mem_axi_rready  (clk,    mem_axi_rready , io_mem_axi_rready );
	delay4 #(32) delay_mem_axi_rdata   (clk, io_mem_axi_rdata  ,    mem_axi_rdata  );
	delay4 #(32) delay_irq             (clk, io_irq            ,    irq            );
	delay4 #(32) delay_eoi             (clk,    eoi            , io_eoi            );

	picorv32_axi #(
		.TWO_CYCLE_ALU(1)
	) cpu (
		.clk            (clk            ),
		.resetn         (resetn         ),
		.trap           (trap           ),
		.mem_axi_awvalid(mem_axi_awvalid),
		.mem_axi_awready(mem_axi_awready),
		.mem_axi_awaddr (mem_axi_awaddr ),
		.mem_axi_awprot (mem_axi_awprot ),
		.mem_axi_wvalid (mem_axi_wvalid ),
		.mem_axi_wready (mem_axi_wready ),
		.mem_axi_wdata  (mem_axi_wdata  ),
		.mem_axi_wstrb  (mem_axi_wstrb  ),
		.mem_axi_bvalid (mem_axi_bvalid ),
		.mem_axi_bready (mem_axi_bready ),
		.mem_axi_arvalid(mem_axi_arvalid),
		.mem_axi_arready(mem_axi_arready),
		.mem_axi_araddr (mem_axi_araddr ),
		.mem_axi_arprot (mem_axi_arprot ),
		.mem_axi_rvalid (mem_axi_rvalid ),
		.mem_axi_rready (mem_axi_rready ),
		.mem_axi_rdata  (mem_axi_rdata  ),
		.irq            (irq            ),
		.eoi            (eoi            )
	);
endmodule

// 每個 tabtest 訊號共用的可參數化四級 pipeline。此模組刻意沒有 reset，
// 因此前四拍 pipeline 尚未填滿時，外部驗證必須忽略輸出。
module delay4 #(
	parameter WIDTH = 1
) (
	input clk,
	input [WIDTH-1:0] in,
	output reg [WIDTH-1:0] out
);
	reg [WIDTH-1:0] q1, q2, q3;
	always @(posedge clk) begin
		q1 <= in;
		q2 <= q1;
		q3 <= q2;
		out <= q3;
	end
endmodule

