library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gral_ctrl_tb is
    generic(
        COORD_W: natural := 13;
        DATA_W: natural := 16;
		ADDR_W: natural := 23
    );
end gral_ctrl_tb;

architecture gral_ctrl_tb_arch of gral_ctrl_tb is 

--    constant BIT_W : time := 20 ns * DVSR_BIT_UART * 16; 

    --señales de prueba --------------------------------------
    constant EOF_WORD : std_logic_vector(DATA_W-1 downto 0) 
                      :="1111111111111111";
    constant DATA_MATCH : std_logic_vector(DATA_W-1 downto 0)
                        := std_logic_vector(to_unsigned(138,DATA_W));
    signal clk_tb, rst_tb, ena_tb: std_logic := '0';
    signal count_tb: std_logic_vector(4 downto 0);
    -- Dual port RAM ----------------------------
    signal wr_dpr_tick_tb: std_logic;
    signal x_coord_tb: std_logic_vector(COORD_W-1 downto 0);
    signal y_coord_tb: std_logic_vector(COORD_W-1 downto 0);
    signal z_coord_tb: std_logic_vector(COORD_W-1 downto 0);
    -- rotador 3D -------------------------------
    signal flag_fin_tb: std_logic;
    -- gral_ctrl -------------------------------------------
    signal rx_uart_empty_tb: std_logic:= '1';
    -- uart2sram -------------------------------------------
    signal ena_uart2sram_tb: std_logic:= '0';
    signal mem_uart_tb: std_logic:= '0';
    signal addr_tick_uart_tb: std_logic:= '0';
    -- sram2cordic -----------------------------------------
    signal ena_sram2cordic_tb: std_logic:= '0';
    signal mem_cordic_tb: std_logic:= '0';
    signal addr_tick_cordic_tb: std_logic:= '0';
    -- sram_ctrl ------------------------------------------
                --       lado fpga         --
    signal addr_sram_tb: std_logic_vector(ADDR_W-1 downto 0)
                  := (others => '0');
    signal data_f2s_tb: std_logic_vector(DATA_W-1 downto 0)
                      := (others => '0');
    signal data_s2f_r_tb: std_logic_vector(DATA_W-1 downto 0)
                        := (others => '0');
    signal data_s2f_ur_tb: std_logic_vector(DATA_W-1 downto 0)
                         := (others => '0');
    signal mem_tb, rw_tb, ready_tb: std_logic := '0';
               --        lado SRAM         --    
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

--##################################################
    -- ::  Contador para generar datos   ::        #
    -----------------------------------------------#
    gen_data: entity work.counter                --#
    generic map(N => DATA_W+3)                   --#
    port map(                                    --#
        rst => rst_tb,                           --#
        rst_sync => '0',                         --#
        clk => clk_tb,                           --#
        ena => '1',                              --#
        count => dio_a_tb_aux                    --#
    );                                           --#
    dio_a_tb <= EOF_WORD when dio_a_tb_aux(DATA_W+2 downto 3) = DATA_MATCH else
                dio_a_tb_aux(DATA_W+2 downto 3); --#
                                                 --#
--##################################################

--###########################################################
    -- ::  Contador para emular fin del  rotador 3D  ::     #
    --------------------------------------------------------#
    gen_tick3D: entity work.counter(behavioral)           --#
    generic map (N => 5) --quiero contar 32 ciclos        --#
    port map(                                             --#
        rst => rst_tb,                                    --#
        clk => clk_tb,                                    --#
        rst_sync => '0',                                  --#
        ena => '1', -- que cuente siempre                 --#
        count => count_tb                                 --#
    );                                                    --#
    -- genero un tick cada 32 ciclos emulando el rotador 3D #
    process(count_tb)                                     --# 
    begin                                                 --#
        if(count_tb = "10001") then                       --#
            flag_fin_tb <= '1';                           --#
        else                                              --#
            flag_fin_tb <= '0';                           --#
        end if;                                           --#
    end process;                                          --#
                                                          --#
--###########################################################

    sram_ctrl_inst: entity work.sram_ctrl
    generic map(
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
    )
    port map(
        clk => clk_tb, reset => rst_tb,
        -- to/from main system
        mem         => mem_tb,
        rw          => rw_tb,
        addr        => addr_sram_tb,
        data_f2s    => data_f2s_tb,
        ready       => ready_tb,
        data_s2f_r  => data_s2f_r_tb,
        data_s2f_ur => data_s2f_ur_tb,
        ce_in_n     => '0',
        lb_in_n     => '0',
        ub_in_n     => '0',
        -- to/from chip
        ad      => ad_tb,          
        we_n    => we_n_tb,
        oe_n    => oe_n_tb,
        -- SRAM chip a
        dio_a   => dio_a_tb,
        ce_a_n  => ce_a_n_tb,
        ub_a_n  => ub_a_n_tb,
        lb_a_n  => lb_a_n_tb 
    );


    DUT2: entity work.sram2cordic
    generic map(
        COORD_W => COORD_W,
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
    )
    port map(
        clk=>clk_tb, rst=>rst_tb,
        ena=>ena_sram2cordic_tb,
        -- a dual port ram
        wr_dpr_tick => wr_dpr_tick_tb,
        -- hacia/desde rotador 3d
        flag_fin => flag_fin_tb,
        x_coord => x_coord_tb,
        y_coord => y_coord_tb,
        z_coord => z_coord_tb,
        -- a sram_ctrl
        data_in => data_s2f_r_tb,
        mem => mem_cordic_tb,
        ready => ready_tb,
        ena_count_tick => addr_tick_cordic_tb 
    );

    
    DUT3: entity work.gral_ctrl
    generic map(
        COORD_W => COORD_W,
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
     )
    port map(
        clk => clk_tb, rst => rst_tb, ena => ena_tb,
        -- a sram2cordic
        ena_sram2cordic => ena_sram2cordic_tb,
        addr_tick_cordic => addr_tick_cordic_tb,
        mem_cordic => mem_cordic_tb,
        -- a uart2sram
        ena_uart2sram => ena_uart2sram_tb,
        rx_uart_empty => rx_uart_empty_tb,
        addr_tick_uart => addr_tick_uart_tb,
        mem_uart => mem_uart_tb,
        -- a sram_ctrl
        data_f2s => data_f2s_tb,
        data_s2f_r => data_s2f_r_tb,
        addr_sram => addr_sram_tb,
        mem => mem_tb,
        rw => rw_tb
    );

end gral_ctrl_tb_arch;    

