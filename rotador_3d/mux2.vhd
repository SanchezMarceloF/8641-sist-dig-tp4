-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity mux2 is
	generic(N :integer:= 23);
    port (
        A_0, A_1, A_2, A_3: in std_logic_vector(N-1 downto 0);
        sel: in std_logic_vector(1 downto 0);
		sal: out std_logic_vector(N-1 downto 0) --(5 downto 0)
		);
end;

architecture mux2_arq of mux2 is

signal sal_aux: std_logic_vector(N-1 downto 0);

begin
    process(A_0, A_1, A_2, A_3, sel, sal_aux)
    begin
        if (to_integer(unsigned(sel)) = 0) then
            sal_aux <= A_0;
		elsif (to_integer(unsigned(sel)) = 1) then
			sal_aux <= A_1;
		elsif (to_integer(unsigned(sel)) = 2) then
			sal_aux <= A_2;
		else
			sal_aux <= A_3;
		end if;
    end process;
	
	sal <= sal_aux;
	
end;