-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity cordic_tb is
	generic(N: integer:= 14;
			M: integer:= 15);
end;


-- cuerpo de arquitectura
architecture cordic_tb_arq of cordic_tb is
	-- declaracion de componente, senales, etc
	
	component cordic is
		generic(N: natural := 14;
				M: natural := 15); --M: cantidad de digitos del angulo
		port(
			x_0: in std_logic_vector(N-1 downto 0);
			y_0: in std_logic_vector(N-1 downto 0);
			phi_0: in std_logic_vector(M-1 downto 0); --angulo a rotar 
			ctrl: in std_logic;
			clk: in std_logic;
			x_n: out std_logic_vector(N-1 downto 0);
			y_n: out std_logic_vector(N-1 downto 0);
			phi_n: out std_logic_vector(M-1 downto 0);
			flag: out std_logic
		);
    end component;
	
	signal clk_tb, flag_tb : std_logic := '0';
	signal x_0_tb: std_logic_vector(N-1 downto 0):= "00111111111111";
	signal y_0_tb: std_logic_vector(N-1 downto 0):= "11000000000000";
	signal phi_0_tb: std_logic_vector(M-1 downto 0):= "000000000000000";
	signal ctrl_tb: std_logic:= '0';
	signal rst_tb: std_logic:= '1';
	signal x_n_tb, y_n_tb: std_logic_vector(N-1 downto 0);
	signal phi_n_tb: std_logic_vector(M-1 downto 0);
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	
	rst_tb <= '0' after 20 ns;--inicia el contador
	ctrl_tb <= '1' after 25 ns;--inicia la carga de la ROM
	
	
	DUT: cordic
	generic map(N => N)
	port map(
		x_0 => x_0_tb,
		y_0 => y_0_tb,
		phi_0 => phi_0_tb,
		ctrl => ctrl_tb,
		clk => clk_tb,
		x_n => x_n_tb,
		y_n => y_n_tb,
		phi_n => phi_n_tb,
		flag => flag_tb
	);
	
end;