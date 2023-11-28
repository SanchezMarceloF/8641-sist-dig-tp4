-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use ieee.std_logic_arith;
--use ieee.std_logic_unsigned;


--Recibe 2 vectores de N bits en punto fijo
--normalizado en 2*13 = 8192 y lo escala a 320 y una
--longitud de 9 bits para las direcciones	

entity generador_direcciones is
	generic(N: integer := 16;	--longitud de los vectores
			L: integer := 9);	--longitud de las direcciones
	port(
		--flag: in std_logic;	--me avisa cuando termina de rotar.
		x, y: in std_logic_vector(N-1 downto 0);
		Addrx, Addry: out std_logic_vector(L-1 downto 0)
		--grabar: out std_logic
	);
end;

--cuerpo de arquitectura

architecture generador_direcciones_arq of generador_direcciones is

	--Para escalar el vector normalizado en 2048 a 320 necesito
	--dividir por 25,6 = 128/5. Es lo mismo que multiplicar por 5
	--y luego dividir por 128 (ó descartar los 7 bits menos
	--sinificativos del multiplicador)
	
	constant M: integer:= 2*N; --tamanio vector multiplicacion
	constant BIAS: std_logic_vector(L-1 downto 0):= std_logic_vector(to_signed(160,L));
	--constant SUMY: std_logic_vector(L-1 downto 0):= "010100010"; --162
	constant VAL_MULT: integer := 5;
	--constant CERO: std_logic:= '0';
	
	component sumador is
    generic(N: integer:= 4);
    port(
        A: in std_logic_vector(N-1 downto 0);
        B: in std_logic_vector(N-1 downto 0);
		ctrl: in std_logic;
        Cin: in std_logic;
        Sal: out std_logic_vector(N-1 downto 0);
        Cout: out std_logic
    );
	end component;
	
	--señales
	
	signal sal_multx, sal_multy: std_logic_vector(M-1 downto 0);
	signal x_mul, y_mul, addrx_aux, addry_aux: std_logic_vector(L-1 downto 0);
	
	
begin

	sal_multx <= std_logic_vector (signed(x)*to_signed(VAL_MULT,N)); --multiplico por 5
	sal_multy <= std_logic_vector (signed(y)*to_signed(VAL_MULT,N));

	x_mul <= sal_multx(L+6 downto 7); --division por 128
	y_mul <= sal_multy(L+6 downto 7); --division por 128

	--sumo 160 para eliminar los numeros negativos.
	xsum: sumador generic map (L) port map(x_mul, BIAS, '0', '0', addrx_aux, open);
	ysum: sumador generic map (L) port map(BIAS, y_mul, '1', '0', addry_aux, open);

	--Salidas

	Addrx <= addrx_aux;
	Addry <= addry_aux;

end;
