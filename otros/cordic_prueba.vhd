-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;

-- declaracion de entidad
entity cordic is
	generic(N: natural := 12;
			M: natural := 13); --M: cantidad de digitos del angulo
	port(
		x_0: in std_logic_vector(N-1 downto 0);
		y_0: in std_logic_vector(N-1 downto 0);
		--z_0: in std_logic_vector(M-1 downto 0); --angulo a rotar 
		ctrl: in std_logic;
		clk: in std_logic;
		x_n: out std_logic_vector(N-1 downto 0);
		y_n: out std_logic_vector(N-1 downto 0)
		--z_n: out std_logic_vector(M-1 downto 0)
	);
end;

architecture cordic_arq of cordic is
	
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
			ctrl: in std_logic_vector(1 downto 0); --ctrl(0) = {0 shift derecha,1 shift izquierda}
			sal: out std_logic_vector(N-1 downto 0)--ctrl(1) = {0 relleno con 0's, 1 relleno con 1's}
		);
	end component;
	
	component acumulador_ang is
		generic(N: integer:= 13);
		port(
			z_0: in std_logic_vector(N-1 downto 0);
			count: in std_logic_vector(3 downto 0);
			clk: in std_logic;
			ctrl: in std_logic;
			sgn_zi: out std_logic;
			z_n: out std_logic_vector(N-1 downto 0)
			);
	end component;
	
	
	--declaracion de señales
	
	signal A1_up, sal_mux_up, xn_bef, sal_shift_up: std_logic_vector(N-1 downto 0);
	signal A1_down, sal_mux_down, yn_bef, sal_shift_down: std_logic_vector(N-1 downto 0);
	signal sal_count: std_logic_vector(3 downto 0);
	signal ctrl_aux, di_up, di_down: std_logic:= '0';
	--signal zn_aux: std_logic_vector(M-1 downto 0);

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
	
	shift_up: barrer_shifter
		generic map(N => N)
		port map(
			ent => yn_bef,
			shift => sal_count,
			ctrl => "00",
			sal => sal_shift_up 
	);
	
	di_up <= not di_down;
	
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
			ena => '1',
			count => sal_count,
			flag => open
	);
	
--Bloque inferior	
	
	sum_down: sumador
		generic map(N => N)
		port map(
			A => sal_shift_down,
			B => yn_bef, 
			ctrl => di_down,
			Cin => '0',
			Sal => A1_down,
			Cout => open
    );

	shift_down: barrer_shifter
		generic map(N => N)
		port map(
			ent => xn_bef,
			shift => sal_count,
			ctrl => "00",
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
	
	-- acum: acumulador_ang
		-- generic map(N => M)
		-- port map(
			-- z_0 => z_0,
			-- count => sal_count,
			-- clk => clk,
			-- ctrl => ctrl,
			-- sgn_zi => di_down, 
			-- z_n => zn_aux
	-- );
	
	
	--Salidas	
	
	x_n <= A1_up;
	y_n <= A1_down;
	--z_n <= zn_aux;
	
end;	