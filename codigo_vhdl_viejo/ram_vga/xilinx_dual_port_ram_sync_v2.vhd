--extract to FPGA PROTOTYPING BY VHDL EXAMPLES, Pong P. Chu 
--dual-portRAM with synchronous read
--modified fromXST8.1irams-11
--se agrega borrado total de memoria

library ieee;
use ieee. std_logic_1164.all ;
use ieee. numeric_std.all ;

entity xilinx_dual_port_ram_sync is
	generic(
		ADDR_WIDTH: integer:=18;
		DATA_WIDTH:	integer:=1
	);
	port(
		clk: in std_logic;
		we: in std_logic;
		rst: in std_logic;
		addr_a: in std_logic_vector (ADDR_WIDTH-1 downto 0);
		addr_b: in std_logic_vector (ADDR_WIDTH-1 downto 0);
		din_a: in std_logic_vector (DATA_WIDTH-1 downto 0);
		dout_a: out std_logic_vector (DATA_WIDTH-1 downto 0);
		dout_b: out std_logic_vector (DATA_WIDTH -1 downto 0)
	);
end;

architecture beh_arch of xilinx_dual_port_ram_sync is
	type 	ram_type is array (0 to 2**ADDR_WIDTH-1)
		of 	std_logic_vector (DATA_WIDTH-1 downto 0) ;
	signal 	ram: ram_type;
	signal 	addr_a_reg , addr_b_reg :
			std_logic_vector (ADDR_WIDTH -1 downto 0 ) ;

begin
	process (clk)
	begin
		if rising_edge(clk) then --(clk’event and clk = ’ 1 ’ ) then
			if (rst = '1') then
				ram <= (others => (others => '0'));
                dout_b <= (others => '0');
			elsif (we = '1') then
				ram(to_integer(unsigned(addr_a))) <= din_a;
			end if;
			addr_a_reg <= addr_a;
			addr_b_reg <= addr_b ;			
		end if ;
	end process ;
	dout_a <= ram(to_integer(unsigned(addr_a_reg)));
	dout_b <= ram(to_integer(unsigned(addr_b_reg)));
end beh_arch;