-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity cordic_tb is
	generic(VECT_W: integer:= 14;
			ANG_W: integer:= 15);
end;


-- cuerpo de arquitectura
architecture cordic_tb_arq of cordic_tb is
	-- declaracion de componente, senales, etc
	
	component cordic is
	generic(VECT_WIDE: natural := 13;	--longitud de los vectores a rotar
			ANG_WIDE: natural := 15); 	--longitud del angulo
	port(
		x_0, y_0: in std_logic_vector(VECT_WIDE-1 downto 0);
		phi_0: in std_logic_vector(ANG_WIDE-1 downto 0); --angulo a rotar 
		ctrl: in std_logic;		--'0' => x_0; '1' => x_i 
		clk: in std_logic;
		x_n, y_n: out std_logic_vector(VECT_WIDE-1 downto 0);
		phi_n: out std_logic_vector(ANG_WIDE-1 downto 0);
		flag: out std_logic
	);
	end component;
	
	signal clk_tb, flag_tb : std_logic := '0';
	signal x_0_tb: std_logic_vector(VECT_W-1 downto 0):= "00110101101011";
	signal y_0_tb: std_logic_vector(VECT_W-1 downto 0):= "00100010110111";
	signal phi_0_tb: std_logic_vector(ANG_W-1 downto 0):= "011111111111111";
	signal ctrl_tb: std_logic:= '0';
	signal rst_tb: std_logic:= '1';
	signal x_n_tb, y_n_tb: std_logic_vector(VECT_W-1 downto 0);
	signal phi_n_tb: std_logic_vector(ANG_W-1 downto 0);
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	
	rst_tb <= '0' after 20 ns;--inicia el contador
	ctrl_tb <= '1' after 123 ns;--inicia la carga de la ROM
	
	
	DUT: cordic
	generic map(VECT_WIDE => VECT_W,
				ANG_WIDE => ANG_W)
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