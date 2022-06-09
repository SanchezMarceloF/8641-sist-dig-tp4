----------------------------------------------------------------------------------
-- Create Date: 13/08/2019 
-- Designer Name: Sanchez Marcelo
-- Module Name: Tp4
-- Project Name: Disenio de un motor de rotacion grafico
--				3D basado en el algoritmo CORDIC
-- Target Devices: Spartan 3
-- Tool versions: v1.0
--
----------------------------------------------------------------------------------
-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity tp4 is
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
    
--    attribute loc: string;
--	attribute iostandard: string;
--	
--	--Mapeo de pines para el kit Nexys 2 (spartan 3E)
--	attribute loc of clk: signal is "B8";
--	attribute loc of rst: signal is "B18";
--    
--    -- Pulsadores
--    attribute loc of pulsadores: signal is "D18 E18 H13";
--
--    -- UART
--	attribute loc of rx: signal is "U6";
--	attribute loc of tx: signal is "P9";
--    
--    -- SRAM externa
--	attribute loc of we_n: signal is "N7";
--	attribute loc of oe_n: signal is "T2";
--	attribute loc of dio_sram: signal is "T1 R3 N4 L2 M6 M3 L5 L3 R2 P2 P1 N5
--                                          M4 L6 L4 L1";
--	attribute loc of ce_n: signal is "R6";
--	attribute loc of ub_n: signal is "K4";
--	attribute loc of lb_n: signal is "K5";
--	attribute loc of address_sram: signal is "K6 D1 K3 D2 C1 C2 E2 M5 E1 F2 G4
--                                        G5 G6 G3 F1 H6 H3 J5 H2 H1 H4 J2 J1 NA";
--    -- VGA	
--	attribute loc of hs: signal is "T4";
--	attribute loc of vs: signal is "U3";
--	attribute loc of red_o: signal is "R8 T8 R9";
--	attribute loc of grn_o: signal is "P6 P8 N8";
--	attribute loc of blu_o: signal is "U4 U5";

        
end;

-- cuerpo de arquitectura
architecture tp4_arq of tp4 is
	-- declaracion de componente, senales, etc

    component uart2sram_ctrl is
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
    port(
        clk, rst, ena : in std_logic;
        rx : in std_logic;
        tx : out std_logic;
        we_n, oe_n: out std_logic;
        ad : out std_logic_vector(ADDR_W-1 downto 0);
        dio_a : inout std_logic_vector(DATA_W-1 downto 0);
        ce_a_n, ub_a_n, lb_a_n : out std_logic
    );
    end component uart2sram_ctrl;

	component generador_direcciones is
	generic(N: integer := 13;	--longitud de los vectores
			L: integer := 9);	--longitud de las direcciones
	port(
		--flag: in std_logic;	--me avisa cuando termina de rotar.
		x, y: in std_logic_vector(N-1 downto 0);
		Addrx, Addry: out std_logic_vector(L-1 downto 0)
		--grabar: out std_logic
	);
	end component;
	
	component xilinx_dual_port_ram_sync is
	generic (
		ADDR_WIDTH: integer:=2*ADDR_DP_W;
		DATA_WIDTH:	integer:=1
	);
	port (
		clk: in std_logic;
		we: in std_logic;
		rst: in std_logic;
		addr_a: in std_logic_vector (ADDR_WIDTH-1 downto 0);
		addr_b: in std_logic_vector (ADDR_WIDTH-1 downto 0);
		din_a: in std_logic_vector (DATA_WIDTH-1 downto 0);
		dout_a: out std_logic_vector (DATA_WIDTH-1 downto 0);
		dout_b: out std_logic_vector (DATA_WIDTH -1 downto 0)
	);
	end component;
	
	component controlador is
	generic(
		M: integer:= 10; --long de vectores pixel de vga_ctrl
		N: integer:= 9 --long vectores direccionamiento
		--W: integer:= 8
	);
	port(
		pixel_row, pixel_col: in std_logic_vector(M-1 downto 0);
		address: out std_logic_vector(N*2 - 1 downto 0)
	);
	end component;
	
	component vga_ctrl is
    port (
		mclk: in std_logic;
		red_i: in std_logic;
		grn_i: in std_logic;
		blu_i: in std_logic;
		hs: out std_logic;
		vs: out std_logic;
		red_o: out std_logic_vector(2 downto 0);
		grn_o: out std_logic_vector(2 downto 0);
		blu_o: out std_logic_vector(1 downto 0);
		pixel_row: out std_logic_vector(9 downto 0);
		pixel_col: out std_logic_vector(9 downto 0)
	);
	end component;	
	
	
	--señales de prueba
    signal xn_aux, yn_aux: std_logic_vector(COORD_W-1 downto 0);
	signal flag_fin_3d: std_logic:= '0';
	--señales para generador_direcciones
	signal Addrx_aux, Addry_aux: std_logic_vector(ADDR_DP_W-1 downto 0);
	--señales para la dual port ram
	signal we_aux: std_logic;
	signal din_porta, dout_b_aux: std_logic_vector(DATA_DP_W-1 downto 0);
	signal addr_porta, addr_portb: std_logic_vector(2*ADDR_DP_W-1 downto 0);
	--señales para controlador y vga
	signal red_aux, grn_aux: std_logic_vector(2 downto 0);
	signal blu_aux: std_logic_vector(1 downto 0);
	signal vs_aux, hs_aux: std_logic;
	signal pxl_col_aux, pxl_row_aux: std_logic_vector(ADDR_W-1 downto 0);
    -- señales para la sram externa
    signal dio_sram_aux : std_logic_vector(DATA_W-1 downto 0);
	
	
	
