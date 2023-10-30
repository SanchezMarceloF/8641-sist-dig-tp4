----------------------------------------------------------------------------------
-- Create Date: 20/10/2023
-- Designer Name: Sanchez Marcelo
-- Module Name: borrado-dpr - Behavioral 
-- Project Name: algoritmo CORDIC
-- Target Devices: Spartan 3
-- Tool versions: v1.0
-- Description: Borrador de Dual Port Ram con pussbutton
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity borrado_dpr is
	generic(
		ADDR_W: integer:= 18; --long vectores direccionamiento
		DATA_W: integer:= 1  --len of data
	);
	port(
		clk, rst: in std_logic;
		button: in std_logic;
		addr_in: in std_logic_vector(ADDR_W-1 downto 0);
		addr_out: out std_logic_vector(ADDR_W-1 downto 0);
		we: out std_logic;
		data: out std_logic_vector(DATA_W-1 downto 0) 
	);
end borrado_dpr;

architecture borrado_dpr_arq of borrado_dpr is
	-- declaracion de componente, senales, etc
	
	component counter is
	generic (N : natural := 8);
	port(
        rst : in std_logic;
        rst_sync : in std_logic;
        clk : in std_logic;
        ena : in std_logic;
        count : out std_logic_vector(N-1 downto 0)
	);
	end component;
	
	--seniales
	signal count_aux: std_logic_vector(ADDR_W-1 downto 0);
	signal data_aux: std_logic_vector(DATA_W-1 downto 0):= "1";
	
-----------------------------------------------------------------------------------
begin
	
	borrado: process(button, addr_in, count_aux)
	begin
		if (button = '1') then
			we <= '1';
			data_aux <= (others => '1');
			addr_out <= count_aux;
		else
			we <= '0';
			data_aux <= (others => '0');
			addr_out <= addr_in;
		end if;
	end process;
	
	count_ins: counter
	generic map (N => ADDR_W)
	port map(
        rst => '0',
        rst_sync => rst,
        clk => clk,
        ena => '1',
        count => count_aux
	);

	data <= data_aux;
		
end borrado_dpr_arq;