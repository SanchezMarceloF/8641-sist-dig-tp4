-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--calcula el angulo de rotacion para cada coordenada


entity rotacion_ctrl is
	generic(M: integer := 15; 	--longitud del angulo a rotar
			N: integer := 13);	--longitud del dato a rotar
	port(
	clk, rst, ena: in std_logic;
	sel: in std_logic_vector(5 downto 0);
	alfa, beta, gamma: out std_logic_vector(M-1 downto 0)
	);
end;

--cuerpo de arquitectura
architecture rotacion_ctrl_arq of rotacion_ctrl is
	
	component updown_counter is
		generic(M:	natural := 15); --longitud del angulo
		port(
			pulsadores: in std_logic_vector(1 downto 0);
			clk, rst, ena: in std_logic;
			count: out std_logic_vector(M-1 downto 0)
			);
	end component;
	
--Señales
	
signal ctrl_out: std_logic;
signal alfa_aux, beta_aux, gamma_aux: std_logic_vector(M-1 downto 0);
signal sel_alfa, sel_beta, sel_gamma: std_logic_vector(1 downto 0);



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
		ena => ena,
		count => alfa_aux
	);
	
	
	count_beta: updown_counter
	generic map(M => M)
	port map(
		pulsadores => sel_beta,
		clk => clk,
		rst => rst,
		ena => ena,
		count => beta_aux
	);
	
	count_gamma: updown_counter
	generic map(M => M)
	port map(
		pulsadores => sel_gamma,
		clk => clk,
		rst => rst,
		ena => ena,
		count => gamma_aux
	);
	
	--Salidas
	
	alfa <= alfa_aux;
	beta <= beta_aux;
	gamma <= gamma_aux;
	
end;
	