begin	

	uart2sram: uart2sram_ctrl
    generic map(
        DBIT_UART => DBIT_UART, -- # data bits
        SB_TICK_UART => SB_TICK_UART, -- # ticks for stop bits, 16/24/32
        DVSR_UART => DVSR_UART,  -- baud rate divisor
        DVSR_BIT_UART => DVSR_BIT_UART, -- # bits of DVSR
        FIFO_W_UART => FIFO_W_UART,    -- # addr bits of FIFO
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
    )
    port map(
        clk => clk, rst => rst, ena => ena,
        rx => rx,
        tx => tx,
        we_n => we_n, oe_n => oe_n,
        ad => address_sram,
        dio_a => dio_sram_aux,
        ce_a_n => ce_n, ub_a_n => ub_n, lb_a_n => lb_n
    );
	
	gen_dir: generador_direcciones
	generic map(N => COORD_W, L => ADDR_DP_W)	--longitud de las direcciones
	port map(
		--flag: in std_logic;	--me avisa cuando termina de rotar.
		x => xn_aux, y => yn_aux,
		Addrx => Addrx_aux, Addry => Addry_aux --direcciones a port A dual port RAM
	);
	
	addr_porta <= Addry_aux & Addrx_aux;
	--CAMBIAR DESDE CONTROLADOR------------------------
	din_porta <= "1";				
	--#################################################
	
	dualport_ram: xilinx_dual_port_ram_sync
	generic map( ADDR_WIDTH => 2*ADDR_DP_W, DATA_WIDTH => DATA_DP_W)
	port map(
		clk => clk, we => flag_fin_3d, rst =>rst,
		addr_a => addr_porta, addr_b => addr_portb,
		din_a => din_porta, dout_a => open, dout_b => dout_b_aux
	);
	
	
	ctrl_portb: controlador
	generic map (M => ADDR_W, N => ADDR_DP_W) --long de vectores pixel de vga_ctrl
		--long vectores direccionamiento
	port map(
		pixel_row => pxl_row_aux,
		pixel_col => pxl_col_aux,
		address => addr_portb --direcciones a port B dual port RAM
	);
	
	
	vga: vga_ctrl
    port map(
		mclk => clk, red_i => '1', grn_i => '1', blu_i => dout_b_aux(0),
		hs => hs_aux, vs => vs_aux, red_o => red_aux, grn_o => grn_aux,
		blu_o => blu_aux, pixel_row => pxl_row_aux, pixel_col => pxl_col_aux
	);
	
	--salidas
	
	blu_o <= blu_aux; ---CAMBIAR
	hs <= hs_aux;
	vs <= vs_aux;
	
end;
