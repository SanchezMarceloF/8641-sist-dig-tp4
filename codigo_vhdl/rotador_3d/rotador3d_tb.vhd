-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity rotador3d_tb is
	generic(N: integer:= 13; --long coordenadas x y z
			M: integer:= 15; --long angulos de rotacion
			R: natural := 10; --long direcciones a memoria ROM externa
			L: integer := 9); --long direcciones a dual port RAM
	end;

-- cuerpo de arquitectura
architecture rotador3d_tb_arq of rotador3d_tb is
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
	
	--señales tb
	signal clk_tb, ena_tb, rst_tb: std_logic := '0';
	--señales para rotador 3D
	signal x0_tb: std_logic_vector(N-1 downto 0):= "1110011111001";
	signal y0_tb: std_logic_vector(N-1 downto 0):= "1110010000101";
	signal z0_tb: std_logic_vector(N-1 downto 0):= "0011010001001";
	signal pulsadores_tb: std_logic_vector(5 downto 0);
	signal xn_tb, yn_tb, zn_tb: std_logic_vector(N-1 downto 0);
	signal addr_tb: std_logic_vector(R-1 downto 0);	
	--señales para generador_direcciones
	signal Addrx_tb, Addry_tb: std_logic_vector(L-1 downto 0);
	--señales para controlador
	signal pxl_col_tb, pxl_row_tb: std_logic_vector(R-1 downto 0);
	signal address_tb: std_logic_vector(2*L-1 downto 0);
	--señales auxiliares
	signal flag_fin_aux: std_logic;
	
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 

	pulsadores_tb <= "010010";
	ena_tb <= '1';
	rst_tb <= '1' after 20 ns, '0' after 100 ns;
	
	
	DUT: rotador3d
	generic map(N => N, M => M)
	port map(
		x_0 => x0_tb, y_0 => y0_tb, z_0 => z0_tb,
		pulsadores => pulsadores_tb,
		rst => rst_tb, ena => ena_tb, clk => clk_tb,
		x_n => xn_tb, y_n => yn_tb, z_n => zn_tb,
		addr => addr_tb, --direccionamiento memoria ROM externa
		flag_fin => flag_fin_aux
	);
	
	DUT2: generador_direcciones
	generic map(N => N, L => L)	--longitud de las direcciones
	port map(
		--flag: in std_logic;	--me avisa cuando termina de rotar.
		x => xn_tb, y => yn_tb,
		Addrx => Addrx_tb, Addry => Addry_tb --direcciones a port A dual port RAM
	);
	
	vga: vga_ctrl
    port map(mclk => clk_tb, red_i => '1', grn_i => '1', blu_i => '1',
		hs => open, vs => open, red_o => open, grn_o => open, blu_o => open,
		pixel_row => pxl_row_tb, pixel_col => pxl_col_tb
	);
	
	ctrl_portb: controlador
	generic map (M => 10, N => L) --long de vectores pixel de vga_ctrl
		--long vectores direccionamiento
	port map(
		pixel_row => pxl_row_tb,
		pixel_col => pxl_col_tb,
		address => address_tb --direcciones a port B dual port RAM
	);
	
end;