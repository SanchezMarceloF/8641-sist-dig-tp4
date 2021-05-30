-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity contador is
	generic(L: integer:= 12); --L para definir la cantidad de corrimientos a realizar
	port(
		clk: in std_logic;
		rst: in std_logic;
		ena: in std_logic;
		count: out std_logic_vector(3 downto 0);
		flag: out std_logic
	);
end;

-- cuerpo de arquitectura
architecture contador_arq of contador is
	-- declaracion de componente, senales, etc
	
	component registro is
		generic(N: natural := 4);
		port(
			clk: in std_logic;
			rst: in std_logic;
			ena: in std_logic;
			D: in std_logic_vector(N-1 downto 0);
			Q: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	signal sal_or, sal_comp, ena_aux, flag_aux: std_logic;
	signal count_aux, sal_sum: std_logic_vector(3 downto 0);
begin
	--sal_or <= ena or sal_comp;
	
	reg_ins: registro
		port map(
			clk => clk,
			rst => rst,
			ena => ena_aux,
			D => sal_sum,
			Q => count_aux
	);
	
	sal_sum <= std_logic_vector(unsigned(count_aux) + 1);
	flag_aux <= '0' when to_integer(unsigned(count_aux)) < (L-1) else '1';
	ena_aux <= ena and not flag_aux;
	
	count <= count_aux;
	flag <= flag_aux;
	
end;