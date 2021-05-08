 -- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Detecta un flanco positivo, genera un "flag" (un pulso positivo de duración 1 ciclo de máquina)
--en el clock siguiente al flanco.

--declaracion de entidad

entity detect_flanco is
	port(
		clk, rst: in std_logic; 
		secuencia: in std_logic;
		salida: out std_logic
		);
end;

architecture det_arq of detect_flanco is
    type tipo_estado is (A, B1, B2);
    signal estado_actual, estado_siguiente: tipo_estado;
	signal det_flag: std_logic;
begin

registros: process(clk, rst)
    begin
        if rst = '1' then
            estado_actual <= A;
        elsif rising_edge(clk) then
            estado_actual <= estado_siguiente;
        end if;
end process;

transiciones: process(estado_actual, secuencia)
	begin
    case estado_actual is
        when A =>
            --det_flag <= '0';
            if secuencia = '1' then
                estado_siguiente <= B1;
            else
                estado_siguiente <= A;
            end if;
			
		when B1 =>
			if secuencia = '0' then
				estado_siguiente <= A;
			else
				estado_siguiente <= B2;
			end if;

		when B2 =>
			if secuencia = '0' then
				estado_siguiente <= A;
			else
				estado_siguiente <= B2;
			end if;			
	end case;
	end process;	
   
    det_flag <= '1' when estado_actual = B1 else '0';

	salida <= det_flag;
end;  -- fin de la arquitectura