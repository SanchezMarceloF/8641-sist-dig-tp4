-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;

-- declaracion de entidad
entity registro is
	generic(N: natural := 4);
	port(
		D: in std_logic_vector(N-1 downto 0);
		clk, rst, ena: in std_logic;
		Q: out std_logic_vector(N-1 downto 0)
	);
end;

-- cuerpo de arquitectura
architecture registro_arq of registro is
	-- declaracion de componente, senales, etc
begin

	ffd_proc: process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Q <= (others => '0');
			elsif ena = '1' then
				Q <= D;
			end if;
		end if;
	end process;
	
end;