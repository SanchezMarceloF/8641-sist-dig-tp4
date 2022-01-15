-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- declaracion de entidad
entity rotador3d_tb is
	generic(COORD_W: integer:= 13; --long coordenadas x y z
			ANG_W: integer:= 15; --long angulos de rotacion
			PIX_W: natural := 10; --long direcciones pixel_col y pixel_row
			DUAL_W: integer := 9; --long direcciones a dual port RAM
			ADDR_W: natural := 18; -- address width to external SRAM
			DATA_W: natural := 16); 	--data width to external SRAM
  port(
      --clk, reset: in std_logic;
      --sw: in std_logic_vector(7 downto 0);
      --btn: in std_logic_vector(2 downto 0);
      --led: out std_logic_vector(7 downto 0);
      ad_tb: out std_logic_vector(ADDR_W-1 downto 0);
      we_n, oe_n: out std_logic;
      dio_a: inout std_logic_vector(DATA_W-1 downto 0);
      ce_a_n, ub_a_n, lb_a_n: out std_logic
  );
end rotador3d_tb;

-- cuerpo de arquitectura
architecture rotador3d_tb_arq of rotador3d_tb is
	-- declaracion de componente, senales, etc
	
	component rotador3d is
	generic(N: natural := COORD_W;	--longitud de los vectores
			M: natural := ANG_W;	--longitud de los angulos
			R: natural := ADDR_W);	--address width to external SRAM
	port(
		x_0, y_0, z_0: in std_logic_vector(N-1 downto 0);
		pulsadores: in std_logic_vector(5 downto 0);
		rst, ena, clk: in std_logic;
		x_n, y_n, z_n: out std_logic_vector(N-1 downto 0);
		addr: out std_logic_vector(R-1 downto 0); --direccionamiento memoria RAM externa
		flag_fin: out std_logic
	);
	end component;

	component sram_ctrl is
    generic(DATA_W: natural := DATA_W;
			ADDR_W: natural := ADDR_W);
	port(
      clk, reset: in std_logic;
      -- to/from main system
      mem: in std_logic;
      rw: in std_logic;
      addr: in std_logic_vector(ADDR_W-1 downto 0);
      data_f2s: in std_logic_vector(DATA_W-1 downto 0);
      ready: out std_logic;
      data_s2f_r, data_s2f_ur: out std_logic_vector(DATA_W-1 downto 0);
      -- to/from chip
      ad: out std_logic_vector(ADDR_W-1 downto 0);
      we_n, oe_n: out std_logic;
      -- SRAM chip a
      dio_a: inout std_logic_vector(DATA_W-1 downto 0);
      ce_a_n, ub_a_n, lb_a_n: out std_logic
	);
	end component;

	component generador_direcciones is
	generic(N: integer := COORD_W;	--longitud de las coordenadas x y z
			L: integer := DUAL_W);	--longitud de las direcciones
	port(
		--flag: in std_logic;	--me avisa cuando termina de rotar.
		x, y: in std_logic_vector(N-1 downto 0);
		Addrx, Addry: out std_logic_vector(L-1 downto 0)
		--grabar: out std_logic
	);
	end component;
	
	component controlador is
	generic(
		M: integer:= PIX_W; --long de vectores pixel de vga_ctrl
		N: integer:= DUAL_W --address width dual_port port B
		--W: integer:= 8
	);
	port(
		pixel_row, pixel_col: in std_logic_vector(M-1 downto 0);
		address: out std_logic_vector(N*2 - 1 downto 0)
	);
	end component;
	
	component vga_ctrl is
    port (
		mclk: in std_logic;
		red_i: in std_logic;
		grn_i: in std_logic;
		blu_i: in std_logic;
		hs: out std_logic;
		vs: out std_logic;
		red_o: out std_logic_vector(2 downto 0);
		grn_o: out std_logic_vector(2 downto 0);
		blu_o: out std_logic_vector(1 downto 0);
		pixel_row: out std_logic_vector(9 downto 0);
		pixel_col: out std_logic_vector(9 downto 0)
	);
	end component;	
	
  
   -- señales para RAM externa ----------------------------
    signal addr_ramext_tb: std_logic_vector(ADDR_W-1 downto 0) := "010101010101010101";
    signal data_f2s_tb: std_logic_vector(DATA_W-1 downto 0);
    signal data_s2f_r_tb: std_logic_vector(DATA_W-1 downto 0);
    signal mem_tb, rw_tb, ready_tb: std_logic;
    --signal data_reg: std_logic_vector(7 downto 0);
    --signal db_btn: std_logic_vector(2 downto 0);
	--señales tb ----------------------------------------
	signal clk_tb, ena_tb, rst_tb: std_logic := '0';
	--señales para rotador 3D
	signal x0_tb: std_logic_vector(COORD_W-1 downto 0):= "1110011111001";
	signal y0_tb: std_logic_vector(COORD_W-1 downto 0):= "1110010000101";
	signal z0_tb: std_logic_vector(COORD_W-1 downto 0):= "0011010001001";
	signal pulsadores_tb: std_logic_vector(5 downto 0);
	signal xn_tb, yn_tb, zn_tb: std_logic_vector(COORD_W-1 downto 0);
	--señales para generador_direcciones ------------------
	signal Addrx_ram_portA_tb, Addry_ram_portA_tb: std_logic_vector(DUAL_W-1 downto 0);
	--señales para controlador ------------------------------
	signal pxl_col_tb, pxl_row_tb: std_logic_vector(PIX_W-1 downto 0);
	signal addr_ram_portB_tb: std_logic_vector(2*DUAL_W-1 downto 0);
	--señales auxiliares -----------------------------------
	signal flag_fin_aux: std_logic;
	
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	rst_tb <= '1' after 30 ns, '0' after 60 ns;

	pulsadores_tb <= "010010";
	ena_tb <= '1';

	--SRAM ----------------------------------------------------

	
	-- mem_tb = 1 habilita las operaciones de memoria
	mem_tb <= '0', '1' after 60 ns, '0' after 1000 ns;
	-- rw_tb = 1 modo lectura, rw = 0 modo escritura.
	rw_tb <= '0', '1' after 500 ns; --activo modo 'read' después de 500 ns
	
	process(clk_tb, rw_tb, dio_a)
	begin
		if rising_edge(clk_tb) then
			if (rw_tb = '1') then
				dio_a <= "0000000011111111";
			end if;
		end if;						
	end process;
		
	
	ctrl_unit: sram_ctrl
	port map(
      clk=>clk_tb, reset=>rst_tb,
      mem=>mem_tb, rw =>rw_tb, addr=>addr_ramext_tb, data_f2s=>data_f2s_tb,
      ready=>ready_tb, data_s2f_r=>data_s2f_r_tb,
      data_s2f_ur=>open, ad=>ad_tb,
      we_n=>we_n, oe_n=>oe_n, dio_a=>dio_a,
      ce_a_n=>ce_a_n, ub_a_n=>ub_a_n, lb_a_n=>lb_a_n)
	;
	
	x0_tb <= data_s2f_r_tb(COORD_W-1 downto 0);
	--------------------------------------------------------------

	DUT: rotador3d
	generic map(N => COORD_W, M => ANG_W, R => ADDR_W)
	port map(
		x_0 => x0_tb, y_0 => y0_tb, z_0 => z0_tb,
		pulsadores => pulsadores_tb,
		rst => rst_tb, ena => ena_tb, clk => clk_tb,
		x_n => xn_tb, y_n => yn_tb, z_n => zn_tb,
		addr => addr_ramext_tb, --direccionamiento memoria RAM externa
		flag_fin => flag_fin_aux
	);
	
	DUT2: generador_direcciones
	generic map(N => COORD_W, L => DUAL_W)	--longitud de las direcciones
	port map(
		--flag: in std_logic;	--me avisa cuando termina de rotar.
		x => xn_tb, y => yn_tb,
		Addrx => Addrx_ram_portA_tb, Addry => Addry_ram_portA_tb --direcciones a port A dual port RAM
	);
	
	vga: vga_ctrl
    port map(mclk => clk_tb, red_i => '1', grn_i => '1', blu_i => '1',
		hs => open, vs => open, red_o => open, grn_o => open, blu_o => open,
		pixel_row => pxl_row_tb, pixel_col => pxl_col_tb
	);
	
	ctrl_portb: controlador
	generic map (M => PIX_W, N => DUAL_W) --long de vectores pixel de vga_ctrl
		--long vectores direccionamiento
	port map(
		pixel_row => pxl_row_tb,
		pixel_col => pxl_col_tb,
		address => addr_ram_portB_tb --direcciones a port B dual port RAM
	);
	
end;
