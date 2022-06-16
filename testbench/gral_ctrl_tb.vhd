library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gral_ctrl_tb is
	generic(COORD_W: integer:= 13;  --long coordenadas x, y, z.
			ANG_W: integer:= 15;    --long angulos de rotacion
			ADDR_DP_W: integer:= 9; --long direcciones a dual port RAM
	        DATA_DP_W: natural:= 1;
            -- UART -- Default setting:
            -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
            DBIT_UART: integer:=8;     -- # data bits
            SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
            DVSR_UART: integer:= 3;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
            DVSR_BIT_UART: integer:=8; -- # bits of DVSR
            FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
            -- SRAM externa ----------
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
    -- rotador 3D --------------------------------------------
    signal flag_fin_tb: std_logic;
    -- gral_ctrl ---------------------------------------------
    signal rx_uart_empty_tb: std_logic:= '0';
    -- uart2sram ---------------------------------------------
    signal rx_tb, tx_tb: std_logic:= '1';
    signal ena_uart2sram_tb: std_logic:= '0';
    signal mem_uart_tb: std_logic:= '0';
    signal addr_tick_uart_tb: std_logic:= '0';
    -- sram2cordic -------------------------------------------
    signal ena_sram2cordic_tb: std_logic:= '0';
    signal mem_cordic_tb: std_logic:= '0';
    signal addr_tick_cordic_tb: std_logic:= '0';
    -- sram_ctrl ---------------------------------------------
    ----------------       lado fpga         -----------------
    signal addr_sram_tb: std_logic_vector(ADDR_W-1 downto 0)
                  := (others => '0');
    signal data_f2s_tb: std_logic_vector(DATA_W-1 downto 0)
                      := (others => '0');
    signal data_s2f_r_tb: std_logic_vector(DATA_W-1 downto 0)
                        := (others => '0');
    signal data_s2f_ur_tb: std_logic_vector(DATA_W-1 downto 0)
                         := (others => '0');
    signal mem_tb, rw_tb, ready_tb: std_logic := '0';
    ---------------       lado SRAM          -----------------    
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
	rst_tb <= '1' after 20 ns, '0' after 100 ns;
	ena_tb <= '0' after 40 ns, '1' after 35005 ns;

    -- :: primer byte de dato :: --
             -- bit de start
    rx_tb <= '0' after 1 ns,
             -- bits de datos
             '0' after 960 ns,
             '0' after 1920 ns,
             '0' after 2880 ns,
             '1' after 3840 ns,
             '0' after 4800 ns,
             '0' after 5760 ns,
             '1' after 6720 ns,
             '0' after 7680 ns,
             -- bit de stop
             '1' after 8640 ns,
             -- en reposo
             '1' after 9600 ns,
	        
        -- :: segundo byte de dato :: --
             -- bit de start
             '0' after 10000 ns,
    --rx_tb <= '0' after 10000 ns,
             -- bits de datos
             '1' after 10960 ns,
             '1' after 11920 ns,
             '1' after 12880 ns,
             '1' after 13840 ns,
             '0' after 14800 ns,
             '0' after 15760 ns,
             '1' after 16720 ns,
             '0' after 17680 ns,
             -- bit de stop
             '1' after 18640 ns,
             -- en reposo
             '1' after 19600 ns,
	
        -- :: tercer byte de dato :: --
             -- bit de start
    --rx_tb <= '0' after 20000 ns,
             '0' after 20000 ns,
             -- bits de datos
             '0' after 20960 ns,
             '0' after 21920 ns,
             '1' after 22880 ns,
             '1' after 23840 ns,
             '0' after 24800 ns,
             '0' after 25760 ns,
             '1' after 26720 ns,
             '0' after 27680 ns,
             -- bit de stop
             '1' after 28640 ns,
             -- en reposo
             '1' after 29600 ns,
	
        -- :: cuarto byte de dato :: --
             -- bit de start
    --rx_tb <= '0' after 30000 ns,
             '0' after 30000 ns,
             -- bits de datos
             '1' after 30960 ns,
             '0' after 31920 ns,
             '0' after 32880 ns,
             '0' after 33840 ns,
             '0' after 34800 ns,
             '0' after 35760 ns,
             '1' after 36720 ns,
             '0' after 37680 ns,
             -- bit de stop
             '1' after 38640 ns,
             -- en reposo
             '1' after 39600 ns,
	
        -- :: quinto byte de dato :: --
             -- bit de start
             '0' after 40000 ns,
             -- bits de datos
             '0' after 40960 ns,
             '0' after 41920 ns,
             '0' after 42880 ns,
             '0' after 43840 ns,
             '0' after 44800 ns,
             '1' after 45760 ns,
             '0' after 46720 ns,
             '0' after 47680 ns,
             -- bit de stop
             '1' after 48640 ns,
             -- en reposo
             '1' after 49600 ns,
	        
        -- :: sexto byte de dato :: --
             -- bit de start
             '0' after 50000 ns,
    --rx_tb <= '0' after 10000 ns,
             -- bits de datos
             '1' after 50960 ns,
             '0' after 51920 ns,
             '1' after 52880 ns,
             '1' after 53840 ns,
             '0' after 54800 ns,
             '0' after 55760 ns,
             '1' after 56720 ns,
             '0' after 57680 ns,
             -- bit de stop
             '1' after 58640 ns,
             -- en reposo
             '1' after 59600 ns,
	
         -- :: septimo byte de dato :: --
             -- bit de start
    --rx_tb <= '0' after 20000 ns,
             '0' after 60000 ns,
             -- bits de datos
             '1' after 60960 ns,
             '0' after 61920 ns,
             '1' after 62880 ns,
             '0' after 63840 ns,
             '1' after 64800 ns,
             '0' after 65760 ns,
             '1' after 66720 ns,
             '0' after 67680 ns,
             -- bit de stop
             '1' after 68640 ns,
             -- en reposo
             '1' after 69600 ns,
	
        -- :: octavo byte de dato :: --
             -- bit de start
    --rx_tb <= '0' after 30000 ns,
             '0' after 70000 ns,
             -- bits de datos
             '0' after 70960 ns,
             '1' after 71920 ns,
             '1' after 72880 ns,
             '1' after 73840 ns,
             '0' after 74800 ns,
             '0' after 75760 ns,
             '1' after 76720 ns,
             '0' after 77680 ns,
             -- bit de stop
             '1' after 78640 ns,
             -- en reposo
             '1' after 79600 ns,
	
        -- :: noveno byte de dato :: --
             -- bit de start
    --rx_tb <= '0' after 20000 ns,
             '0' after 80000 ns,
             -- bits de datos
             '0' after 80960 ns,
             '0' after 81920 ns,
             '1' after 82880 ns,
             '0' after 83840 ns,
             '0' after 84800 ns,
             '0' after 85760 ns,
             '1' after 86720 ns,
             '0' after 87680 ns,
             -- bit de stop
             '1' after 88640 ns,
             -- en reposo
             '1' after 89600 ns,
	
        -- :: decimo byte de dato :: --
             -- bit de start
             --rx_tb <= '0' after 30000 ns,
             '0' after 90000 ns,
             -- bits de datos
             '1' after 90960 ns,
             '1' after 91920 ns,
             '1' after 92880 ns,
             '1' after 93840 ns,
             '0' after 94800 ns,
             '0' after 95760 ns,
             '1' after 96720 ns,
             '0' after 97680 ns,
             -- bit de stop
             '1' after 98640 ns,
             -- en reposo
             '1' after 99600 ns,

        -- :: onceavo byte EOF_WORD :: --
             -- bit de start
    --rx_tb <= '0' after 20000 ns,
             '0' after 100000 ns,
             -- bits de datos
             '1' after 100960 ns,
             '1' after 101920 ns,
             '1' after 102880 ns,
             '1' after 103840 ns,
             '1' after 104800 ns,
             '1' after 105760 ns,
             '1' after 106720 ns,
             '1' after 107680 ns,
             -- bit de stop
             '1' after 108640 ns,
             -- en reposo
             '1' after 109600 ns,
	
        -- :: doceavo byte EOF_WORD :: --
             -- bit de start
             --rx_tb <= '0' after 30000 ns,
             '0' after 110000 ns,
             -- bits de datos
             '1' after 110960 ns,
             '1' after 111920 ns,
             '1' after 112880 ns,
             '1' after 113840 ns,
             '1' after 114800 ns,
             '1' after 115760 ns,
             '1' after 116720 ns,
             '1' after 117680 ns,
             -- bit de stop
             '1' after 118640 ns,
             -- en reposo
             '1' after 119600 ns;
	

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
   -- dio_a_tb <= EOF_WORD when dio_a_tb_aux(DATA_W+2 downto 3) = DATA_MATCH else
   --             dio_a_tb_aux(DATA_W+2 downto 3); --#
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

    DUT1: entity work.uart2sram
    generic map(
        -- Default setting:
        -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
        DBIT_UART => DBIT_UART,
        SB_TICK_UART => SB_TICK_UART,
        DVSR_UART => DVSR_UART,
        DVSR_BIT_UART => DVSR_BIT_UART,
        FIFO_W_UART => FIFO_W_UART,
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
    )
    port map(
        clk => clk_tb, rst => rst_tb, ena => ena_uart2sram_tb,
        rx => rx_tb,
        tx => tx_tb,
        -- a sram_ctrl
        data_out => data_f2s_tb,
        mem => mem_uart_tb,
        ready => ready_tb, 
        addr_tick => addr_tick_uart_tb
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

