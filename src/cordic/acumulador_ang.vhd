-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity acumulador_ang is
	generic(ANG_WIDE: integer:= 16);
	port(
		phi_0: in std_logic_vector(ANG_WIDE-1 downto 0);
		count: in std_logic_vector(3 downto 0);
		clk: in std_logic;
		ctrl: in std_logic;		--'0' => phi_0; '1' => z_i
		di: out std_logic;
		phi_n: out std_logic_vector(ANG_WIDE-1 downto 0)
		);
end;

--declaracion de arquitectura

architecture acumulador_ang_arq of acumulador_ang is

	component mux is
		generic(N :integer:= 17);
		port (
			A_0: in std_logic_vector(N-1 downto 0);
			A_1: in std_logic_vector(N-1 downto 0);
			sel: in std_logic;
			sal: out std_logic_vector(N-1 downto 0) 
		);
	end component;
	
	component registro is
		generic(N: natural := 4);
		port(
			D: in std_logic_vector(N-1 downto 0);
			clk: in std_logic;
			rst: in std_logic;
			ena: in std_logic;		
			Q: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
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
	
	signal zn_aux, sal_rom, B1_aux: std_logic_vector(ANG_WIDE-1 downto 0);
	signal sal_mux, sal_reg: std_logic_vector(ANG_WIDE-1 downto 0);
	signal di_aux: std_logic;
	

begin	
	

	mux_up: mux
		generic map(N => ANG_WIDE)
		port map(
			A_0 => phi_0,
			A_1 => zn_aux,
			sel => ctrl,
			sal => sal_mux
	);
	
	reg_z: registro
		generic map(N => ANG_WIDE)
		port map(
			D => sal_mux,
			clk => clk,
			rst => '0',
			ena => '1',
			Q => sal_reg
	);
	
	
	--aca van los valores calculados de tg^(-1){2^(-i)}
	--------------------------------------------------------
	sal_rom <=	"00100000000000000" when to_integer(unsigned(count)) = 0 else
				"00010010111001000" when to_integer(unsigned(count)) = 1 else
				"00001001111110110" when to_integer(unsigned(count)) = 2 else
				"00000101000100010" when to_integer(unsigned(count)) = 3 else
				"00000010100010110" when to_integer(unsigned(count)) = 4 else
				"00000001010001011" when to_integer(unsigned(count)) = 5 else
				"00000000101000101" when to_integer(unsigned(count)) = 6 else
				"00000000010100011" when to_integer(unsigned(count)) = 7 else
				"00000000001010001" when to_integer(unsigned(count)) = 8 else
				"00000000000101001" when to_integer(unsigned(count)) = 9 else
				"00000000000010100" when to_integer(unsigned(count)) = 10 else
				"00000000000001010" when to_integer(unsigned(count)) = 11 else
				"00000000000000101" when to_integer(unsigned(count)) = 12 else
				"00000000000000011" when to_integer(unsigned(count)) = 13 else
				"00000000000000001";

	di_aux <= not sal_reg(ANG_WIDE-1);		
				
	sum_z: sumador
		generic map(N => ANG_WIDE)
		port map(
			A => sal_reg,
			B => sal_rom, 
			ctrl => di_aux,
			Cin => '0',
			Sal => zn_aux,
			Cout => open
    );
	

	--salida. angulo acumulado
	phi_n <= zn_aux;
	di <= di_aux;
	
end;