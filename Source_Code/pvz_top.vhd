library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pvz_top is
    port (
        sys_clk, sys_rst_n : in std_logic;
        key       : in std_logic_vector(3 downto 0);
        sd_miso   : in std_logic;
        sd_clk, sd_cs, sd_mosi : out std_logic;
        lcd_bl, lcd_rst, lcd_clk, lcd_hs, lcd_vs, lcd_de : out std_logic;
        lcd_rgb   : out std_logic_vector(15 downto 0);
        beep      : out std_logic
    );
end pvz_top;

architecture bhv of pvz_top is
    component plant_plugin
        port (
            sys_clk, pixel_clk, sys_rst_n : in std_logic;
            plant_id : in std_logic_vector(2 downto 0);
            h_cnt, v_cnt, cell_x, cell_y : in std_logic_vector(10 downto 0);
            pixel_data : out std_logic_vector(15 downto 0);
            is_plant_area : out std_logic;
            z_x, z_y : in std_logic_vector(10 downto 0);
            z_active : in std_logic;
            z_pixel : out std_logic_vector(15 downto 0);
            is_zombie_area : out std_logic;
            z_is_eating : in std_logic;
            pea_x, pea_y : in std_logic_vector(10 downto 0);
            pea_active : in std_logic;
            pea_pixel : out std_logic_vector(15 downto 0);
            is_pea_area : out std_logic;
            sd_miso : in std_logic;
            sd_clk, sd_cs, sd_mosi : out std_logic
        );
    end component;

    signal p_clk : std_logic := '0';
    signal h_p, v_p : unsigned(10 downto 0) := (others => '0');
    signal is_p, is_z, is_pea : std_logic;
    signal p_rgb, z_rgb, pea_rgb : std_logic_vector(15 downto 0);
    
    type grid_map is array (0 to 4, 0 to 8) of integer range 0 to 7;
    signal plants : grid_map := (others => (others => 0));
    
    signal cur_r, cur_c : integer range 0 to 8 := 0; 
    signal hand  : integer range 0 to 7 := 0;
    signal k_d0  : std_logic_vector(3 downto 0) := "1111";

    signal tick_1s, tick_100ms : std_logic := '0';
    signal clk_cnt : unsigned(25 downto 0) := (others => '0');
    signal m_cnt : unsigned(22 downto 0) := (others => '0');
    signal score : integer range 0 to 9999 := 150;
    signal s_1000, s_100, s_10, s_1 : integer range 0 to 9 := 0;
    signal sun_slots : std_logic_vector(5 downto 0) := "000000";
    
    -- 核心计时器
    signal drop_timer   : integer range 0 to 30 := 0;
    signal flower_timer : integer range 0 to 30 := 0;
    signal z_gen_timer  : integer range 0 to 30 := 0;
    
    signal z_active : std_logic := '0';
    signal z_x_pos  : integer range 0 to 1023 := 750;
    signal z_row    : integer range 0 to 4 := 0;
    signal z_hp     : integer range 0 to 10 := 9;
    signal z_is_eating : std_logic := '0';
    signal eat_timer   : integer range 0 to 50 := 0;
    signal z_spawned   : std_logic := '0';

    signal kill_count : integer range 0 to 15 := 0;
    signal game_over, game_win : std_logic := '0';

    type pea_x_array is array (0 to 4) of integer range 0 to 1023;
    signal pea_x_arr : pea_x_array := (others => 0);
    signal pea_active_vec : std_logic_vector(4 downto 0) := (others => '0');

    signal scan_r, scan_c : integer;
    signal cell_x_sig, cell_y_sig : std_logic_vector(10 downto 0);
    signal pea_x_sig, pea_y_sig : std_logic_vector(10 downto 0);
    signal pea_active_sig : std_logic;
    signal current_id : std_logic_vector(2 downto 0);
    signal rand_cnt : integer range 0 to 6 := 0;
    
    function get_digit_pixel(d, x, y : integer) return std_logic is
        type digit_rom is array(0 to 9) of std_logic_vector(14 downto 0);
        constant rom : digit_rom := ("111101101101111", "001001001001001", "111001111100111", "111001111001111", "101101111001001", "111100111001111", "111100111101111", "111001001001001", "111101111101111", "111101111001111");
    begin
        if x < 0 or x > 2 or y < 0 or y > 4 then return '0'; end if;
        return rom(d)(14 - (y * 3 + x));
    end function;

    function get_text_pixel(mode, char_idx, x, y : integer) return std_logic is
        type char_rom is array(0 to 7) of std_logic_vector(34 downto 0);
        constant rom_defeat : char_rom := ("11110100011000110001100011000111110", "11111100001000011110100001000011111", "11111100001000011110100001000010000", "11111100001000011110100001000011111", "01110100011000111111100011000110001", "11111001000010000100001000010000100", "00100001000010000100001000000000100", "00000000000000000000000000000000000");
        constant rom_victory : char_rom := ("10001100011000101010010100010000100", "01110001000010000100001000010001110", "01110100011000010000100001000101110", "11111001000010000100001000010000100", "01110100011000110001100011000101110", "11110100011000111110100101000110001", "10001100010101000100001000010000100", "00100001000010000100001000000000100");
    begin
        if x < 0 or x > 4 or y < 0 or y > 6 then return '0'; end if;
        if mode = 0 then return rom_defeat(char_idx)(34 - (y * 5 + x));
        else return rom_victory(char_idx)(34 - (y * 5 + x)); end if;
    end function;

