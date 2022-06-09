library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram2cordic_tb is
    generic(
        COORD_W: natural := 13;
        DATA_W: natural := 16;
		ADDR_W: natural := 18
    );
end sram2cordic_tb;

architecture sram2cordic_tb_arch of sram2cordic_tb is 

--    constant BIT_W : time := 20 ns * DVSR_BIT_UART * 16; 

    --señales de prueba --------------------------------------
    signal clk_tb, rst_tb, ena_tb: std_logic := '0';
    signal count_tb: std_logic_vector(3 downto 0);
    -- Dual port RAM ----------------------------
    signal wr_dpr_tick_tb: std_logic;
    signal x_coord_tb: std_logic_vector(COORD_W-1 downto 0);
    signal y_coord_tb: std_logic_vector(COORD_W-1 downto 0);
    signal z_coord_tb: std_logic_vector(COORD_W-1 downto 0);
    -- rotador 3D -------------------------------
    signal flag_fin_tb: std_logic;
    -- SRAM --------------------------------------
    signal we_n_tb, oe_n_tb : std_logic;
    signal ad_tb: std_logic_vector(ADDR_W-1 downto 0)
                 := (others =>'0');
    signal dio_a_tb: std_logic_vector(DATA_W-1 downto 0)
                    := (others =>'0');
    signal dio_a_tb_aux: std_logic_vector(DATA_W+2 downto 0)
                    := (others =>'0');
    signal ce_a_n_tb, ub_a_n_tb, lb_a_n_tb: std_logic;

begin

   	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	rst_tb <= '1' after 17 ns, '0' after 98 ns;
	ena_tb <= '1' after 157 ns;
   
    gen_data: entity work.counter(behavioral) 
    generic map(N => DATA_W+3)
    port map(
        rst => rst_tb,
        clk => clk_tb,
        ena => '1',
        count => dio_a_tb_aux
    );
    dio_a_tb <= dio_a_tb_aux(DATA_W+2 downto 3);

    gen_tick3D: entity work.counter(behavioral)
    generic map (N => 4) --quiero contar 13 ciclos
    port map(
        rst => rst_tb,
        clk => clk_tb,
        ena => '1', -- que cuente siempre 
        count => count_tb
    );
    -- genero un tick cada 16 ciclos emulando el rotador 3D
    process(count_tb)
    begin
        if(count_tb = "1011") then
            flag_fin_tb <= '1';
        else 
            flag_fin_tb <= '0';
        end if;
    end process;    


    DUT: entity work.sram2cordic(sram2cordic_arch)
    generic map(
        COORD_W => COORD_W,
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
    )
    port map(
        clk=>clk_tb, rst=>rst_tb, ena=>ena_tb,
        -- a dual port ram
        wr_dpr_tick => wr_dpr_tick_tb,
        -- hacia/desde rotador 3d
        flag_fin => flag_fin_tb,
        x_coord => x_coord_tb,
        y_coord => y_coord_tb,
        z_coord => z_coord_tb,
        -- a SRAM externa
        we_n => we_n_tb, oe_n => oe_n_tb,
        ad => ad_tb,
        dio_a => dio_a_tb,
        ce_a_n=>ce_a_n_tb, ub_a_n=>ub_a_n_tb, lb_a_n=>lb_a_n_tb
    );

end;    

