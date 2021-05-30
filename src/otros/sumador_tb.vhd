-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity sumador_tb is
	generic(N: integer:= 4);
end;


-- cuerpo de arquitectura
architecture sumador_tb_arq of sumador_tb is
	-- declaracion de componente, senales, etc
	
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
	
	signal clk_tb: std_logic :=  '0';
	signal A_tb: std_logic_vector(N-1 downto 0) := "1111";
	signal B_tb: std_logic_vector(N-1 downto 0) := "1111";
	signal ctrl_tb: std_logic := '0';
	signal sal_tb: std_logic_vector(N-1 downto 0);
	signal Cin_tb, Cout_tb: std_logic;
	
begin
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	ctrl_tb <= '1' after 50 ns;
	--ena_tb <= '0' after 800 ns, '1' after 1000 ns;
	
	DUT:sumador -- DUT es una etiqueta Device under test. Podria decir cualquier cosa la etiqueta, nosotros elegimos esas siglas.
	generic map(N => N)
	port map(
		A => A_tb,
		B => B_tb,
		ctrl => ctrl_tb,
		Cin => '0',
		Sal => sal_tb,
		Cout => Cout_tb
	);
	
end;