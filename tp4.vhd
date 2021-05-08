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
	generic(N: integer:= 13; --long coordenadas x, y, z.
			M: integer:= 15; --long angulos de rotacion
			R: natural:= 10; --long direcciones a memoria ROM externa
			L: integer:= 9); --long direcciones a dual port RAM
	port(
		clk, ena, rst: in std_logic;
		--pulsadores(5): alfa_up | (4): alfa_down | (3): beta_up
		--(2): beta_down | (1): gamma_up | (0): gamma_down	
		pulsadores: in std_logic_vector(5 downto 0);
		xin, yin, zin: in std_logic_vector(N-1 downto 0);
		addr_rom: out std_logic_vector(R-1 downto 0);
		data_out, hs, vs: out std_logic		
		);
end;

-- cuerpo de arquitectura
architecture tp4_arq of tp4 is
	-- declaracion de componente, senales, etc
	
	component rotador3d is
	generic(N: natural := 14;	--longitud de los vectores
			M: natural := 15;	--longitud de los angulos
			R: natural := 10);	--tamaño del puntero
	port(
		x_0, y_0, z_0: in std_logic_vector(N-1 downto 0);
		pulsadores: in std_logic_vector(5 downto 0);
		rst, ena, clk: in std_logic;
		x_n, y_n, z_n: out std_logic_vector(N-1 downto 0);
		addr: out std_logic_vector(R-1 downto 0); --direccionamiento memoria ROM externa
		flag_fin: out std_logic
	);
	end component;
	
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
		ADDR_WIDTH: integer:=18;
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
	
	constant DATA_WIDTH: natural:= 1;
	
	--señales de prueba
	
	--señales para rotador 3D
	signal xn_aux, yn_aux, zn_aux: std_logic_vector(N-1 downto 0);
	signal flag_fin_aux: std_logic;
	signal addr_rom_aux: std_logic_vector(R-1 downto 0);
	--señales para generador_direcciones
	signal Addrx_aux, Addry_aux: std_logic_vector(L-1 downto 0);
	--señales para la dual port ram
	signal we_aux: std_logic;
	signal din_porta, dout_b_aux: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal addr_porta, addr_portb: std_logic_vector(2*L-1 downto 0);
	--señales para controlador
	signal red_aux, grn_aux: std_logic_vector(2 downto 0);
	signal blu_aux: std_logic_vector(1 downto 0);
	signal vs_aux, hs_aux: std_logic;
	signal pxl_col_aux, pxl_row_aux: std_logic_vector(R-1 downto 0);
	
	
	
begin	

	rot3d: rotador3d
	generic map(N => N, M => M)
	port map(
		x_0 => xin, y_0 => yin, z_0 => zin,
		pulsadores => pulsadores,
		rst => rst, ena => ena, clk => clk,
		x_n => xn_aux, y_n => yn_aux, z_n => zn_aux,
		addr => addr_rom_aux, --direccionamiento memoria ROM externa
		flag_fin => flag_fin_aux
	);
	
	
	gen_dir: generador_direcciones
	generic map(N => N, L => L)	--longitud de las direcciones
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
	generic map( ADDR_WIDTH => 2*L, DATA_WIDTH => 1)
	port map(
		clk => clk, we => flag_fin_aux, rst =>rst,
		addr_a => addr_porta, addr_b => addr_portb,
		din_a => din_porta, dout_a => open, dout_b => dout_b_aux
	);
	
	
	ctrl_portb: controlador
	generic map (M => R, N => L) --long de vectores pixel de vga_ctrl
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
	
	addr_rom <= addr_rom_aux;
	data_out <= blu_aux(0); ---CAMBIAR
	hs <= hs_aux;
	vs <= vs_aux;
	
end;