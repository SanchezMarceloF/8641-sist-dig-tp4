library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ffd is
    port(
          D: in std_logic;
          clk: in std_logic;			-- señal de reloj
          rst: in std_logic;			-- señal de reset
          ena: in std_logic;		-- señal de habilitación
          Q: out std_logic
	);
end;

architecture ffd_arq of ffd is
begin
     process(clk, rst, ena, D)
     begin
          if rst = '1' then
               Q <= '0';
          elsif rising_edge(clk) then--clk = '1' and clk'event then
               if ena = '1' then
                    Q <= D;
               end if;
          end if;
     end process;
end;