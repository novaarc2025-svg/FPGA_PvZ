// 植物专用显存 (16个M9K, 8192深度)
module plant_ram (
    input  wire [15:0] data,
    input  wire [12:0] wraddress,
    input  wire        wrclock,
    input  wire        wren,
    input  wire [12:0] rdaddress,
    input  wire        rdclock,
    output reg  [15:0] q
);
    reg [15:0] mem [0:8191];
    always @(posedge wrclock) if (wren) mem[wraddress] <= data;
    always @(posedge rdclock) q <= mem[rdaddress];
endmodule

// 僵尸专用显存 (16个M9K, 8192深度)
module zombie_ram (
    input  wire [15:0] data,
    input  wire [12:0] wraddress,
    input  wire        wrclock,
    input  wire        wren,
    input  wire [12:0] rdaddress,
    input  wire        rdclock,
    output reg  [15:0] q
);
    reg [15:0] mem [0:8191];
    always @(posedge wrclock) if (wren) mem[wraddress] <= data;
    always @(posedge rdclock) q <= mem[rdaddress];
endmodule
