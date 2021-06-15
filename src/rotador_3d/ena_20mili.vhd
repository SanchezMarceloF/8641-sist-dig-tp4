library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ena_20mili is
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
end;

architecture ena_20mili_arq of ena_20mili is
begin
	aaa: process(clk, rst, ena)
		variable count: integer := 0;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				count := 0;
				sal <= '0';
				--out_2 <= '1';
			else
				count := count + 1;
				if count = N  then
					sal <= '1';
				--	out_2 <= '0';
					count := 0;
				else
					sal <= '0';
				--	out_2 <= '0';
				end if;
			end if;
		--else 
		--sal <= '0';
		end if;
	end process;
end;
