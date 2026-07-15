// generic Yosys gate library 實驗使用的最小面積 synthesis top。刻意關閉部分可選安全／效能功能，
// 並只暴露 Native Memory Interface；它是量測 boundary，不是完整 SoC。
module top (
	input clk, resetn,

	output        mem_valid,
	output        mem_instr,
	input         mem_ready,

	output [31:0] mem_addr,
	output [31:0] mem_wdata,
	output [ 3:0] mem_wstrb,
	input  [31:0] mem_rdata
);
	picorv32 #(
		.ENABLE_COUNTERS(0),
		.LATCHED_MEM_RDATA(1),
		.TWO_STAGE_SHIFT(0),
		.CATCH_MISALIGN(0),
		.CATCH_ILLINSN(0)
	) picorv32 (
		.clk      (clk      ),
		.resetn   (resetn   ),
		.mem_valid(mem_valid),
		.mem_instr(mem_instr),
		.mem_ready(mem_ready),
		.mem_addr (mem_addr ),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata)
	);
endmodule
