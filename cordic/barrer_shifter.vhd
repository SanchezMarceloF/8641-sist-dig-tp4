-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity barrer_shifter is
    generic (N: integer := 17);
    port(
		ent: in std_logic_vector(N-1 downto 0);
		shift: in std_logic_vector(3 Downto 0);
		ctrl: in std_logic_vector(1 downto 0); --ctrl(0) = {0 shift derecha,1 shift izquierda}
		sal: out std_logic_vector(N-1 downto 0)--ctrl(1) = {0 relleno con 0's, 1 relleno con 1's}
		);
end;


--cuerpo de arquitectura

architecture estruc of barrer_shifter is
    
	component mux is
	generic(N :integer:= 17);
    port (
        A_0: in std_logic_vector(N-1 downto 0);
        A_1: in std_logic_vector(N-1 downto 0);
		sel: in std_logic;
		sal: out std_logic_vector(N-1 downto 0) 
		);
     end component;
    
	
	signal sal_aux, sal1_aux, sal2_aux, sal3_aux: std_logic_vector(N-1 downto 0);
	signal A1_mux_0, A1_mux_1, A1_mux_2, A1_mux_3: std_logic_vector(N-1 downto 0);
begin    
	
	-- A1_mux_4 <= "0000000000000000" & ent(N-1 downto 16) when ctrl = "00" else
				-- ent(N-17 downto 0) & "0000000000000000" when ctrl = "01" else
				-- "1111111111111111" & ent(N-1 downto 16) when ctrl = "10" else
				-- ent(N-17 downto 0) & "1111111111111111";
	A1_mux_3 <= "00000000" & ent(N-1 downto 8) when ctrl = "00" else
				ent(N-9 downto 0) & "00000000"	when ctrl = "01" else
				"11111111" & ent(N-1 downto 8) when ctrl = "10" else
				ent(N-9 downto 0) & "11111111";
	A1_mux_2 <= "0000" & sal3_aux(N-1 downto 4) when ctrl = "00" else
				sal3_aux(N-5 downto 0) & "0000" when ctrl = "01" else
				"1111" & sal3_aux(N-1 downto 4) when ctrl = "10" else
				sal3_aux(N-5 downto 0) & "1111";
	A1_mux_1 <= "00" & sal2_aux(N-1 downto 2) when ctrl = "00" else
				sal2_aux(N-3 downto 0) & "00" when ctrl = "01" else
				"11" & sal2_aux(N-1 downto 2) when ctrl = "10" else
				sal2_aux(N-3 downto 0) & "11";
	A1_mux_0 <= "0" & sal1_aux(N-1 downto 1) when ctrl = "00" else
				sal1_aux(N-2 downto 0) & "0" when ctrl = "01" else
				"1" & sal1_aux(N-1 downto 1) when ctrl = "10" else
				sal1_aux(N-2 downto 0) & "1";
	
	--mux_4: mux  generic map(N => N) port map(ent		, A1_mux_4, shift(4), sal4_aux);
	mux_3: mux	generic map(N => N) port map(ent, A1_mux_3, shift(3), sal3_aux);
	mux_2: mux	generic map(N => N) port map(sal3_aux, A1_mux_2, shift(2), sal2_aux);
	mux_1: mux	generic map(N => N) port map(sal2_aux, A1_mux_1, shift(1), sal1_aux);
	mux_0: mux	generic map(N => N) port map(sal1_aux, A1_mux_0, shift(0), sal_aux);

	sal <= sal_aux;
	
end;