-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Este bloque Cordic recibe un vector de 2 componentes en complemento al modulo
--y lo rota un angulo phi que entra también con el mismo formato
--El vector a la salida sale con el mismo módulo de la entrada.

-- declaracion de entidad
entity cordic is
	generic(N: natural := 13;	--longitud de los vectores a rotar
			M: natural := 15); 	--longitud del angulo
	port(
		x_0, y_0: in std_logic_vector(N-1 downto 0);
		phi_0: in std_logic_vector(M-1 downto 0); --angulo a rotar 
		ctrl: in std_logic;		--'0' => x_0; '1' => x_i 
		clk: in std_logic;
		x_n, y_n: out std_logic_vector(N-1 downto 0);
		phi_n: out std_logic_vector(M-1 downto 0);
		flag: out std_logic
	);
end;

architecture cordic_arq of cordic is

	--constant ANG_CERO: std_logic_vector(M-1 downto 0):=(others => '0');
	
	component mux is
		generic(N :integer:= 17);
		port (
			A_0: in std_logic_vector(N-1 downto 0);
			A_1: in std_logic_vector(N-1 downto 0);
			sel: in std_logic;
			sal: out std_logic_vector(N-1 downto 0) 
		);
	end component;
	
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
	
	component sumador is
		generic(N: integer:= 4);
		port(
			A: in std_logic_vector(N-1 downto 0);
			B: in std_logic_vector(N-1 downto 0);
			ctrl: in std_logic;
			Cin: in std_logic;
			Sal: out std_logic_vector(N-1 downto 0);
			Cout: out std_logic
		);
    end component;
	
	component barrer_shifter is
		generic (N: integer := 17);
		port(
			ent: in std_logic_vector(N-1 downto 0);
			shift: in std_logic_vector(3 Downto 0);
			ctrl: in std_logic_vector(1 downto 0); 
			--ctrl(0) = {0 shift derecha,1 shift izquierda}
			--ctrl(1) = {0 relleno con 0's, 1 relleno con 1's}
			sal: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	component acumulador_ang is
		generic(N: integer:= 15);
	port(
		phi_0: in std_logic_vector(N-1 downto 0);
		count: in std_logic_vector(3 downto 0);
		clk: in std_logic;
		ctrl: in std_logic;		--'0' => phi_0; '1' => z_i
		di: out std_logic;
		phi_n: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	
	--declaracion de señales
	
	signal A1_up, sal_mux_up, xn_bef, sal_shift_up: std_logic_vector(N-1 downto 0);
	signal A1_down, sal_mux_down, yn_bef, sal_shift_down: std_logic_vector(N-1 downto 0);
	signal sal_count: std_logic_vector(3 downto 0);
	signal ctrlbrr_up, ctrlbrr_d: std_logic_vector(1 downto 0);
	signal ctrl_aux, di_up, di_down, flag_aux, flag_angulo: std_logic;
	signal zn_aux: std_logic_vector(M-1 downto 0);
	signal yn_aux1, xn_aux1: std_logic_vector(N+5 downto 0);
	signal yn_aux2, xn_aux2: std_logic_vector(N-1 downto 0);
	
begin
	
--Bloque superior
--=======================================================
	
	mux_up: mux
		generic map(N => N)
		port map(
			A_0 => x_0,
			A_1 => A1_up,
			sel => ctrl,
			sal => sal_mux_up
	);
	
	reg_up: registro
		generic map(N => N)
		port map(
			D => sal_mux_up,
			clk => clk,
			rst => '0',
			ena => '1',
			Q => xn_bef
	);
	
	ctrlbrr_up <= yn_bef(N-1) & "0";
	
	shift_up: barrer_shifter
		generic map(N => N)
		port map(
			ent => yn_bef,
			shift => sal_count,
			ctrl => ctrlbrr_up,
			sal => sal_shift_up 
	);
	
	di_down <= not di_up;
	
	sum_up: sumador
		generic map(N => N)
		port map(
			A => xn_bef,
			B => sal_shift_up, 
			ctrl => di_up,
			Cin => '0',
			Sal => A1_up,
			Cout => open
    );
	
	ctrl_aux <= not ctrl;
	
	cont: contador
		generic map (L => N)
		port map(
			clk => clk,
			rst => ctrl_aux,
			ena => ctrl,
			count => sal_count,
			flag => flag_aux
	);
	
--Bloque inferior	
	
	sum_down: sumador
		generic map(N => N)
		port map(
			A => yn_bef,
			B => sal_shift_down, 
			ctrl => di_down,
			Cin => '0',
			Sal => A1_down,
			Cout => Open
    );
	

	ctrlbrr_d <= xn_bef(N-1) & "0";
	
	shift_down: barrer_shifter
		generic map(N => N)
		port map(
			ent => xn_bef,
			shift => sal_count,
			ctrl => ctrlbrr_d,
			sal => sal_shift_down 
	);
	
	reg_down: registro
		generic map(N => N)
		port map(
			D => sal_mux_down,
			clk => clk,
			rst => '0',
			ena => '1',
			Q => yn_bef
	);
	
	mux_down: mux
		generic map(N => N)
		port map(
			A_0 => y_0,
			A_1 => A1_down,
			sel => ctrl,
			sal => sal_mux_down
	);
	
	--Acumulador angular
	--============================================================
	
	acum: acumulador_ang
		generic map(N => M)
		port map(
			phi_0 => phi_0,
			count => sal_count,
			clk => clk,
			ctrl => ctrl,
			di => di_up,
			phi_n => zn_aux
	);
	
	--Escalamiento
	--============================================================
	
	--se divide el vector por 1,64102564=[64/39] (aprox ganancia del Cordic)
	--así se igualan los módulos para poder rotar en la siguiente etapa.
	xn_aux1 <= std_logic_vector(to_signed(to_integer(signed(A1_up)) * 39, N+6));
	yn_aux1 <= std_logic_vector(to_signed(to_integer(signed(A1_down)) * 39, N+6));
	
	
	--Para ángulo nulo salida igual a la entrada
		
	check_angulo: process(phi_0, xn_aux2, x_0, yn_aux2, y_0, xn_aux1, yn_aux1)
	begin		
		if (to_integer(unsigned(phi_0)) = 0) then 
			xn_aux2 <= x_0;
			yn_aux2 <= y_0;
		else
			xn_aux2 <= xn_aux1(N+5 downto 6);
			yn_aux2 <= yn_aux1(N+5 downto 6);
		end if;
	end process;

	--Salidas	
	
	x_n <= xn_aux2;
	y_n <= yn_aux2;
	phi_n <= zn_aux;
	flag <= flag_aux;
	
end;	
