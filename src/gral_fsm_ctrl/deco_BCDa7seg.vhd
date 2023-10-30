-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity deco_BCDa7seg is
	port(
	inBCD : in std_logic_vector (3 downto 0);
	segm : out std_logic_vector (7 downto 0)
	);
end;
--segm(0)= a, segm(1) = b ...., segm(7) = dp

architecture deco_BCDa7seg_arq of deco_BCDa7seg is
	
begin 

	process (inBCD)
	begin
		deco : case inBCD is 
			   when "0000" =>  segm <= "00000011"; --0
			   when "0001" =>  segm <= "10011111"; --1	
			   when "0010" =>  segm <= "00100101"; --2
			   when "0011" =>  segm <= "00001101"; --3
			   when "0100" =>  segm <= "10011001"; --4
			   when "0101" =>  segm <= "01001001"; --5
			   when "0110" =>  segm <= "01000001"; --6
			   when "0111" =>  segm <= "00011111"; --7
			   when "1000" =>  segm <= "00000001"; --8
			   when "1001" =>  segm <= "00011001"; --9
			   
			  when others => segm <= "11111111";
		end case deco;
	end process;
	
end;