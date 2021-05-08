-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--genera un angulo de longitud M con 2 pulsadores ("up", "down")
--se suma o resta el angulo "PHI" predefinido 
--con ena = 1 y flanco ascendente del clk. 


entity updown_counter is
	generic(M:	integer := 15); --longitud del angulo
	port(
	pulsadores: in std_logic_vector(1 downto 0);
	clk, rst, ena: in std_logic;
	count: out std_logic_vector(M-1 downto 0)
	);
end;

--cuerpo de arquitectura

architecture updown_counter_arq of updown_counter is
	-- declaracion de componente, senales, etc
	
	constant PHI: std_logic_vector(M-1 downto 0):= "000000010110100";
	constant PHI_NEG: std_logic_vector(M-1 downto 0):= "111111101001100";
	constant CERO: std_logic_vector(M-1 downto 0):= (others => '0');
	
	component mux2 is
		generic(N :integer:= 23);
		 port (
			A_0, A_1, A_2, A_3: in std_logic_vector(N-1 downto 0);
			sel: in std_logic_vector(1 downto 0);
			sal: out std_logic_vector(N-1 downto 0) --(5 downto 0)
	);
	end component;
	
	component registro is
		generic(N: integer:= 4);
		port(
			D: in std_logic_vector(N-1 downto 0);
			clk, rst, ena: in std_logic;
			Q: out std_logic_vector(N-1 downto 0)
		 );
	end component;
	
	
	signal D_aux, Q_aux, sal_mux: std_logic_vector(M-1 downto 0);--:= (others => '0');
	
	
begin

	--Q_aux <= (others => '0');
	--D_aux <= (others => '0');	
	
	a: mux2
		generic map(N => M)
		port map(
			A_0 => CERO,
			A_1 => PHI_NEG,
			A_2 => PHI,
			A_3 => CERO,
			sel => pulsadores,
			sal => sal_mux
	);
	
	D_aux <= std_logic_vector(unsigned(sal_mux) + unsigned(Q_aux));
	
	b: registro	generic map(N => M)	port map(D_aux, clk, rst, ena, Q_aux);
	
--- Salidas ---
	
	count <= Q_aux;
	
end;