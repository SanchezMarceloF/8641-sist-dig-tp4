library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
   
entity contador_clock is
	generic (
		N: natural := 10); ---ciclos a contar
	port(
		clk, rst: in std_logic;
		flag_fin: out std_logic
	);
end;

architecture contador_clock_arq of contador_clock is

signal flag_aux: std_logic;
    
begin

	aaa: process(clk, rst)
		variable count: integer := 0;
	begin
		if rising_edge(clk) then
			if rst = '1' or count = N+1 then
				count := 0;
				flag_aux <= '0';
			else
				count := count + 1;
				if count = N then --or count = N+1 then
					flag_aux <= '1';
				else
					flag_aux <= '0';
				end if;
			end if;
		end if;
	end process;

flag_fin <= flag_aux;

end;