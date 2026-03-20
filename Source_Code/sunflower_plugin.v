`include "assets_map.v"

module plant_plugin(
    input  wire        sys_clk, pixel_clk, sys_rst_n,
    input  wire [2:0]  plant_id,   
    input  wire [10:0] h_cnt, v_cnt, cell_x, cell_y,
    output wire [15:0] pixel_data,
    output wire        is_plant_area,
    input  wire [10:0] z_x, z_y,
    input  wire        z_active,
    output wire [15:0] z_pixel,
    output wire        is_zombie_area,
    input  wire        z_is_eating,
    input  wire [10:0] pea_x, pea_y,
    input  wire        pea_active,
    output wire [15:0] pea_pixel,
    output wire        is_pea_area,
    input  wire        sd_miso,
    output wire        sd_clk, sd_cs, sd_mosi
);

    localparam SEC_SUNFLOWER  = `ADDR_SUNFLOWER  / 512; 
    localparam SEC_SUN        = `ADDR_SUN        / 512;
    localparam SEC_PEASHOOTER = `ADDR_PEASHOOTER / 512; 
    localparam SEC_ZOMBIE     = `ADDR_ZOMBIE     / 512;
    localparam SEC_PEA        = `ADDR_PEA        / 512;

    reg [31:0] rd_addr; reg [7:0] sec_cnt; reg rd_start;
    wire rd_busy, rd_val, sd_init; wire [15:0] rd_data;
    reg [3:0] load_state; reg [12:0] wa;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin load_state <= 0; sec_cnt <= 0; rd_start <= 0; wa <= 0; end
        else if (sd_init) begin
            case (load_state)
                4'd0: begin sec_cnt <= 0; wa <= 0; load_state <= 4'd1; end
                4'd1: begin rd_addr <= SEC_SUNFLOWER + sec_cnt; rd_start <= 1'b1; load_state <= 4'd2; end
                4'd2: begin rd_start <= 1'b0; if (rd_busy) load_state <= 4'd3; end
                4'd3: begin if (!rd_busy) begin if (sec_cnt < 15) begin sec_cnt <= sec_cnt + 1; load_state <= 4'd1; end else begin sec_cnt <= 0; wa <= 3960; load_state <= 4'd4; end end end
                4'd4: begin rd_addr <= SEC_SUN + sec_cnt; rd_start <= 1'b1; load_state <= 4'd5; end
                4'd5: begin rd_start <= 1'b0; if (rd_busy) load_state <= 4'd6; end
                4'd6: begin if (!rd_busy) begin if (sec_cnt < 4) begin sec_cnt <= sec_cnt + 1; load_state <= 4'd4; end else begin sec_cnt <= 0; wa <= 5210; load_state <= 4'd7; end end end
                4'd7: begin rd_addr <= SEC_PEASHOOTER + sec_cnt; rd_start <= 1'b1; load_state <= 4'd8; end
                4'd8: begin rd_start <= 1'b0; if (rd_busy) load_state <= 4'd9; end
                4'd9: begin if (!rd_busy) begin if (sec_cnt < 10) begin sec_cnt <= sec_cnt + 1; load_state <= 4'd7; end else begin sec_cnt <= 0; wa <= 0; load_state <= 4'd10; end end end
                4'd10: begin rd_addr <= SEC_ZOMBIE + sec_cnt; rd_start <= 1'b1; load_state <= 4'd11; end
                4'd11: begin rd_start <= 1'b0; if (rd_busy) load_state <= 4'd12; end
                4'd12: begin if (!rd_busy) begin if (sec_cnt < 25) begin sec_cnt <= sec_cnt + 1; load_state <= 4'd10; end else begin sec_cnt <= 0; wa <= 6656; load_state <= 4'd13; end end end    
                4'd13: begin rd_addr <= SEC_PEA + sec_cnt; rd_start <= 1'b1; load_state <= 4'd14; end
                4'd14: begin rd_start <= 1'b0; if (rd_busy) load_state <= 4'd15; end
                4'd15: begin if (!rd_busy) begin if (sec_cnt < 5) begin sec_cnt <= sec_cnt + 1; load_state <= 4'd13; end else load_state <= 4'd16; end end
                default: load_state <= 4'd16;
            endcase
            if (rd_val) wa <= wa + 1'b1;
        end
    end

    reg [23:0] anim_cnt; 
    reg [21:0] pea_anim_cnt; 
    reg [1:0] f_z, f_sun, f_pea, f_flower, f_pea_move; 
    always @(posedge pixel_clk) begin
        if (anim_cnt < 24'd4_000_000) anim_cnt <= anim_cnt + 1;
        else begin 
            anim_cnt <= 0; f_flower <= f_flower + 1'b1; f_sun <= f_sun + 1'b1; 
            f_pea <= (f_pea < 2'd2) ? f_pea + 1'b1 : 2'd0; 
            if (!z_is_eating) f_z <= (f_z < 2'd2) ? f_z + 1'b1 : 2'd0; 
        end
        if (pea_anim_cnt < 22'd2_000_000) pea_anim_cnt <= pea_anim_cnt + 1;
        else begin
            pea_anim_cnt <= 0;
            f_pea_move <= (f_pea_move < 2'd2) ? f_pea_move + 1'b1 : 2'd0;
        end
    end

    wire [10:0] dx_p = (h_cnt >= cell_x) ? (h_cnt - cell_x) : 11'd2047;
    wire [10:0] dy_p = (v_cnt >= cell_y) ? (v_cnt - cell_y) : 11'd2047;
    wire [10:0] dx_z = (h_cnt >= z_x) ? (h_cnt - z_x) : 11'd2047;
    wire [10:0] dy_z = (v_cnt >= z_y) ? (v_cnt - z_y) : 11'd2047;
    wire [10:0] dx_pea = (h_cnt >= pea_x) ? (h_cnt - pea_x) : 11'd2047;
    wire [10:0] dy_pea = (v_cnt >= pea_y) ? (v_cnt - pea_y) : 11'd2047;

    wire [10:0] sx_p = dx_p >> 1; wire [10:0] sy_p = dy_p >> 1;
    wire [10:0] sx_z = dx_z >> 1; wire [10:0] sy_z = dy_z >> 1;
    wire [10:0] sx_pea = dx_pea;  wire [10:0] sy_pea = dy_pea;

    wire [12:0] ra_p = (plant_id == 3'd2) ? (13'd5210 + f_pea*896 + (sy_p < 32 ? sy_p[4:0] : 5'd31)*28 + (sx_p < 28 ? sx_p[4:0] : 5'd27)) :
                       (plant_id == 3'd3) ? (13'd3960 + (f_sun[0])*625 + (sy_p < 25 ? sy_p[4:0] : 5'd24)*25 + (sx_p < 25 ? sx_p[4:0] : 5'd24)) :
                       (f_flower*990 + (sy_p < 33 ? sy_p[5:0] : 6'd32)*30 + (sx_p < 30 ? sx_p[4:0] : 5'd29));
    
    reg [12:0] ra_z_comb;
    always @(*) begin
        if (pea_active && sx_pea < 12 && sy_pea < 32)
            ra_z_comb = 13'd6656 + f_pea_move*384 + sy_pea[4:0]*12 + sx_pea[3:0];
        else
            ra_z_comb = f_z*2214 + (sy_z < 54 ? sy_z[5:0] : 6'd53)*41 + (sx_z < 41 ? sx_z[5:0] : 6'd40);
    end

    wire [15:0] q_p, q_z;
    plant_ram u_ram_p (.wrclock(sys_clk), .wren(rd_val && load_state <= 9), .wraddress(wa), .data({rd_data[7:0], rd_data[15:8]}), .rdclock(pixel_clk), .rdaddress(ra_p), .q(q_p));
    zombie_ram u_ram_z (.wrclock(sys_clk), .wren(rd_val && load_state >= 10 && load_state <= 15), .wraddress(wa), .data({rd_data[7:0], rd_data[15:8]}), .rdclock(pixel_clk), .rdaddress(ra_z_comb), .q(q_z));

    wire tr_p = (q_p == 16'hF81F);
    wire tr_z = (q_z == 16'hF81F);

    reg in_p_reg, in_z_reg, in_pea_reg;
    reg is_p_out, is_z_out, is_pea_out;
    reg [15:0] p_px_out, z_px_out, pea_px_out;

    always @(posedge pixel_clk) begin
        in_p_reg <= (plant_id != 0) && (sx_p < 30 && sy_p < 33);
        in_pea_reg <= pea_active && (sx_pea < 12 && sy_pea < 32);
        in_z_reg <= z_active && (sx_z < 41 && sy_z < 54);
        
        is_p_out <= in_p_reg && !tr_p;
        is_pea_out <= in_pea_reg && !tr_z; 
        is_z_out <= in_z_reg && !tr_z && !in_pea_reg;
        
        p_px_out <= q_p;
        z_px_out <= q_z;
        pea_px_out <= q_z;
    end

    assign is_plant_area = is_p_out;
    assign is_zombie_area = is_z_out;
    assign is_pea_area = is_pea_out;
    assign pixel_data = p_px_out; 
    assign z_pixel = z_px_out;
    assign pea_pixel = pea_px_out;

    sd_ctrl_top u_sd(.clk_ref(sys_clk), .clk_ref_180deg(~sys_clk), .rst_n(sys_rst_n), .sd_miso(sd_miso), .sd_clk(sd_clk), .sd_cs(sd_cs), .sd_mosi(sd_mosi), .rd_start_en(rd_start), .rd_sec_addr(rd_addr), .rd_busy(rd_busy), .rd_val_en(rd_val), .rd_val_data(rd_data), .sd_init_done(sd_init));

endmodule
