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
	generic(COORD_W: integer:= 14;  --long coordenadas x, y, z.
			ANG_W: integer:= 16; --15	  --long angulos de rotacion
			ADDR_DP_W: integer:= 9; --long direcciones a dual port RAM
			DATA_DP_W: natural:= 1;
          -- UART -- Default setting:
          -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
			DBIT_UART: integer:=8;    	-- # data bits
			SB_TICK_UART: integer:=16; 	-- # ticks for stop bits, 16/24/32
										--   for 1/1.5/2 stop bits
			DVSR_UART: integer:= 163;  -- baud rate divisor
										-- DVSR = 50M/(16*baud rate)
			DVSR_BIT_UART: integer:=8; -- # bits of DVSR
			FIFO_W_UART: integer:=2;   -- # addr bits of FIFO
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
		-- pulsadores(3 2): eje select | (1): up | (0): down
		pulsadores: in std_logic_vector(3 downto 0);
		vga_clear_ext: in std_logic;
		ena_rot_ext: in std_logic;
		transparencia: in std_logic;
		-- a SRAM externa --------------------------
		adv, mt_clk, mt_cre : out std_logic;
		we_n, oe_n : out std_logic;
		dio_sram : inout std_logic_vector(DATA_W-1 downto 0);
		ce_n, ub_n, lb_n : out std_logic;
		address_sram: out std_logic_vector(ADDR_W-1 downto 0);
		-- a VGA ----------------------------------- 
		red_o: out std_logic_vector(2 downto 0);
		grn_o: out std_logic_vector(2 downto 0);
		blu_o: out std_logic_vector(1 downto 0);	
		hs, vs: out std_logic;
		-- a 7 segmentos
		sal_7seg: out std_logic_vector(11 downto 0);
		-- para capturar en simulacion
		tick_dpr: out std_logic;
		pxl_x: out std_logic_vector(ADDR_DP_W-1 downto 0);
		pxl_y: out std_logic_vector(ADDR_DP_W-1 downto 0)
	);
	
	-- *-----------------------* 
    -- | baud rate | DVSR_UART |
    -- *-----------+-----------*     
    -- |      300    10416.7   |
    -- |      600     5208.3   |
    -- |     1200     2604.2   |
    -- |     2400     1302.1   |
    -- |     4800      651     |
    -- |     9600      325.5   |
    -- |    14400      217     |
    -- |    19200      162.8   |
    -- |    38400       81.4   |
    -- |    57600       54.3   |
    -- |   115200       27.1   |
    -- |   230400       13.6   |
    -- |   460800        6.8   |
    -- *-----------------------*
    
--  attribute loc: string;
--	attribute iostandard: string;
--	
--	--Mapeo de pines para el kit Nexys 2 (Spartan 3E-500 FG320)
--	attribute loc of clk: signal is "B8"; --CHECK OK
--	attribute loc of rst: signal is "B18";
--	attribute loc of ena: signal is "G18";
--    
--  -- Pulsadores rotacion
--  attribute loc of pulsadores: signal is "R17 N17 H13 E18"; --CHECK OK
--
--	--Boton borrado dpr, habilitador rotacion, transparencia
--	attribute loc of vga_clear_ext: signal is "D18"; --CHECK OK
--	attribute loc of ena_rot_ext: signal is "H18";
--	attribute loc of transparencia: signal is "K18";
--  
--  -- UART
--	attribute loc of rx: signal is "G15"; --(Pmod conector) --"U6"; --VA A DB-9 (RS-232)
--  attribute loc of tx: signal is "J16"; --(Pmod conector) --"P9"; --VA A DB-9 (RS-232)
--    
--  -- SRAM externa
--	attribute loc of adv: signal is "J4"; -- CHECK OK
--	attribute loc of mt_clk: signal is "H5"; -- CHECK OK
--	attribute loc of mt_cre: signal is "P7"; -- CHECK OK
--	attribute loc of we_n: signal is "N7"; -- CHECK OK
--	attribute loc of oe_n: signal is "T2"; -- CHECK OK
--  -- dio_sram CHECK OK
--	attribute loc of dio_sram: signal is "T1 R3 N4 L2 M6 M3 L5 L3 R2 P2 P1 N5 M4 L6 L4 L1"; 
--	attribute loc of ce_n: signal is "R6"; --CHECK OK
--	attribute loc of ub_n: signal is "K4"; --CHECK OK
--	attribute loc of lb_n: signal is "K5"; --CHECK OK
--  -- address_sram -> 22 a 0 CHECK OK (ADDR0 en DRAM desconectado) 
--	attribute loc of address_sram: signal is "K6 D1 K3 D2 C1 C2 E2 M5 E1 F2 G4 G5 G6 G3 F1 H6 H3 J5 H2 H1 H4 J2 J1";                       
--  -- VGA  -- CHECK OK	
--	attribute loc of hs: signal is "T4";
--	attribute loc of vs: signal is "U3";
--	attribute loc of red_o: signal is "R8 T8 R9";
--	attribute loc of grn_o: signal is "P6 P8 N8";
--	attribute loc of blu_o: signal is "U4 U5";
--
--  -- a 7 segmentos
--  attribute LOC of sal_7seg: signal is "F17 H17 C18 F15 L18 F18 D17 D16 G14 J17 H14 C17";

        
end tp4;

