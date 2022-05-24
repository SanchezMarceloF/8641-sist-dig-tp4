library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart2sram_wrap is
    generic(
        -- Default setting:
        -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
        DBIT_UART: integer:=8;     -- # data bits
        SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
        DVSR_UART: integer:= 163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
        DVSR_BIT_UART: integer:=8; -- # bits of DVSR
        FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
        DATA_W: natural := 16;
		ADDR_W: natural := 18
    );

    attribute loc: string;
	attribute iostandard: string;

	--Mapeo de pines para el kit Nexys 2 (spartan 3E)
    -- https://reference.digilentinc.com/_media/nexys:nexys2:nexys2_rm.pdf
	--attribute loc of clk: signal is "B8";
	--attribute loc of rst: signal is "B18";

	--attribute iostandard of data_volt_in_p: signal is "LVDS_25";
	--attribute loc of data_volt_in_p: signal is "G15"; --"D7"; --"L16"
	--attribute iostandard of data_volt_in_n: signal is "LVDS_25";
	--attribute loc of data_volt_in_n: signal is "G16"; --"E7"; --"L15"

	--attribute loc of hs: signal is "T4";
	--attribute loc of vs: signal is "U3";
	--attribute loc of red_o: signal is "R8 T8 R9";
	--attribute loc of grn_o: signal is "P6 P8 N8";
	--attribute loc of blu_o: signal is "U4 U5";
	-- attribute loc of data_volt_in_p: signal is "G15";
	-- attribute loc of data_volt_in_n: signal is "G16";
	--attribute loc of P: signal is "J12";

end uart2sram_wrap;

architecture uart2sram_wrap_arch of uart2sram_wrap is 

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

