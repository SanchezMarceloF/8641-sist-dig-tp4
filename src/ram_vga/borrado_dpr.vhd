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
		clk, rst, ena: in std_logic;
		addr_in: in std_logic_vector(ADDR_W-1 downto 0);
		addr_out: out std_logic_vector(ADDR_W-1 downto 0);
		we: out std_logic;
		data: out std_logic_vector(DATA_W-1 downto 0);
		flag_fin: out std_logic
	);
end borrado_dpr;

architecture borrado_dpr_arq of borrado_dpr is
	-- declaracion de componente, senales, etc
	
	constant MAXCOUNT: unsigned((ADDR_W/2)-1 downto 0):= to_unsigned(322,ADDR_W/2);
	
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
	signal ena_v, rst_sync_v, rst_sync_h: std_logic:= '0';
	signal count_v, count_h: std_logic_vector(ADDR_W/2-1 downto 0);
	signal addr_aux: std_logic_vector(ADDR_W-1 downto 0);
	signal data_aux: std_logic_vector(DATA_W-1 downto 0):= "1";
	
-----------------------------------------------------------------------------------
begin
	
	borrado: process(ena, addr_in, addr_aux)
	begin
		if (ena = '1') then
			we <= '1';
			data_aux <= (others => '1');
			addr_out <= addr_aux;
		else
			we <= '0';
			data_aux <= (others => '0');
			addr_out <= addr_in;
		end if;
	end process;
	
	addr_aux <= count_v & count_h;
	
	counter_h: counter
	generic map (N => ADDR_W/2)
	port map(
        rst => rst,
        rst_sync => rst_sync_h,
        clk => clk,
        ena => ena,
        count => count_h
	);
	
	counter_v: counter
	generic map (N => ADDR_W/2)
	port map(
        rst => rst,
        rst_sync => rst_sync_v,
        clk => clk,
        ena => ena_v,
        count => count_v
	);
	
	reset_count_h: process(count_h)
	begin
		if unsigned(count_h(ADDR_W/2-1 downto 0)) = MAXCOUNT then
			rst_sync_h <= '1';
			ena_v <= '1';
		else
			rst_sync_h <= '0';
			ena_v <= '0';
		end if;
	end process;
	
	reset_count_v: process(count_v)
	begin
		if unsigned(count_v(ADDR_W/2-1 downto 0)) = MAXCOUNT+1 then
			rst_sync_v <= '1';
		else
			rst_sync_v <= '0';
		end if;
	end process;

	-- Salidas
	
	data <= data_aux;
	flag_fin <= rst_sync_v;
		
end borrado_dpr_arq;