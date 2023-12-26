-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

-- declaracion de entidad
entity tp4_tb is
	generic(COORD_W: integer:= 14;  --long coordenadas x, y, z.
			ANG_W: integer:= 15;    --long angulos de rotacion
			ADDR_DP_W: integer:= 9; --long direcciones a dual port RAM
	        DATA_DP_W: natural:= 1;
            -- UART -- Default setting:
            -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
            DBIT_UART: integer:=8;     -- # data bits
            SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
            DVSR_UART: integer:= 3;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
            DVSR_BIT_UART: integer:=8; -- # bits of DVSR
            FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
            -- SRAM externa ----------
            DATA_W: natural := 16;
		    ADDR_W: natural := 23
    );
	end;

    -- *-----------------------* 
    -- | baud rate | DVSR_UART |
    -- *-----------+-----------*     
    -- |      300    10416.7   |
    -- |      600     5208.3   |
    -- |     1200     2604.2   |
    -- |     2400     1302.1   |
    -- |     4800      651     |
    -- |     9600      325.5   |
    -- |    14400      217     |
    -- |    19200      162.8   |
    -- |    38400       81.4   |
    -- |    57600       54.3   |
    -- |   115200       27.1   |
    -- |   230400       13.6   |
    -- |   460800        6.8   |
    -- *-----------------------*
   
-- cuerpo de arquitectura

architecture tp4_tb_arq of tp4_tb is

    component tp4 is
	generic(COORD_W: integer:= 13;  --long coordenadas x, y, z.
			ANG_W: integer:= 15;    --long angulos de rotacion
            ADDR_DP_W: integer:= 9; --long direcciones a dual port RAM
            DATA_DP_W: natural:= 1;
            -- UART -- Default setting:
            -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
            DBIT_UART: integer:=8;     -- # data bits
            SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
            DVSR_UART: integer:= 163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
            DVSR_BIT_UART: integer:=8; -- # bits of DVSR
            FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
            -- SRAM externa ----------
            DATA_W: natural := 16;
		    ADDR_W: natural := 23
    );
	port(
		clk, ena, rst: in std_logic;
		-- a UART ----------------------------------
		rx : in std_logic;
		tx : out std_logic;
		-- pulsadores(5): alfa_up | (4): alfa_down | (3): beta_up
		-- (2): beta_down | (1): gamma_up | (0): gamma_down	
		pulsadores: in std_logic_vector(5 downto 0);
		vga_clear: in std_logic;
		-- a SRAM externa --------------------------
		adv, mt_clk, mt_cre : out std_logic;
		we_n, oe_n : out std_logic;
		dio_sram : inout std_logic_vector(DATA_W-1 downto 0);
		ce_n, ub_n, lb_n : out std_logic;
		address_sram: out std_logic_vector(ADDR_W-1 downto 0);
		-- a VGA ----------------------------------- 
		red_o: out std_logic_vector(2 downto 0);
		grn_o: out std_logic_vector(2 downto 0);
		blu_o: out std_logic_vector(1 downto 0);	
		hs, vs: out std_logic;	
		-- a 7 segmentos
		sal_7seg: out std_logic_vector(7 downto 0);
		-- para capturar en simulacion
		tick_dpr: out std_logic;
		pxl_x: out std_logic_vector(ADDR_DP_W-1 downto 0);
		pxl_y: out std_logic_vector(ADDR_DP_W-1 downto 0)
	);
   end component;
    
	-- señales de prueba -----------------------------------------
	constant BAUD_RATE : integer := 46080;
	constant BIT_TIME : integer := 1000/BAUD_RATE;
	constant EOF_WORD : std_logic_vector(DATA_W-1 downto 0) 
                      :="1111111111111111";
	constant DATA_MATCH : std_logic_vector(DATA_W-1 downto 0)
						:= std_logic_vector(to_unsigned(138,DATA_W));
	constant DATA_ROW_LEN : integer := 4;                   
	constant SRAM_ROW_LEN : integer := 12;                     
	
	signal clk_tb, ena_tb, rst_tb: std_logic:= '0';
	signal count_tb: std_logic_vector(4 downto 0);
	signal ena_gen_data: std_logic := '0';
    -- a UART ----------------------------------
	signal rx_tb : std_logic:= '1';
	signal tx_tb, tx_ena: std_logic:='0';
	signal pulsadores_tb: std_logic_vector(5 downto 0);
	signal vga_clear_tb: std_logic:= '0';
    -- a SRAM externa --------------------------
	signal adv_tb, mt_clk_tb, mt_cre_tb : std_logic;
	signal we_n_tb, oe_n_tb : std_logic;
	signal dio_sram_tb: std_logic_vector(DATA_W-1 downto 0)
                    := (others =>'0');
	signal dio_sram_tb_aux: std_logic_vector(DATA_W+2 downto 0)
                    := (others =>'0');
	signal ce_n_tb, ub_n_tb, lb_n_tb : std_logic;
	signal address_sram_tb: std_logic_vector(ADDR_W-1 downto 0);
    -- a VGA ----------------------------------- 
	signal red_o_tb: std_logic_vector(2 downto 0);
	signal grn_o_tb: std_logic_vector(2 downto 0);
	signal blu_o_tb: std_logic_vector(1 downto 0);	
	signal hs_tb, vs_tb: std_logic;	
	-- para capturar datos y escribir en archivo
	signal tick_dpr_tb: std_logic;
	signal pxl_x_tb, pxl_y_tb:	std_logic_vector(ADDR_DP_W-1 downto 0);
	-- para operar con archivo de datos -------------
	-- file datos  : text open read_mode is "test_files/datos.bin";
	file datos  : text open read_mode is "test_files/coord_linea_ptofijo-16.bin";
	file datos_ram 	: text open read_mode is
					--"test_files/coor_linea_ptofijo-16_ram.txt";
					"test_files/coordenadas_ptofijoDEC3-16.txt";
	file output	: text open write_mode is
					"test_files/output.txt";
	signal word : std_logic_vector(7 downto 0);
	signal word_sram : std_logic_vector(7 downto 0);
    	
