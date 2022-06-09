-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity tp4_tb is
	generic(COORD_W: integer:= 13;  --long coordenadas x, y, z.
			ANG_W: integer:= 15;    --long angulos de rotacion
			ADDR_DP_W: integer:= 9; --long direcciones a dual port RAM
	        DATA_DP_W: natural:= 1;
            -- UART -- Default setting:
            -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
            DBIT_UART: integer:=8;     -- # data bits
            SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
            DVSR_UART: integer:= 163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
            DVSR_BIT_UART: integer:=8; -- # bits of DVSR
            FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
            -- SRAM externa ----------
            DATA_W: natural := 16;
		    ADDR_W: natural := 23
    );
	end;

-- cuerpo de arquitectura
architecture tp4_tb_arq of tp4_tb is

    component tp4 is
	generic(COORD_W: integer:= 13;  --long coordenadas x, y, z.
			ANG_W: integer:= 15;    --long angulos de rotacion
			ADDR_DP_W: integer:= 9; --long direcciones a dual port RAM
	        DATA_DP_W: natural:= 1;
            -- UART -- Default setting:
            -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
            DBIT_UART: integer:=8;     -- # data bits
            SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
            DVSR_UART: integer:= 163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
            DVSR_BIT_UART: integer:=8; -- # bits of DVSR
            FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
            -- SRAM externa ----------
            DATA_W: natural := 16;
		    ADDR_W: natural := 23
    );
	port(
		clk, ena, rst: in std_logic;
        -- a UART ----------------------------------
        rx : in std_logic;
        tx : out std_logic;
		-- pulsadores(5): alfa_up | (4): alfa_down | (3): beta_up
		-- (2): beta_down | (1): gamma_up | (0): gamma_down	
		pulsadores: in std_logic_vector(5 downto 0);
		-- xin, yin, zin: in std_logic_vector(COORD_W-1 downto 0);
        -- a SRAM externa --------------------------
        we_n, oe_n : out std_logic;
        dio_sram : inout std_logic;
        ce_n, ub_n, lb_n : out std_logic;
		address_sram: out std_logic_vector(DATA_W-1 downto 0);
        -- a VGA ----------------------------------- 
	    red_o: out std_logic_vector(2 downto 0);
		grn_o: out std_logic_vector(2 downto 0);
		blu_o: out std_logic_vector(1 downto 0);	
        hs, vs: out std_logic		
		);
    end component;
    
    --señales de prueba
	
    signal clk_tb, ena_tb, rst_tb: std_logic;
    -- a UART ----------------------------------
    signal rx_tb : std_logic;
    signal tx_tb : std_logic;
	signal pulsadores_tb: std_logic_vector(5 downto 0);
	signal  xin, yin, zin: std_logic_vector(COORD_W-1 downto 0);
    -- a SRAM externa --------------------------
    signal we_n_tb, oe_n_tb : std_logic;
    signal dio_sram_tb : std_logic;
    signal ce_n_tb, ub_n_tb, lb_n_tb : std_logic;
	signal address_sram_tb: std_logic_vector(DATA_W-1 downto 0);
    -- a VGA ----------------------------------- 
	signal red_o_tb: std_logic_vector(2 downto 0);
	signal grn_o_tb: std_logic_vector(2 downto 0);
	signal blu_o_tb: std_logic_vector(1 downto 0);	
    signal hs_tb, vs_tb: std_logic;		
	
	
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 

	pulsadores_tb <= "010010";
	ena_tb <= '1';
	rst_tb <= '1' after 20 ns, '0' after 100 ns;
	
	DUT: tp4
	generic map(COORD_W => COORD_W, --long coordenadas x, y, z.
			ANG_W => ANG_W,    --long angulos de rotacion
			ADDR_DP_W => ADDR_DP_W, --long direcciones a dual port RAM
	        DATA_DP_W => DATA_DP_W,
            -- UART -- Default setting:
            -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
            DBIT_UART => DBIT_UART,     -- # data bits
            SB_TICK_UART => SB_TICK_UART, -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
            DVSR_UART => DVSR_UART,  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
            DVSR_BIT_UART => DVSR_BIT_UART, -- # bits of DVSR
            FIFO_W_UART => FIFO_W_UART,    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
            -- SRAM externa ----------
            DATA_W => DATA_W,
		    ADDR_W => ADDR_W
    )
	port map(
		clk => clk_tb, ena => ena_tb, rst => rst_tb,
        -- a UART ----------------------------------
        rx => rx_tb,
        tx => tx_tb,
		-- pulsadores(5): alfa_up | (4): alfa_down | (3): beta_up
		-- (2): beta_down | (1): gamma_up | (0): gamma_down	
		pulsadores => pulsadores_tb,
		-- xin, yin, zin: in std_logic_vector(COORD_W-1 downto 0);
        -- a SRAM externa --------------------------
        we_n => we_n_tb, oe_n => oe_n_tb,
        dio_sram => dio_sram_tb,
        ce_n => ce_n_tb, ub_n => ub_n_tb, lb_n => lb_n_tb,
		address_sram => address_sram_tb,
        -- a VGA ----------------------------------- 
	    red_o => red_o_tb,
		grn_o => grn_o_tb,
		blu_o => blu_o_tb,	
        hs => hs_tb, vs => vs_tb		
		);
  
    

		
end;
