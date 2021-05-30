-- Listing 10.2
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity sram_tb is
  generic( 	M: natural := 18; -- address width
			L: natural := 16); 	--data width	
  port(
      --clk, reset: in std_logic;
      --sw: in std_logic_vector(7 downto 0);
      --btn: in std_logic_vector(2 downto 0);
      --led: out std_logic_vector(7 downto 0);
      ad: out std_logic_vector(M-1 downto 0);
      we_n, oe_n: out std_logic;
      dio_a: inout std_logic_vector(L-1 downto 0);
      ce_a_n, ub_a_n, lb_a_n: out std_logic
  );
end sram_tb;

architecture sram_tb_arch of sram_tb is
   
   constant ADDR_W: natural:=M ;
   constant DATA_W: natural:=L ;
   
   signal addr: std_logic_vector(ADDR_W-1 downto 0) := "010101010101010101";
   signal data_f2s: std_logic_vector(DATA_W-1 downto 0) := "1111111100000000";
   signal data_s2f: std_logic_vector(DATA_W-1 downto 0) := "0000111111110000";
   signal mem, rw: std_logic;
   signal data_reg: std_logic_vector(7 downto 0);
   signal db_btn: std_logic_vector(2 downto 0);
   signal clk_tb, reset_tb: std_logic := '0';
   --signal dio_aux: inout std_logic_vector(L-1 downto 0); -- := 

begin
   
	reset_tb <= '0';
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	
	mem <= '0', '1' after 60 ns, '0' after 1000 ns;
	rw <= '0', '1' after 500 ns; --activo modo 'read' después de 500 ns
	process(rw, dio_a)
	begin
		if (rw = '1') then
			dio_a <= "0000000011111111";
		end if;
	end process;
		
	
	ctrl_unit: entity work.sram_ctrl
	port map(
      clk=>clk_tb, reset=>reset_tb,
      mem=>mem, rw =>rw, addr=>addr, data_f2s=>data_f2s,
      ready=>open, data_s2f_r=>data_s2f,
      data_s2f_ur=>open, ad=>ad,
      we_n=>we_n, oe_n=>oe_n, dio_a=>dio_a,
      ce_a_n=>ce_a_n, ub_a_n=>ub_a_n, lb_a_n=>lb_a_n)
	;
       -- port map(
          -- clk=>clk, reset=>reset, sw=>btn(1),
          -- db_level=>open, db_tick=>db_btn(1));
    -- debounce_unit2: entity work.debounce
       -- port map(
          -- clk=>clk, reset=>reset, sw=>btn(2),
          -- db_level=>open, db_tick=>db_btn(2));

   ----data registers
   -- process(clk)
   -- begin
      -- if (rising_edge(clk)) then
         -- if (db_b_tn(0)='1') then
            -- data_reg <= sw;
         -- end if;
     -- end if;
   -- end process;
   ----address
   -- addr <= "0000000000" & sw;
   
   -- process(db_btn,data_reg)
   -- begin
     -- data_f2s <= (others=>'0');
     -- if db_btn(1)='1' then -- write
        -- mem <= '1';
        -- rw <= '0';
        -- data_f2s <= "00000000" & data_reg;
     -- elsif db_btn(2)='1' then -- read
        -- mem <= '1';
        -- rw <= '1';
     -- else
        -- mem <= '0';
        -- rw <= '1';
      -- end if;
   -- end process;
   ----output
   -- led <= data_s2f(7 downto 0);
end sram_tb_arch;
