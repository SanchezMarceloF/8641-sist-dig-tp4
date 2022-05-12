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

    signal clk_tb, rst_tb : std_logic := '0';
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

	sw_tb <= '0' after 135 ns, '1' after 11010 ns;
             -- bit de start
    rx_tb <= '0' after 160 ns,
             -- bits de datos
             '1' after 1120 ns,
             '0' after 2080 ns,
             '0' after 3040 ns,
             '1' after 4000 ns,
             '1' after 4960 ns,
             '0' after 5920 ns,
             '1' after 6880 ns,
             '0' after 7840 ns,
             -- bit de stop
             '1' after 8800 ns,
             -- en reposo
             '1' after 9760 ns;
	
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
        clk => clk_tb, rst => rst_tb,
        sw => sw_tb,
        rx => rx_tb,
        tx => tx_tb,
        we_n => we_n_tb, oe_n => oe_n_tb,
        ad => ad_tb,
        dio_a => dio_a_tb,
        ce_a_n => ce_a_n_tb, ub_a_n => ub_a_n_tb,
        lb_a_n => lb_a_n_tb
    );

end;    

