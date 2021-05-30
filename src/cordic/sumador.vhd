--Componente elemental sumador/restador
--ctrl: '0' => sumador; '1' => restador; 
--Se puede ingresar carry in. Calcula el carry out

--Diagrama en bloques
--			_____
--      A__|     \
--		   \ +/-  \____Sal
--		B__/      /  
--		   |_____/
--	Cin____|  |  |____Cout
--           ctrl

-- declaracion de librerias
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


-- declaracion de entidad
entity sumador is
    generic(N: integer:= 4);
    port(
        A: in std_logic_vector(N-1 downto 0);
        B: in std_logic_vector(N-1 downto 0);
		ctrl: in std_logic;
        Cin: in std_logic;
        Sal: out std_logic_vector(N-1 downto 0);
        Cout: out std_logic
    );
end;

-- cuerpo de arquitectura
architecture sum of sumador is
    -- declaración de una señal auxiliar
    signal Sal_aux: std_logic_vector(N+1 downto 0);
	signal B1: std_logic_vector(N-1 downto 0);
begin
	
	suma_resta: process(ctrl, B)
	begin
		if(ctrl = '0') then
			B1 <= B;
		else
			B1 <= std_logic_vector((unsigned(not B)) + 1); --complemento a 2 para restar
		end if;
	end process;
	
    Sal_aux <= std_logic_vector(unsigned('0' & A & Cin) + unsigned('0' & B1 & '1'));
    Sal <= Sal_aux(N downto 1);			
    Cout <= Sal_aux(N+1);				
	
end;