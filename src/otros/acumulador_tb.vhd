-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity acumulador_tb is
	generic(N: integer:= 15);
end;


-- cuerpo de arquitectura
architecture acumulador_tb_arq of acumulador_tb is
	-- declaracion de componente, senales, etc


	component contador is
		generic(L: integer:= 9); --L para definir la cantidad de corrimientos a realizar
		port(
			clk: in std_logic;
			rst: in std_logic;
			ena: in std_logic;
			count: out std_logic_vector(3 downto 0);
			flag: out std_logic
		);
	end component;
	
	component acumulador_ang is
		generic(N: integer:= 14);
		port(
			z_0: in std_logic_vector(N-1 downto 0);
			count: in std_logic_vector(3 downto 0);
			clk: in std_logic;
			ctrl: in std_logic;
			di: out std_logic;
			z_n: out std_logic_vector(N-1 downto 0)
			);
	end component;
	
	signal clk_tb: std_logic := '0';
	signal z_0_tb: std_logic_vector(N-1 downto 0):= "001010000000000";
	signal count_tb: std_logic_vector(3 downto 0);
	signal di_tb, ctrl_tb: std_logic:= '0';
	signal rst_tb: std_logic:= '1';
	signal z_n_tb: std_logic_vector(N-1 downto 0);
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	
	rst_tb <= '0' after 20 ns;--inicia el contador
	ctrl_tb <= '1' after 25 ns;--inicia la carga de la ROM
	
	
	-- --Rotación a izquierda	
	-- rst_tb <= '1' after 380 ns;--inicia el contador
	-- rst_tb <= '0' after 400 ns;
	-- ctrl_tb <= '0' after 400 ns;--inicia la carga de la ROM
	-- ctrl_tb <= '1' after 420 ns;
	
	
	count: contador
		generic map(L => N)
		port map(
			clk => clk_tb,
			rst => rst_tb,
			ena => '1',
			count => count_tb,
			flag => open
	);
	
	
	DUT: acumulador_ang
		generic map(N => N)
		port map(
			z_0 => z_0_tb,
			count => count_tb,
			clk => clk_tb,
			ctrl => ctrl_tb,
			di => di_tb,
			z_n => z_n_tb
	);

	
end;