begin
    beep <= '1' when (game_over = '1' or game_win = '1') and m_cnt(22) = '1' else '0'; 
    lcd_bl <= '1'; lcd_rst <= '1';
    process(sys_clk) begin if rising_edge(sys_clk) then p_clk <= not p_clk; end if; end process;
    lcd_clk <= p_clk;

    process(sys_clk) begin
        if rising_edge(sys_clk) then
            if clk_cnt < 49999999 then clk_cnt <= clk_cnt + 1; tick_1s <= '0';
            else clk_cnt <= (others => '0'); tick_1s <= '1'; end if;
            if m_cnt < 4999999 then m_cnt <= m_cnt + 1; tick_100ms <= '0';
            else m_cnt <= (others => '0'); tick_100ms <= '1'; end if;
            if rand_cnt < 6 then rand_cnt <= rand_cnt + 1; else rand_cnt <= 0; end if;
        end if;
    end process;

    process(sys_clk, sys_rst_n) 
        variable tid, v_z_col, f_count : integer;
    begin
        if sys_rst_n = '0' then
            plants <= (others => (others => 0)); hand <= 0; score <= 150; sun_slots <= "000000";
            z_active <= '0'; z_x_pos <= 750; z_gen_timer <= 0; game_over <= '0'; game_win <= '0';
            kill_count <= 0; drop_timer <= 0; flower_timer <= 0; z_spawned <= '0';
            pea_active_vec <= (others => '0');
        elsif rising_edge(sys_clk) then
            if game_over = '0' and game_win = '0' then
                if tick_1s = '1' then
                    -- 1. 阳光逻辑：5s 掉落 / 20s 向日葵
                    if drop_timer < 5 then drop_timer <= drop_timer + 1;
                    else drop_timer <= 0;
                        for i in 0 to 5 loop if sun_slots(i)='0' then sun_slots(i)<='1'; exit; end if; end loop;
                    end if;
                    if flower_timer < 20 then flower_timer <= flower_timer + 1;
                    else flower_timer <= 0;
                        f_count := 0;
                        for r in 0 to 4 loop for c in 0 to 8 loop if plants(r,c)=1 then f_count := f_count + 1; end if; end loop; end loop;
                        for k in 1 to 6 loop
                            if k <= f_count then
                                for i in 0 to 5 loop if sun_slots(i)='0' then sun_slots(i)<='1'; exit; end if; end loop;
                            end if;
                        end loop;
                    end if;

                    -- 2. 僵尸生成：20s 首发 / 15s 间隔
                    if z_active = '0' then
                        if (z_spawned = '0' and z_gen_timer < 20) or (z_spawned = '1' and z_gen_timer < 15) then
                            z_gen_timer <= z_gen_timer + 1;
                        else
                            z_gen_timer <= 0; z_active <= '1'; z_x_pos <= 750; 
                            z_row <= rand_cnt mod 5; z_hp <= 9; z_spawned <= '1';
                        end if;
                    end if;

                    -- 3. 射击逻辑：每秒 1 发 (仅在有僵尸且有射手时)
                    for r in 0 to 4 loop
                        if z_active = '1' and z_row = r then
                            for c in 0 to 8 loop
                                if plants(r, c) = 2 then
                                    pea_active_vec(r) <= '1';
                                    pea_x_arr(r) <= c*88 + 60;
                                    exit;
                                end if;
                            end loop;
                        end if;
                    end loop;
                end if;

                if tick_100ms = '1' then
                    -- 4. 僵尸移动 (约 4s 一格)
                    if z_active = '1' then
                        v_z_col := (z_x_pos + 10) / 88; 
                        if v_z_col <= 8 and plants(z_row, v_z_col) /= 0 then
                            z_is_eating <= '1';
                            if eat_timer < 30 then eat_timer <= eat_timer + 1;
                            else eat_timer <= 0; plants(z_row, v_z_col) <= 0; z_is_eating <= '0'; end if;
                        else
                            z_is_eating <= '0'; eat_timer <= 0;
                            if z_x_pos > 5 then z_x_pos <= z_x_pos - 2; else game_over <= '1'; end if;
                        end if;
                    end if;
                    -- 5. 豌豆高速飞行 (保证 1s 内离开屏幕以支持 1s 连发)
                    for i in 0 to 4 loop
                        if pea_active_vec(i) = '1' then
                            if pea_x_arr(i) < 800 then 
                                pea_x_arr(i) <= pea_x_arr(i) + 80;
                                if z_active = '1' and z_row = i and pea_x_arr(i) > z_x_pos and pea_x_arr(i) < z_x_pos + 80 then
                                    pea_active_vec(i) <= '0';
                                    if z_hp > 1 then z_hp <= z_hp - 1; 
                                    else z_active <= '0'; kill_count <= kill_count + 1;
                                        if kill_count = 9 then game_win <= '1'; end if;
                                    end if;
                                end if;
                            else pea_active_vec(i) <= '0'; end if;
                        end if;
                    end loop;
                end if;

                k_d0 <= key;
                if k_d0(2)='1' and key(2)='0' then 
                    if cur_r = 0 then
                        if cur_c >= 2 and cur_c <= 7 then
                            if sun_slots(cur_c-2) = '1' then sun_slots(cur_c-2) <= '0'; if score<9975 then score <= score+25; end if; end if;
                        elsif cur_c = 0 and score >= 50 then if hand=1 then hand<=0; else hand<=1; end if;
                        elsif cur_c = 1 and score >= 100 then if hand=2 then hand<=0; else hand<=2; end if; end if;
                    elsif hand /= 0 and plants(cur_r-1, cur_c) = 0 then
                        plants(cur_r-1, cur_c) <= hand;
                        if hand = 1 then score <= score - 50; else score <= score - 100; end if;
                        hand <= 0;
                    end if;
                end if;
                if k_d0(0)='1' and key(0)='0' then if cur_c < 8 then cur_c <= cur_c + 1; else cur_c <= 0; end if; end if;
                if k_d0(1)='1' and key(1)='0' then if cur_r < 5 then cur_r <= cur_r + 1; else cur_r <= 0; end if; end if;
            end if; 
            s_1 <= score rem 10; s_10 <= (score/10) rem 10; s_100 <= (score/100) rem 10; s_1000 <= (score/1000) rem 10;
        end if;
    end process;

    scan_c <= to_integer(h_p) / 88;
    scan_r <= 0 when v_p < 80 else (to_integer(v_p) - 80) / 80 + 1;

    process(scan_r, scan_c, plants, sun_slots, pea_active_vec, pea_x_arr)
    begin
        if scan_r = 0 then
            if scan_c = 0 then current_id <= "001"; elsif scan_c = 1 then current_id <= "010";
            elsif scan_c >= 2 and scan_c <= 7 and sun_slots(scan_c-2) = '1' then current_id <= "011";
            else current_id <= "000"; end if;
            cell_y_sig <= std_logic_vector(to_unsigned(10, 11));
            pea_active_sig <= '0'; 
        elsif scan_r <= 5 and scan_c <= 8 then
            current_id <= std_logic_vector(to_unsigned(plants(scan_r-1, scan_c), 3));
            cell_y_sig <= std_logic_vector(to_unsigned((scan_r-1)*80 + 80 + 10, 11));
            pea_active_sig <= pea_active_vec(scan_r-1);
            pea_x_sig <= std_logic_vector(to_unsigned(pea_x_arr(scan_r-1), 11));
            pea_y_sig <= std_logic_vector(to_unsigned((scan_r-1)*80 + 80 + 8, 11));
        else current_id <= "000"; cell_y_sig <= (others => '0'); pea_active_sig <= '0'; end if;
        cell_x_sig <= std_logic_vector(to_unsigned(scan_c*88 + 10, 11));
    end process;

    u_p : plant_plugin port map (
        sys_clk => sys_clk, pixel_clk => p_clk, sys_rst_n => sys_rst_n,
        plant_id => current_id, h_cnt => std_logic_vector(h_p), v_cnt => std_logic_vector(v_p),
        cell_x => cell_x_sig, cell_y => cell_y_sig, pixel_data => p_rgb, is_plant_area => is_p,
        z_x => std_logic_vector(to_unsigned(z_x_pos, 11)), 
        z_y => std_logic_vector(to_unsigned(80 + z_row*80 - 25, 11)), 
        z_active => z_active, z_pixel => z_rgb, is_zombie_area => is_z,
        z_is_eating => z_is_eating,
        pea_x => pea_x_sig, pea_y => pea_y_sig, pea_active => pea_active_sig,
        pea_pixel => pea_rgb, is_pea_area => is_pea,
        sd_miso => sd_miso, sd_clk => sd_clk, sd_cs => sd_cs, sd_mosi => sd_mosi
    );

    process(p_clk)
        variable dv, dx, dy, mode : integer; variable idig, itxt : std_logic;
        variable frgb : std_logic_vector(15 downto 0);
    begin
        if rising_edge(p_clk) then
            idig := '0'; itxt := '0';
            if scan_r = 0 and scan_c = 8 then
                dx := (to_integer(h_p) mod 88 - 2); dy := (to_integer(v_p) - 20);
                if dy >= 0 and dy < 40 and dx >= 0 and dx < 83 then
                    if dx < 20 then dv := s_1000; elsif dx < 41 then dv := s_100; elsif dx < 62 then dv := s_10; else dv := s_1; end if;
                    idig := get_digit_pixel(dv, (dx mod 21)/6, dy/7);
                end if;
            end if;

            if h_p < 800 and v_p < 480 then
                if idig = '1' then frgb := (others => '1');
                elsif is_pea = '1' then frgb := pea_rgb; 
                elsif is_z = '1' then frgb := z_rgb; 
                elsif is_p = '1' then frgb := p_rgb;
                elsif (scan_c = cur_c and scan_r = cur_r) then
                    if (to_integer(h_p) mod 88 < 4 or to_integer(h_p) mod 88 > 84) then
                        if hand /= 0 then frgb := "1111100000000000"; else frgb := "1111111111100000"; end if;
                    else frgb := "0000001111100000"; end if;
                else frgb := "0000001111100000"; end if;
                
                if game_over = '1' or game_win = '1' then
                    if game_win = '1' then mode := 1; dx := to_integer(h_p)-208; dy := to_integer(v_p)-212;
                    else mode := 0; dx := to_integer(h_p)-232; dy := to_integer(v_p)-212; end if;
                    
                    if dy >= 0 and dy < 56 and dx >= 0 and dx < 384 then
                        itxt := get_text_pixel(mode, dx/48, (dx mod 48)/8, dy/8);
                    end if;

                    if itxt = '1' then lcd_rgb <= (others => '1');
                    elsif h_p > 180 and h_p < 620 and v_p > 180 and v_p < 300 then
                        if game_win = '1' then lcd_rgb <= "1111111111100000"; else lcd_rgb <= "1000000000000000"; end if;
                    else lcd_rgb <= frgb(15 downto 14) & "00000000000000"; end if;
                else lcd_rgb <= frgb; end if;
            else lcd_rgb <= (others => '0'); end if;

            if h_p < 1055 then h_p <= h_p + 1; else h_p <= (others => '0');
                if v_p < 524 then v_p <= v_p + 1; else v_p <= (others => '0'); end if;
            end if;
        end if;
    end process;
    lcd_de <= '1' when h_p < 800 and v_p < 480 else '0'; lcd_hs <= '1'; lcd_vs <= '1';
end bhv;
