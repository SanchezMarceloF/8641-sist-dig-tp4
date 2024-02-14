----------------------------------------------------------------------------------
-- Create Date: 18:42:51 26/10/2016 
-- Designer Name: Sanchez Marcelo
-- Module Name: controlador - Behavioral 
-- Project Name: algoritmo CORDIC
-- Target Devices: Spartan 3
-- Tool versions: v1.0
-- Description: Generación de puntero a DUAL PORT RAM
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity controlador is
	generic(
		M: integer:= 10; --long de vectores pixel de vga_ctrl
		N: integer:= 9 --long vectores direccionamiento
		--W: integer:= 8
	);
	port(
		pixel_row, pixel_col: in std_logic_vector(M-1 downto 0);
		address: out std_logic_vector(N*2 - 1 downto 0)
	);

end controlador;

architecture Behavioral of controlador is
	
	--posiciones limite de escritura en pantalla
	constant COLEFT: signed(M-1 downto 0):= to_signed(160,M); --(160,M)
	constant COLRIGHT: signed(M-1 downto 0):= to_signed(480,M); --(480,M)
	constant ROWSUP: signed(M-1 downto 0):= to_signed(80,M); --(80,M)
	constant ROWINF: signed(M-1 downto 0):= to_signed(400,M); --(400,M)
	
	
	--seniales
	signal address_aux: std_logic_vector(N*2-1 downto 0);
	
	
	--Bloque lógico para control de la RAM
-----------------------------------------------------------------------------------
	
begin
	
	ctrl_portb: process(pixel_row, pixel_col, address_aux)

	begin
		--if ((ROWSUP <= signed(pixel_row)) and (signed(pixel_row) <= ROWINF) and (COLEFT <= signed(pixel_col)) and (signed(pixel_col) <= COLRIGHT)) then
		if ((ROWSUP <= signed(pixel_row)) and (ROWINF >= signed(pixel_row)) and (COLEFT <= signed(pixel_col)) and (COLRIGHT >= signed(pixel_col))) then
			address_aux(N*2-1 downto N) <= std_logic_vector(signed(pixel_col(N-1 downto 0))-COLEFT(N-1 downto 0));
			address_aux(N-1 downto 0) <= std_logic_vector(signed(pixel_row(N-1 downto 0))-ROWSUP(N-1 downto 0));
		else
			address_aux <= (others=>'0');
		end if;
	end process;
	
	--Salidas
-------------------------------------------------------------	

	address <= address_aux;
	
	
end Behavioral;