begin 

	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	pulsadores_tb <= "100000";
	rst_tb <= '1' after 20 ns, '0' after 100 ns;
	ena_tb <= '0' after 40 ns, '1' after 203 ns;
	tx_ena <= '1' after 500 ns;
	vga_clear_tb <= '1' after 350 us;

	Test_sram: process
		variable linea: line;
		variable ch: character:= ' ';
	begin
		wait until rising_edge(ena_tb);
		while not(endfile(datos_ram)) loop 	-- si se quiere leer de stdin se pone "input"
			readline(datos_ram, linea); 	-- se lee una linea del archivo de valores de prueba
			for i in 1 to 3 loop
				wait until falling_edge(oe_n_tb);
				for j in 0 to 15 loop
					read(linea, ch);   -- se extrae un entero de la linea
					word_sram <= std_logic_vector(to_unsigned(character'pos(ch),8));
					wait for 1 ps;
					dio_sram_tb (15-j) <= word_sram(0);
				end loop;
			end loop;
		end loop;
		file_close(datos_ram); -- cierra el archivo
	end process Test_sram;
	
	output_file: process
	variable linea: line;
	variable ch: character:= ' ';
	begin
		wait until falling_edge(tick_dpr_tb);
		write(linea, to_integer(unsigned(pxl_x_tb)));
		write(linea, ch);
		write(linea, to_integer(unsigned(pxl_y_tb)));
		writeline(output, linea);
	end process output_file;

	Test_uart: process
		variable linea: line;
		variable ch: character:= ' ';
		--variable aux: bit;
	begin
		wait until rising_edge(tx_ena);
		while not(endfile(datos)) loop 	-- si se quiere leer de stdin se pone "input"
			readline(datos, linea); 	-- se lee una linea del archivo de valores de prueba
			for j in 1 to DATA_ROW_LEN loop
				for r in 1 to 6 loop
					read(linea, ch);   -- se extrae un entero de la linea
					word <= std_logic_vector(to_unsigned(character'pos(ch),8));
					-- bit de inicio -------
					rx_tb <= '0'; 
					wait for 960 ns;
					-- bits de datos -------
					for i in 0 to 7 loop
						if j = 1 then
							rx_tb <= '1';
						else
							rx_tb <= word(i);
						end if;
						wait for 960 ns;
					end loop;    
					-- reposo ---------------
					rx_tb <= '1'; 
					wait for 4000 ns;
					-- report "ch uart: " & integer'image(to_integer(unsigned(word)));
				end loop;    
			end loop;
		end loop;

		file_close(datos); -- cierra el archivo
		--wait for TCK*(DELAY+1); -- se pone el +1 para poder ver los datos
		--assert false report -- este assert se pone para abortar la simulacion
		--	"Fin de la simulacion" severity failure;
	end process Test_uart;

	  
	DUT: tp4
	generic map(COORD_W => COORD_W, --long coordenadas x, y, z.
				ANG_W => ANG_W,    --long angulos de rotacion
				ADDR_DP_W => ADDR_DP_W, --long direcciones a dual port RAM
				DATA_DP_W => DATA_DP_W,
				-- UART -- Default setting:
				-- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
				DBIT_UART => DBIT_UART,     -- # data bits
				SB_TICK_UART => SB_TICK_UART, -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
				DVSR_UART => DVSR_UART,  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
				DVSR_BIT_UART => DVSR_BIT_UART, -- # bits of DVSR
				FIFO_W_UART => FIFO_W_UART,    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
				-- SRAM externa ----------
				DATA_W => DATA_W,
				ADDR_W => ADDR_W
   )
	port map(
		clk => clk_tb, ena => ena_tb, rst => rst_tb,
		-- a UART ----------------------------------
		rx => rx_tb,
		tx => tx_tb,
		-- pulsadores(5): alfa_up | (4): alfa_down | (3): beta_up
		-- (2): beta_down | (1): gamma_up | (0): gamma_down	
		pulsadores => pulsadores_tb,
		vga_clear => vga_clear_tb,
		-- a SRAM externa --------------------------
	   adv => adv_tb, mt_clk => mt_clk_tb, mt_cre => mt_cre_tb,
		we_n => we_n_tb, oe_n => oe_n_tb,
		dio_sram => dio_sram_tb,
		ce_n => ce_n_tb, ub_n => ub_n_tb, lb_n => lb_n_tb,
		address_sram => address_sram_tb,
		-- a VGA ----------------------------------- 
		red_o => red_o_tb,
		grn_o => grn_o_tb,
		blu_o => blu_o_tb,	
		hs => hs_tb, vs => vs_tb,
		-- a 7 segmentos
		sal_7seg => open,
		-- para capturar en simulacion
		tick_dpr => tick_dpr_tb,
		pxl_x => pxl_x_tb,
		pxl_y => pxl_y_tb
	);
  
end tp4_tb_arq;
