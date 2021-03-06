-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- la entrada X_0 = x0,y0,z0 se ingresa en formato comlemento al modulo con punto fijo 2 enteros, el resto decimales
-- alfa, beta, gamma son los angulos a rotar de los ejes x ,y ,z respectivamente.
-- la salida xn,yn,zn sale con mismo módulo que la entrada.
--'ctrl' on/off del rotador.
--'flag_rot' se pone en "1" (pulso) cuando termina de rotar.

-- declaracion de entidad

entity cordic3d is
	generic(N: natural := 13;
			M: natural := 15);
	port(
		x_0, y_0, z_0: in std_logic_vector(N-1 downto 0);
		alfa, beta, gama: in std_logic_vector(M-1 downto 0);
		ctrl: in std_logic;		--'0' => x_0; '1' => x_i (comienza a rotar)
		clk: in std_logic;
		x_n, y_n, z_n: out std_logic_vector(N-1 downto 0);
		flag_rot: out std_logic	
		);
end;

--declaracion de arquitectura

architecture cordic3d_arq of cordic3d is
		
	component cordic is
		generic(N: natural := 12;
				M: natural := 13); --M: cantidad de digitos del angulo
		port(
			x_0, y_0: in std_logic_vector(N-1 downto 0);
			phi_0: in std_logic_vector(M-1 downto 0); --angulo a rotar 
			ctrl: in std_logic;		--'0' => x_0; '1' => x_i 
			clk: in std_logic;
			x_n, y_n: out std_logic_vector(N-1 downto 0);
			phi_n: out std_logic_vector(M-1 downto 0);
			flag: out std_logic
		);
	end component;
	
	component detect_flanco is
	port(
		clk, rst: in std_logic; 
		secuencia: in std_logic;
		salida: out std_logic
		);
	end component;
	
	--señales 
	
	signal x1_aux, x2_aux, x3_aux: std_logic_vector(N-1 downto 0);
	signal y1_aux, y2_aux, y3_aux: std_logic_vector(N-1 downto 0);
	signal ctrl_2, ctrl_3, flag_aux, pulso: std_logic;
	
		
begin

	rx: cordic
		generic map(N => N,	M => M)
		port map(
			x_0 => y_0,
			y_0 => Z_0,
			phi_0 => alfa,
			ctrl => ctrl,
			clk => clk,
			x_n => x1_aux,
			y_n => y1_aux,
			phi_n => open,
			flag => ctrl_2	--flag queda fijo en '1' cuando termina rx
							--y habilita la rotación de ry con ctrl_2
	);
	
	
	ry: cordic
		generic map(N => N, M => M)
		port map(
			x_0 => y1_aux,
			y_0 => x_0,
			phi_0 => beta,
			ctrl => ctrl_2,
			clk => clk,
			x_n => x2_aux,
			y_n => y2_aux,
			phi_n => open,
			flag => ctrl_3	--flag queda fijo en '1' cuando termina ry
							--y habilita la rotación de rz con ctrl_3
	);
	
	
	rz: cordic
		generic map (N => N, M=>M)
		port map(
			x_0 => y2_aux,
			y_0 => x1_aux,
			phi_0 => gama,
			ctrl => ctrl_3,
			clk => clk,
			x_n => x3_aux,
			y_n => y3_aux,
			phi_n => open,
			flag => flag_aux
	);
	
	--genero pulso para controlar el lector de datos
	--y actualizacion del registro de salida
	
	gen_ctrl: detect_flanco	port map(clk, '0', flag_aux, pulso);
	
	--Salidas
		
	x_n <= x3_aux;
	y_n <= y3_aux;
	z_n	<= x2_aux;
	flag_rot <= pulso;
	
end;
