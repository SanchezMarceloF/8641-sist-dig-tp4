-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity mux is
generic(N :integer:= 17);
port (
	A_0: in std_logic_vector(N-1 downto 0);
	A_1: in std_logic_vector(N-1 downto 0);
	sel: in std_logic;
	sal: out std_logic_vector(N-1 downto 0) 
	);
end;

architecture mux_arq of mux is

begin
    process(A_0, A_1, sel)
    begin
        if (sel = '0') then
            sal <= A_0;
		else
			sal <= A_1;
		end if;
    end process;
end;