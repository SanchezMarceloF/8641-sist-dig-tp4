library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart2sram_tb is
    generic(
        -- Default setting:
        -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
        DBIT_UART: integer:=8;     -- # data bits
        SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
        DVSR_UART: integer:= 3; --163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
        DVSR_BIT_UART: integer:=8; -- # bits of DVSR
        FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
        DATA_W: natural := 16;
		ADDR_W: natural := 18
    );
end uart2sram_tb;

architecture uart2sram_tb_arch of uart2sram_tb is 

--    constant BIT_W : time := 20 ns * DVSR_BIT_UART * 16; 

    --señales de prueba --------------------------------------

    signal clk_tb, rst_tb, ena_tb : std_logic := '0';
    signal rx_tb : std_logic := '1';
    signal sw_tb, tx_tb : std_logic := '0';
    signal we_n_tb, oe_n_tb : std_logic;
    signal ad_tb : std_logic_vector(ADDR_W-1 downto 0)
                 := (others =>'0');
    signal dio_a_tb : std_logic_vector(DATA_W-1 downto 0)
                    := (others =>'0');
    signal ce_a_n_tb, ub_a_n_tb, lb_a_n_tb : std_logic;

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
             '1' after 99600 ns;
	

    DUT: entity work.uart2sram_ctrl(uart2sram_ctrl_arch)
    generic map(
        DBIT_UART => DBIT_UART,        -- # data bits
        SB_TICK_UART => SB_TICK_UART,
        DVSR_UART => DVSR_UART,  -- baud rate divisor
        DVSR_BIT_UART => DVSR_BIT_UART, -- # bits of DVSR
        FIFO_W_UART => FIFO_W_UART,    -- # addr bits of FIFO
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
    )
    port map(
        clk => clk_tb, rst => rst_tb, ena => ena_tb,
        rx => rx_tb,
        tx => tx_tb,
        we_n => we_n_tb, oe_n => oe_n_tb,
        ad => ad_tb,
        dio_a => dio_a_tb,
        ce_a_n => ce_a_n_tb, ub_a_n => ub_a_n_tb,
        lb_a_n => lb_a_n_tb
    );

end;    

