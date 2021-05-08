-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad

--el módulo de la salida es 1,64^2 = 2,7 Y debe estar normalizado a 160
	--multiplico entonces por 160/2,7 = 59.5 aprox = []
	
	signal x_aux, y_aux: std_logic_vector(N+6 downto 0);
	
	x_aux <= std_logic_vector(to_signed((to_integer(signed(x3_aux))) * 119,N+7));
	y_aux <= std_logic_vector(to_signed((to_integer(signed(y3_aux))) * 119,N+7));