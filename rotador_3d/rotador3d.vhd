-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- la entrada X_0 = x0,y0,z0 se ingresa en formato complemento al módulo
-- alfa, beta, gamma son los angulos a rotar de los ejes x ,y ,z respectivamente.
-- la salida xn,yn,zn sale con módulo 2.72*|X_0| aprox en el mismo formato
-- Para utilizarlo en pto fijo, Se deja 1 bit para el signo y 2 para los enteros,
-- los restantes para los decimales
--'ctrl' on/off del rotador.
--'flag_rot' se pone en "1" cuando termina de rotar.

-- declaracion de entidad

entity rotador3d is
	generic(N: natural := 13;	--longitud de los vectores
			M: natural := 15;	--longitud de los angulos
			R: natural := 10);	--tamaño del puntero a memoria ROM externa
	port(
		x_0, y_0, z_0: in std_logic_vector(N-1 downto 0);
		pulsadores: in std_logic_vector(5 downto 0);
		rst, ena, clk: in std_logic;
		x_n, y_n, z_n: out std_logic_vector(N-1 downto 0);
		addr: out std_logic_vector(R-1 downto 0);
		flag_fin: out std_logic
	);
end;

--declaracion de arquitectura

architecture rotador3d_arq of rotador3d is

	component lector_datos is
		generic(N: integer := 14; 	--longitud del dato 
				R: integer := 12);	--longitud del puntero a ROM
		port(
			x_in, y_in, z_in: in std_logic_vector(N-1 downto 0);
			clk, rst, ena: in std_logic;
			puntero: out std_logic_vector(R-1 downto 0);
			x_out, y_out, z_out: out std_logic_vector(N-1 downto 0);
			ctrl_cordic3D: out std_logic
	);
	end component;
	
	component ena_20mili is
		generic (
			N: natural := 1024	-- cantidad de ciclos a contar
		);
		port(
			clk: in std_logic;
			rst: in std_logic;
			ena: in std_logic;
			sal: out std_logic	--
			--out_2: out std_logic  --
	);
	end component;

	component rotacion_ctrl is
		generic(M: integer := 15; 	--longitud del angulo a rotar
				N: integer := 13);	--longitud del dato a rotar
		port(
			clk, rst, ena: in std_logic;
			sel: in std_logic_vector(5 downto 0);
			alfa, beta, gamma: out std_logic_vector(M-1 downto 0)
	);
	end component;
	
	component cordic3d is
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
	end component;
	
	component detect_flanco is
		port(
			clk, rst: in std_logic; 
			secuencia: in std_logic;
			salida: out std_logic
			);
	end component;
	
	--señales 
	
	signal x0_aux, y0_aux, z0_aux: std_logic_vector(N-1 downto 0);
	signal xn_aux, yn_aux, zn_aux: std_logic_vector(N-1 downto 0);
	signal alfa_aux, beta_aux, gamma_aux: std_logic_vector(M-1 downto 0);
	signal addr_aux :std_logic_vector(R-1 downto 0);
	signal ctrl_cordic, flag_fin_aux, ena_ang: std_logic:= '0';
	signal iniciar, ena_lector, ena_lector_aux, ena_rot: std_logic;

begin

	enable_ang: ena_20mili --habilita cada 20 ms el cambio de angulo
		generic map( N => 1024 )	-- cantidad de ciclos a contar
		port map(
			clk => clk, rst => rst, ena => ena,
			sal => ena_ang
	);
	

	ena_lector_aux <= flag_fin_aux and ena; --PONGO '1' PARA SIMULAR--
	--genero una señal para inicializar el lector de datos cuando reseteo
	ena_lect_ini: detect_flanco port map(clk, '0', rst, iniciar);
	ena_lector <= ena_lector_aux or iniciar;
	
	lector: lector_datos
		generic map(N => N, 	--longitud del dato 
				R => R)	--longitud del puntero
		port map(
			x_in => x_0 , y_in => y_0, z_in => z_0,
			clk => clk, rst => rst, ena => ena_lector,
			puntero => addr_aux, --direccionamiento memoria ROM externa
			x_out => x0_aux, y_out => y0_aux, z_out => z0_aux,
			ctrl_cordic3D => ctrl_cordic
	);
	
	ena_rot <= ena and ena_ang;
	
	ctrl_rot: rotacion_ctrl
		generic map(M => M, 	--longitud del angulo a rotar
				N => N) 	--longitud del dato a rotar
		port map(
			clk => clk, rst => rst, ena => ena_rot,
			sel => pulsadores,
			alfa => alfa_aux, beta => beta_aux, gamma => gamma_aux
	);
	
	rotador: cordic3d
		generic map(N => N,
					M => M)
		port map(
			x_0 => x0_aux, y_0 => y0_aux, z_0 => z0_aux,
			alfa => alfa_aux, beta => beta_aux, gama => gamma_aux,
			ctrl => ctrl_cordic,  clk => clk,	--'0' => X_0; '1' => X_i (comienza a rotar)
			x_n => xn_aux, y_n => yn_aux, z_n => zn_aux,
			flag_rot => flag_fin_aux
	);
	
	--Salidas
	addr <= addr_aux;
	x_n <= xn_aux;
	y_n <= yn_aux;
	z_n	<= zn_aux;
	flag_fin <= flag_fin_aux;

end;