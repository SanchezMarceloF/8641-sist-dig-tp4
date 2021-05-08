-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--este modulo mapea los botones de la FPGA 
--y calcula el angulo de rotacion para cada coordenada


entity comando_rotacion is
	generic(M: integer := 15; 	--longitud del angulo a rotar
			N: integer := 13;	--longitud del vector a rotar
			R: integer := 10);	--tamaño del puntero
	port(
	clk, rst, ena: in std_logic;
	sel: in std_logic_vector(5 downto 0);
	x_in, y_in, z_in: in std_logic_vector(N-1 downto 0)
	alfa, beta, gamma: out std_logic_vector(M-1 downto 0);
	x_out, y_out, z_out: out std_logic_vector(N-1 downto 0)
	);
end;

--cuerpo de arquitectura
architecture comando_rotacion_arq of comando_rotacion is
	
	component updown_counter is
		generic(M:	natural := 15); --longitud del angulo
		port(
			pulsadores: in std_logic_vector(1 downto 0);
			clk, rst, ena: in std_logic;
			count: out std_logic_vector(M-1 downto 0)
			);
	end component;
	
	component lector_datos is
	generic(N: integer := 14; 	--longitud del dato 
			R: integer := 12);	--longitud del puntero
		port(
			x_in, y_in, z_in: in std_logic_vector(N-1 downto 0);
			clk, rst, ena: in std_logic;
			puntero: out std_logic_vector(R-1 downto 0);
			x_out, y_out, z_out: out std_logic_vector(N-1 downto 0);
			ctrl_cordic3D: out std_logic
	);
	end component;

signal ena_20mili, ctrl_out: std_logic;
signal alfa_aux, beta_aux, gamma_aux: std_logic_vector(M-1 downto 0);
signal sel_alfa, sel_beta, sel_gamma: std_logic_vector(1 downto 0);
signal xout_aux, yout_aux, zout_aux: std_logic_vector(N-1 downto 0);
signal puntero_aux: std_logic_vector(R-1 downto 0);


begin

	
	sel_alfa <= sel(5 downto 4);
	sel_beta <= sel(3 downto 2);
	sel_gamma <= sel(1 downto 0);

	count_alfa: updown_counter
	generic map(M => M)
	port map(
		pulsadores => sel_alfa,
		clk => clk,
		rst => rst,
		ena => ena_20mili,
		count => alfa_aux
	);
		
	count_beta: updown_counter
	generic map(M => M)
	port map(
		pulsadores => sel_beta,
		clk => clk,
		rst => rst,
		ena => ena_20mili,
		count => beta_aux
	);
	
	count_gamma: updown_counter
	generic map(M => M)
	port map(
		pulsadores => sel_gamma,
		clk => clk,
		rst => rst,
		ena => ena_20mili,
		count => gamma_aux
	);
	
	lector: lector_datos
	generic map(N => N,		--longitud del dato 
				R => R)	--longitud del puntero
		port map(
			x_in => xin_aux, y_in => yin_aux, z_in => zin_aux,
			clk =>clk, rst=> rst, ena => ena,
			puntero => puntero_aux,
			x_out => xout_aux, y_out => yout_aux, z_out => zout_aux,
			ctrl_cordic3D => ctrl_out
	);
	
	--Salidas
	
	alfa <= alfa_aux;
	beta <= beta_aux;
	gamma <= gamma_aux;
	x_out <= xout_aux;
	y_out <= yout_aux;
	z_out <= zout_aux;	
	
end;
	