-- cuerpo de arquitectura
architecture tp4_arq of tp4 is
	-- declaracion de componente, senales, etc
   
    component gral_ctrl is
    generic(
        COORD_W: natural := 13;
        DATA_W: natural := 16;
		ADDR_W: natural := 23 
    );
    port(
		clk, rst, ena : in std_logic;
		-- a sram2cordic
		ena_sram2cordic: out std_logic;
		addr_tick_cordic: in std_logic;
		mem_cordic: in std_logic;
		 flag_eof: in std_logic;
		-- a uart2sram
		ena_uart2sram: out std_logic;
		rx_uart_empty: in std_logic;
		addr_tick_uart: in std_logic;
		mem_uart: in std_logic;
		-- a sram_ctrl
		data_f2s: in std_logic_vector(DATA_W-1 downto 0);
		data_s2f_r: in std_logic_vector(DATA_W-1 downto 0);
		addr_sram: out std_logic_vector(ADDR_W-1 downto 0);
		mem: out std_logic;
		rw: out std_logic;
		-- para 7 segmentos
		state: out std_logic_vector(2 downto 0);
		-- a rotador3d
		flag_rotnew: in std_logic;
		-- a borrador dual port ram
		clear_fin: in std_logic;
		borrar: out std_logic;
		-- switch externo
		ena_rot_ext: in std_logic
    );
    end component;

    component uart2sram is
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
        -- a sram_ctrl
        data_out : out std_logic_vector(DATA_W-1 downto 0);
        mem   : out std_logic;
        ready : in std_logic;
		addr_tick : out std_logic;
		state: out std_logic_vector(2 downto 0)
    );
    end component;

	component sram_ctrl is
	generic(DATA_W: natural := 16;
			ADDR_W: natural := 18);
	port(
		clk, reset: in std_logic;
		-- to/from main system
		mem: in std_logic;
		rw: in std_logic;
		addr: in std_logic_vector(ADDR_W-1 downto 0);
		data_f2s: in std_logic_vector(DATA_W-1 downto 0);
		ready: out std_logic;
		data_s2f_r, data_s2f_ur: out std_logic_vector(DATA_W-1 downto 0);
		ce_in_n, lb_in_n, ub_in_n: in std_logic; 
		-- to/from chip
		ad: out std_logic_vector(ADDR_W-1 downto 0);
		we_n, oe_n: out std_logic;
		-- SRAM chip a
		dio_a: inout std_logic_vector(DATA_W-1 downto 0);
		ce_a_n, ub_a_n, lb_a_n: out std_logic
	);
	end component;
	
	component sram2cordic is
		generic(
		COORD_W: natural := 13;
		DATA_W: natural := 16;
		ADDR_W: natural := 18
	);
	port(
		clk, rst, ena : in std_logic;
		-- hacia/desde rotador 3d
		coord_ready: out std_logic;
		flag_fin3d: in std_logic;
		x_coord: out std_logic_vector(COORD_W-1 downto 0);
		y_coord: out std_logic_vector(COORD_W-1 downto 0);
		z_coord: out std_logic_vector(COORD_W-1 downto 0);
		-- a gral_ctrl
		flag_eof: out std_logic;
		-- a sram_ctrl
		data_in: in std_logic_vector(DATA_W-1 downto 0);
		mem: out std_logic;
		ready: in std_logic;
		ena_count_tick: out std_logic;
		-- a 7 segmentos
		state: out std_logic_vector(2 downto 0)
	);
	end component;
	
	component rotador3d is
	generic(COORD_W: natural := 13;		--longitud de los vectores
			ANG_WIDE: natural := 15;	--longitud de los angulos
			ADDR_DP_W: natural := 9);	--longitud direcciones dpr
	port(
		rst, ena, clk: in std_logic;
		-- desde botones 
		pulsadores: in std_logic_vector(3 downto 0);
		transparencia: in std_logic;
		-- hacia gral_ctrl
		rotnew: out std_logic;
		-- desde/hacia sram2cordic
		x_0, y_0, z_0: in std_logic_vector(COORD_W-1 downto 0);
		coord_ready: in std_logic;
		coord_ok: out std_logic;
		-- hacia dual port ram
		addr_dpr: out std_logic_vector(2*ADDR_DP_W-1 downto 0);
		dpr_tick: out std_logic;
		-- a 7 segmentos
		state: out std_logic_vector(2 downto 0)
	);
	end component;
	
	component borrado_dpr is
	generic(
		ADDR_W: integer:= 18; --long vectores direccionamiento
		DATA_W: integer:= 1  --len of data
	);
	port(
		clk, rst, ena: in std_logic;
		addr_in: in std_logic_vector(ADDR_W-1 downto 0);
		addr_out: out std_logic_vector(ADDR_W-1 downto 0);
		we: out std_logic;
		data: out std_logic_vector(DATA_W-1 downto 0);
		flag_fin: out std_logic
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
    port(
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
	
	component ctrl_7seg is
	port(
		clk, rst: in std_logic;
		-- a sram2cordic
		gral_ctrl_state: in std_logic_vector(2 downto 0);
		uart2sram_state: in std_logic_vector(2 downto 0);
		sram2cordic_state: in std_logic_vector(2 downto 0);
		rotador3d_state: in std_logic_vector(2 downto 0);
		sal_7seg: out std_logic_vector(11 downto 0)
	);
	end component;


    -- Señales ----------------------------------------------
    -- signal pulsadores_aux: std_logic_vector(5 downto 0):= "000000";
	signal vga_clear, ctrl_clear, clear_fin_wire: std_logic:= '0';
	-- Dual port RAM ----------------------------------------
    signal dpr_tick_wire: std_logic;
    signal x_0_wire: std_logic_vector(COORD_W-1 downto 0);
    signal y_0_wire: std_logic_vector(COORD_W-1 downto 0);
    signal z_0_wire: std_logic_vector(COORD_W-1 downto 0);
    -- rotador 3D --------------------------------------------
    signal ctrl_3d, flag_fin3d_wire, rotnew_wire, rst_rotador3d: std_logic;
    -- gral_ctrl ---------------------------------------------
    signal rx_uart_empty_wire: std_logic:= '0';
    signal flag_eof_wire: std_logic;
    -- uart2sram ---------------------------------------------
    --signal rx_wire, tx_wire: std_logic:= '1';
    signal ena_uart2sram_wire: std_logic:= '0';
    signal mem_uart_wire: std_logic:= '0';
    signal addr_tick_uart_wire: std_logic:= '0';
    -- sram2cordic -------------------------------------------
    signal ena_sram2cordic_wire: std_logic:= '0';
    signal mem_cordic_wire: std_logic:= '0';
    signal addr_tick_cordic_wire: std_logic:= '0';
    -- sram_ctrl -----------------------------------------------------
    ----------------       lado fpga         -----------------
	signal addr_sram_wire: std_logic_vector(ADDR_W-1 downto 0)
                  := (others => '0');
	signal data_f2s_wire: std_logic_vector(DATA_W-1 downto 0)
                      := (others => '0');
	signal data_s2f_r_wire: std_logic_vector(DATA_W-1 downto 0)
                        := (others => '0');
	signal data_s2f_ur_wire: std_logic_vector(DATA_W-1 downto 0)
                         := (others => '0');
	signal mem_wire, rw_wire, ready_wire: std_logic := '0';
	---------------------         lado SRAM          --------------------
	-- señales para la dual port ram -----------------------------------
	signal we_aux, we_borrador, rst_borrador: std_logic:= '0';
	signal din_porta, dout_b_aux: std_logic_vector(DATA_DP_W-1 downto 0);
	signal addr_porta, addr_porta_in, addr_portb: std_logic_vector(2*ADDR_DP_W-1 downto 0);
	-- señales para controlador y vga --------------------------------------
	--signal red_aux, grn_aux: std_logic_vector(2 downto 0);
	signal blu_aux: std_logic_vector(1 downto 0);
	signal vs_aux, hs_aux: std_logic;
	signal pxl_col_aux, pxl_row_aux: std_logic_vector(9 downto 0);
	-- señales para la sram externa ----------------------------------------
	signal dio_sram_aux : std_logic_vector(DATA_W-1 downto 0);
	-- señales a 7 segmentos
	signal gral_ctrl_state, uart2sram_state, sram2cordic_state, rotador3d_state: std_logic_vector(2 downto 0);
	signal sal_7seg_wire: std_logic_vector(11 downto 0);
	
	
begin	
 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                       Conexión de componentes                           |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+

	gral_ctrl_inst: gral_ctrl
	generic map(
		COORD_W => COORD_W,
		DATA_W => DATA_W,
		ADDR_W => ADDR_W
	)
	port map(
		clk => clk, rst => rst, ena => ena,
	   -- a sram2cordic
		ena_sram2cordic => ena_sram2cordic_wire,
		addr_tick_cordic => addr_tick_cordic_wire,
		mem_cordic => mem_cordic_wire,
		flag_eof => flag_eof_wire,
		-- a uart2sram
	   ena_uart2sram => ena_uart2sram_wire,
		rx_uart_empty => rx_uart_empty_wire,
		addr_tick_uart => addr_tick_uart_wire,
		mem_uart => mem_uart_wire,
		-- a sram_ctrl
		data_f2s => data_f2s_wire,
		data_s2f_r => data_s2f_r_wire,
		addr_sram => addr_sram_wire,
		mem => mem_wire,
		rw => rw_wire,
		state => gral_ctrl_state,
		-- a rotador3d
		flag_rotnew => rotnew_wire,
		-- a borrador dual port ram
		clear_fin => clear_fin_wire,
		borrar => ctrl_clear,
		-- switch externo
		ena_rot_ext => ena_rot_ext
	);

	uart2sram_inst: uart2sram
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
		clk => clk, rst => rst, ena => ena_uart2sram_wire,
		rx => rx,
		tx => tx,
		-- a sram_ctrl
		data_out => data_f2s_wire,
		mem => mem_uart_wire,
		ready => ready_wire, 
		addr_tick => addr_tick_uart_wire,
		-- a 7 segmentos
		state => uart2sram_state
	);

	sram_ctrl_inst: sram_ctrl
	generic map(
		DATA_W => DATA_W,
		ADDR_W => ADDR_W
	)
	port map(
		clk => clk, reset => rst,
		-- to/from main system
		mem         => mem_wire,
		rw          => rw_wire,
		addr        => addr_sram_wire,
		data_f2s    => data_f2s_wire,
		ready       => ready_wire,
		data_s2f_r  => data_s2f_r_wire,
		data_s2f_ur => data_s2f_ur_wire,
		ce_in_n     => '0',
		lb_in_n     => '0',
		ub_in_n     => '0',
		-- to/from chip
		ad      => address_sram,          
		we_n    => we_n,
		oe_n    => oe_n,
		-- SRAM chip a
		dio_a   => dio_sram,
		ce_a_n  => ce_n,
		ub_a_n  => ub_n,
		lb_a_n  => lb_n
	);

	sram2cordic_inst: sram2cordic
	generic map(
		COORD_W => COORD_W,
		DATA_W => DATA_W,
		ADDR_W => ADDR_W
	)
	port map(
		clk => clk, rst => rst,
		ena => ena_sram2cordic_wire,
		-- hacia/desde rotador 3d
		coord_ready => ctrl_3d,
		flag_fin3d => flag_fin3d_wire,
		x_coord => x_0_wire,
		y_coord => y_0_wire,
		z_coord => z_0_wire,
		-- a gral_ctrl
		flag_eof => flag_eof_wire,
		-- a sram_ctrl
		data_in => data_s2f_r_wire,
		mem => mem_cordic_wire,
		ready => ready_wire,
		ena_count_tick => addr_tick_cordic_wire,
		-- a 7 segmentos
		state => sram2cordic_state
	);
	
	rst_rotador3d <= rst and not ena_rot_ext;
	
   rotador_3d_inst: rotador3d
	generic map(
		COORD_W => COORD_W, 	--longitud de los vectores
		ANG_WIDE => ANG_W,		--longitud de los angulos
		ADDR_DP_W => ADDR_DP_W	--longitud direcciones dpr
	)
	port map(
		rst => rst_rotador3d, ena => ena, clk => clk,
		pulsadores => pulsadores,
		transparencia => transparencia,
		rotnew => rotnew_wire,
		x_0 => x_0_wire,
		y_0 => y_0_wire,
		z_0 => z_0_wire,
		coord_ready => ctrl_3d,
		coord_ok => flag_fin3d_wire,
		addr_dpr => addr_porta_in,
		dpr_tick => dpr_tick_wire,
		-- a 7 segmentos
		state => rotador3d_state
	);
	
	vga_clear <= vga_clear_ext or ctrl_clear;
	rst_borrador <= rst or not vga_clear;
	
	borrador: borrado_dpr
	generic map(ADDR_W => 2*ADDR_DP_W, --long vectores direccionamiento
				DATA_W => DATA_DP_W)   --len of data
	port map(
		clk => clk, rst => rst_borrador,
		ena => vga_clear,
		addr_in => addr_porta_in,
		addr_out => addr_porta,
		we => we_borrador,
		data => din_porta,
		flag_fin => clear_fin_wire
	);
	
	we_aux <= dpr_tick_wire or we_borrador;
	
	dualport_ram: xilinx_dual_port_ram_sync
	generic map(ADDR_WIDTH => 2*ADDR_DP_W, DATA_WIDTH => DATA_DP_W)
	port map(
		clk => clk, we => we_aux, rst => rst,
		addr_a => addr_porta, addr_b => addr_portb,
		din_a => din_porta, dout_a => open, dout_b => dout_b_aux
	);
	
	
	ctrl_portb: controlador
	generic map (M => 10, N => ADDR_DP_W) --long de vectores pixel de vga_ctrl
		--long vectores direccionamiento
	port map(
		pixel_row => pxl_row_aux,
		pixel_col => pxl_col_aux,
		address => addr_portb --direcciones a port B dual port RAM
	);
	
	vga: vga_ctrl
    port map(
		mclk => clk, red_i => dout_b_aux(0), grn_i => dout_b_aux(0), blu_i => dout_b_aux(0),
		hs => hs_aux, vs => vs_aux, red_o => red_o, grn_o => grn_o,
		blu_o => blu_aux, pixel_row => pxl_row_aux, pixel_col => pxl_col_aux
	);
	
	ctrl_7seg_inst: ctrl_7seg
	port map(
		clk => clk, rst => rst,
		gral_ctrl_state => gral_ctrl_state,
		uart2sram_state => uart2sram_state,
		sram2cordic_state => sram2cordic_state,
		rotador3d_state => rotador3d_state,
		sal_7seg => sal_7seg_wire
	);
		
	
 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                               Salidas                                   |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+
	-- a VGA ----------------------------------- 
	-- red_o <= red_o(vga_ctrl)
	-- grn_o <= red_o(vga_ctrl)
	blu_o <= blu_aux; ---CAMBIAR
	hs <= hs_aux;
	vs <= vs_aux;
 	-- a SRAM externa --------------------------
	adv <= '0';
	mt_clk <= '0';
	mt_cre <= '0';
	-- a testbench (para simulación)
	tick_dpr <= dpr_tick_wire;
	pxl_x	<= addr_porta_in(ADDR_DP_W*2-1 downto ADDR_DP_W);
	pxl_y <= addr_porta_in(ADDR_DP_W-1 downto 0);
	-- a 7 segmentos
	sal_7seg <= sal_7seg_wire;
	
	-- we_n, oe_n <= (sram_ctrl);
	-- ce_n, ub_n, lb_n <= ce_a_n, ub_a_n, lb_a_n (sram_ctrl);
	-- address_sram <= ad (sram_ctrl);
	-- dio_sram <= dio_a (sram_ctrl);
	
end;
