-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--este modulo lee los datos de la memoria externa y almacena el dato en un registro.
--luego genera la señal de control para el cordic_3D
--'ena' habilita el registro y cambia el puntero en la memoria externa.
	--			       _
	-- ena  __________| |_______ entrada: señal de finalizacion de rotacion cordic 3D
	--                    				  pone datos de memoria actual a la salida.
	--					 _
	-- ctrl_aux	________| |_____ señal de habilitacion nueva dir de memoria externa
	--							 para apuntar a los proximos datos a rotar.
	--				____   _____ 
	-- ctrl_cordic3D    |_|  	 señal para comenzar nueva rotación	


entity lector_datos is
	generic(N: integer := 14; 	--longitud del dato 
			R: integer := 12);	--longitud del puntero
	port(
	x_in, y_in, z_in: in std_logic_vector(N-1 downto 0);
	clk, rst, ena: in std_logic;
	puntero: out std_logic_vector(R-1 downto 0);
	x_out, y_out, z_out: out std_logic_vector(N-1 downto 0);
	ctrl_cordic3D: out std_logic
	);
end;

architecture lector_datos_arq of lector_datos is

	constant L: integer:= 3*N; --es el salto que se va a mover el puntero.
	
	component registro is
	generic(N: natural := 4);
	port(
		D: in std_logic_vector(N-1 downto 0);
		clk: in std_logic;
		rst: in std_logic;
		ena: in std_logic;		
		Q: out std_logic_vector(N-1 downto 0)
	);
	end component;
	
	component ffd is
    port(
          D: in std_logic;
          clk: in std_logic;			-- señal de reloj
          rst: in std_logic;			-- señal de reset
          ena: in std_logic;		-- señal de habilitación
          Q: out std_logic
	);
	end component;
	

	--señales
	
	signal xout_aux, yout_aux, zout_aux: std_logic_vector(N-1 downto 0);
	signal puntero_actual, puntero_ant: std_logic_vector(R-1 downto 0):= (others => '0');
	signal ctrl, ctrl_aux: std_logic;
	
	begin
	
	--Registros
	--=============================================
	
	reg_x: registro generic map(N => N) port map(x_in, clk, rst, ena, xout_aux);
	reg_y: registro generic map(N => N) port map(y_in, clk, rst, ena, yout_aux);
	reg_z: registro generic map(N => N) port map(z_in, clk, rst, ena, zout_aux);
	
	--Genero las señales para cambiar puntero y 'ctrl_cordic3D'.
	--========================================================
	
	--genero un retardo de 1 ciclo para el 'ctrl_cordic3D'.
	delay: ffd port map(ena, clk, rst, '1', ctrl);	
	
	gen_puntero: process(ctrl, ctrl_aux, puntero_actual, puntero_ant, rst, clk)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				puntero_actual <= (others => '0');
				puntero_ant <= (others => '0');
				ctrl_aux <= '1';
			elsif (ctrl = '1') then 
				--cuando termina rot actual apunta a un nuevo vector
				puntero_actual <= std_logic_vector(unsigned(puntero_ant) + L);
				ctrl_aux <= '0';
			else
				puntero_ant <= puntero_actual;
				ctrl_aux <= '0';
			end if;
		end if;
	end process;
	
	
	--Salidas
	
	puntero <= puntero_actual;
	x_out <= xout_aux;
	y_out <= yout_aux;
	z_out <= zout_aux;
	ctrl_cordic3D <= ctrl nor ctrl_aux;
	
end;