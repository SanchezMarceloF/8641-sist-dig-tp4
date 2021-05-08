-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity tp4_tb is
	generic(N: integer:= 13; --long coordenadas x y z
			M: integer:= 15; --long angulos de rotacion
			R: natural := 10; --long direcciones a memoria ROM externa
			L: integer := 9); --long direcciones a dual port RAM
	end;

-- cuerpo de arquitectura
architecture tp4_tb_arq of tp4_tb is
	-- declaracion de componente, senales, etc
	
	component tp4 is
	generic(N: integer:= 13; --long coordenadas x, y, z.
			M: integer:= 15; --long angulos de rotacion
			R: natural:= 10; --long direcciones a memoria ROM externa
			L: integer:= 9); --long direcciones a dual port RAM
	port(
		clk, ena, rst: in std_logic;
		--pulsadores(5): alfa_up | (4): alfa_down | (3): beta_up
		--(2): beta_down | (1): gamma_up | (0): gamma_down	
		pulsadores: in std_logic_vector(5 downto 0);
		xin, yin, zin: in std_logic_vector(N-1 downto 0);
		addr_rom: out std_logic_vector(R-1 downto 0);
		data_out, hs, vs: out std_logic		
		);
	end component;	
	
	--señales de prueba
	
	--señales tb
	signal clk_tb, ena_tb, rst_tb: std_logic := '0';
	--señales para tp4
	signal pulsadores_tb: std_logic_vector(5 downto 0);
	signal xin_tb: std_logic_vector(N-1 downto 0):= "1110011111001";
	signal yin_tb: std_logic_vector(N-1 downto 0):= "1110010000101";
	signal zin_tb: std_logic_vector(N-1 downto 0):= "0011010001001";
	signal addr_rom_tb: std_logic_vector(R-1 downto 0);
	signal data_out_tb, hs_tb, vs_tb: std_logic;
	
	
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 

	pulsadores_tb <= "010010";
	ena_tb <= '1';
	rst_tb <= '1' after 20 ns, '0' after 100 ns;
	
	
	DUT: tp4
	generic map(N, M, R, L)
	port map(
		clk_tb, ena_tb, rst_tb,
		pulsadores_tb, xin_tb, yin_tb, zin_tb,
		addr_rom_tb,
		data_out_tb, hs_tb, vs_tb
	);
	
	
end;