-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

-- declaracion de entidad
entity tp4_tb is
	generic(COORD_W: integer:= 13;  --long coordenadas x, y, z.
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

-------------------------* 
-- baud rate | DVSR_UART |
-------------+-----------*     
--      300    10416.7   |
--      600     5208.3   |
--     1200     2604.2   |
--     2400     1302.1   |
--     4800     651      |
--     9600     325.5    |
--    14400     217      |
--    19200     162.8    |
--    38400      81.4    |
--    57600      54.3    |
--    115200     27.1    |
--    230400     13.6    |
--    460800      6.8    |
-------------------------*
   
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
        -- a SRAM externa --------------------------
        we_n, oe_n : out std_logic;
        dio_sram : inout std_logic_vector(DATA_W-1 downto 0);
        ce_n, ub_n, lb_n : out std_logic;
		address_sram: out std_logic_vector(ADDR_W-1 downto 0);
        -- a VGA ----------------------------------- 
	    red_o: out std_logic_vector(2 downto 0);
		grn_o: out std_logic_vector(2 downto 0);
		blu_o: out std_logic_vector(1 downto 0);	
        hs, vs: out std_logic		
		);
    end component;
    
    -- señales de prueba -----------------------------------------
    constant BAUD_RATE : integer := 46080;
    constant BIT_TIME : integer := 1000/BAUD_RATE;
    constant EOF_WORD : std_logic_vector(DATA_W-1 downto 0) 
                      :="1111111111111111";
    constant DATA_MATCH : std_logic_vector(DATA_W-1 downto 0)
                        := std_logic_vector(to_unsigned(138,DATA_W));
	
    signal clk_tb, ena_tb, rst_tb: std_logic:= '0';
    signal count_tb: std_logic_vector(4 downto 0);
    signal ena_gen_data: std_logic := '0';
    -- a UART ----------------------------------
    signal rx_tb : std_logic:= '1';
    signal tx_tb : std_logic;
	signal pulsadores_tb: std_logic_vector(5 downto 0);
	--signal  xin, yin, zin: std_logic_vector(COORD_W-1 downto 0);
    -- a SRAM externa --------------------------
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
	
    file datos: text open read_mode is "test_files/datos.txt";	
    
    signal binario: std_logic_vector(0 downto 0);
	
begin 
	clk_tb <= not clk_tb after 10 ns; -- ES EL CLOCK DE LA FPGA 
	pulsadores_tb <= "010010";
	rst_tb <= '1' after 20 ns, '0' after 100 ns;
	ena_tb <= '0' after 40 ns, '1' after 203 ns;


    Test_Sequence: process
		variable linea: line;
		variable ch: character:= ' ';
		--variable aux: bit;
	begin
		wait until rising_edge(ena_tb);
		while not(endfile(datos)) loop 	-- si se quiere leer de stdin se pone "input"
			readline(datos, linea); 	-- se lee una linea del archivo de valores de prueba
            -- bit de inicio -------
            rx_tb <= '0'; 
            wait for 950 ns;
            -- bits de datos -------
            for i in 1 to 8 loop
			    read(linea, ch);   -- se extrae un entero de la linea
                binario <= std_logic_vector(to_unsigned(character'pos(ch),1));
                wait for 10 ns;
                rx_tb <= binario(0);
                wait for 950 ns;
            end loop;    
            -- reposo ---------------
            rx_tb <= '1'; 
            wait for 1000 ns;
		end loop;

		file_close(datos); -- cierra el archivo
		--wait for TCK*(DELAY+1); -- se pone el +1 para poder ver los datos
		--assert false report -- este assert se pone para abortar la simulacion
		--	"Fin de la simulacion" severity failure;
	end process Test_Sequence;

--    -- :: primer byte de dato :: --
--             -- bit de start
--    rx_tb <= '0' after 1 ns,
--             -- bits de datos
--             '0' after 960 ns,
--             '0' after 1920 ns,
--             '0' after 2880 ns,
--             '1' after 3840 ns,
--             '0' after 4800 ns,
--             '0' after 5760 ns,
--             '1' after 6720 ns,
--             '0' after 7680 ns,
--             -- bit de stop
--             '1' after 8640 ns,
--             -- en reposo
--             '1' after 9600 ns,
--	        
--        -- :: segundo byte de dato :: --
--             -- bit de start
--             '0' after 10000 ns,
--    --rx_tb <= '0' after 10000 ns,
--             -- bits de datos
--             '1' after 10960 ns,
--             '1' after 11920 ns,
--             '1' after 12880 ns,
--             '1' after 13840 ns,
--             '0' after 14800 ns,
--             '0' after 15760 ns,
--             '1' after 16720 ns,
--             '0' after 17680 ns,
--             -- bit de stop
--             '1' after 18640 ns,
--             -- en reposo
--             '1' after 19600 ns,
--	
--        -- :: tercer byte de dato :: --
--             -- bit de start
--    --rx_tb <= '0' after 20000 ns,
--             '0' after 20000 ns,
--             -- bits de datos
--             '0' after 20960 ns,
--             '0' after 21920 ns,
--             '1' after 22880 ns,
--             '1' after 23840 ns,
--             '0' after 24800 ns,
--             '0' after 25760 ns,
--             '1' after 26720 ns,
--             '0' after 27680 ns,
--             -- bit de stop
--             '1' after 28640 ns,
--             -- en reposo
--             '1' after 29600 ns,
--	
--        -- :: cuarto byte de dato :: --
--             -- bit de start
--    --rx_tb <= '0' after 30000 ns,
--             '0' after 30000 ns,
--             -- bits de datos
--             '1' after 30960 ns,
--             '0' after 31920 ns,
--             '0' after 32880 ns,
--             '0' after 33840 ns,
--             '0' after 34800 ns,
--             '0' after 35760 ns,
--             '1' after 36720 ns,
--             '0' after 37680 ns,
--             -- bit de stop
--             '1' after 38640 ns,
--             -- en reposo
--             '1' after 39600 ns,
--	
--        -- :: quinto byte de dato :: --
--             -- bit de start
--             '0' after 40000 ns,
--             -- bits de datos
--             '0' after 40960 ns,
--             '0' after 41920 ns,
--             '0' after 42880 ns,
--             '0' after 43840 ns,
--             '0' after 44800 ns,
--             '1' after 45760 ns,
--             '0' after 46720 ns,
--             '0' after 47680 ns,
--             -- bit de stop
--             '1' after 48640 ns,
--             -- en reposo
--             '1' after 49600 ns,
--	        
--        -- :: sexto byte de dato :: --
--             -- bit de start
--             '0' after 50000 ns,
--    --rx_tb <= '0' after 10000 ns,
--             -- bits de datos
--             '1' after 50960 ns,
--             '0' after 51920 ns,
--             '1' after 52880 ns,
--             '1' after 53840 ns,
--             '0' after 54800 ns,
--             '0' after 55760 ns,
--             '1' after 56720 ns,
--             '0' after 57680 ns,
--             -- bit de stop
--             '1' after 58640 ns,
--             -- en reposo
--             '1' after 59600 ns,
--	
--         -- :: septimo byte de dato :: --
--             -- bit de start
--    --rx_tb <= '0' after 20000 ns,
--             '0' after 60000 ns,
--             -- bits de datos
--             '1' after 60960 ns,
--             '0' after 61920 ns,
--             '1' after 62880 ns,
--             '0' after 63840 ns,
--             '1' after 64800 ns,
--             '0' after 65760 ns,
--             '1' after 66720 ns,
--             '0' after 67680 ns,
--             -- bit de stop
--             '1' after 68640 ns,
--             -- en reposo
--             '1' after 69600 ns,
--	
--        -- :: octavo byte de dato :: --
--             -- bit de start
--    --rx_tb <= '0' after 30000 ns,
--             '0' after 70000 ns,
--             -- bits de datos
--             '0' after 70960 ns,
--             '1' after 71920 ns,
--             '1' after 72880 ns,
--             '1' after 73840 ns,
--             '0' after 74800 ns,
--             '0' after 75760 ns,
--             '1' after 76720 ns,
--             '0' after 77680 ns,
--             -- bit de stop
--             '1' after 78640 ns,
--             -- en reposo
--             '1' after 79600 ns,
--	
--        -- :: noveno byte de dato :: --
--             -- bit de start
--    --rx_tb <= '0' after 20000 ns,
--             '0' after 80000 ns,
--             -- bits de datos
--             '0' after 80960 ns,
--             '0' after 81920 ns,
--             '1' after 82880 ns,
--             '0' after 83840 ns,
--             '0' after 84800 ns,
--             '0' after 85760 ns,
--             '1' after 86720 ns,
--             '0' after 87680 ns,
--             -- bit de stop
--             '1' after 88640 ns,
--             -- en reposo
--             '1' after 89600 ns,
--	
--        -- :: decimo byte de dato :: --
--             -- bit de start
--             --rx_tb <= '0' after 30000 ns,
--             '0' after 90000 ns,
--             -- bits de datos
--             '1' after 90960 ns,
--             '1' after 91920 ns,
--             '1' after 92880 ns,
--             '1' after 93840 ns,
--             '0' after 94800 ns,
--             '0' after 95760 ns,
--             '1' after 96720 ns,
--             '0' after 97680 ns,
--             -- bit de stop
--             '1' after 98640 ns,
--             -- en reposo
--             '1' after 99600 ns,
--
--        -- :: onceavo byte EOF_WORD :: --
--             -- bit de start
--    --rx_tb <= '0' after 20000 ns,
--             '0' after 100000 ns,
--             -- bits de datos
--             '1' after 100960 ns,
--             '1' after 101920 ns,
--             '1' after 102880 ns,
--             '1' after 103840 ns,
--             '1' after 104800 ns,
--             '1' after 105760 ns,
--             '1' after 106720 ns,
--             '1' after 107680 ns,
--             -- bit de stop
--             '1' after 108640 ns,
--             -- en reposo
--             '1' after 109600 ns,
--	
--        -- :: doceavo byte EOF_WORD :: --
--             -- bit de start
--             --rx_tb <= '0' after 30000 ns,
--             '0' after 110000 ns,
--             -- bits de datos
--             '1' after 110960 ns,
--             '1' after 111920 ns,
--             '1' after 112880 ns,
--             '1' after 113840 ns,
--             '1' after 114800 ns,
--             '1' after 115760 ns,
--             '1' after 116720 ns,
--             '1' after 117680 ns,
--             -- bit de stop
--             '1' after 118640 ns,
--             -- en reposo
--             '1' after 119600 ns;
	

--#################################################################
     --   ::    Contador para generar datos     ::                #
------------------------------------------------------------------#
    gen_data: entity work.counter                               --#
    generic map(N => DATA_W+3)                                  --#
    port map(                                                   --#
        rst => rst_tb,                                          --#
        rst_sync => '0',                                        --#
        clk => clk_tb,                                          --#
        ena => ena_gen_data,                                    --#
        count => dio_sram_tb_aux                                --#
    );                                                          --#
    ena_gen_data <= '1' after 119300 ns;                        --#
    process(dio_sram_tb_aux, ena_gen_data)                      --#
    begin                                                       --#
    if ena_gen_data = '1' then                                  --#
        if dio_sram_tb_aux(DATA_W+2 downto 3) = DATA_MATCH then --#
            dio_sram_tb <= EOF_WORD;                           --#
        else                                                    --#
            dio_sram_tb <= dio_sram_tb_aux(DATA_W+2 downto 3);  --#
        end if;                                                 --#
    else                                                        --#
        dio_sram_tb <= (others => 'Z');                         --#
    end if;                                                     --#
    end process;                                                --#
--#################################################################

--###########################################################
--     -- ::  Contador para emular fin del  rotador 3D  ::     #
--     --------------------------------------------------------#
--     gen_tick3D: entity work.counter(behavioral)           --#
--     generic map (N => 5) --quiero contar 32 ciclos        --#
--     port map(                                             --#
--         rst => rst_tb,                                    --#
--         clk => clk_tb,                                    --#
--         rst_sync => '0',                                  --#
--         ena => '1', -- que cuente siempre                 --#
--         count => count_tb                                 --#
--     );                                                    --#
--     -- genero un tick cada 32 ciclos emulando el rotador 3D #
--     process(count_tb)                                     --# 
--     begin                                                 --#
--         if(count_tb = "10001") then                       --#
--             flag_fin_tb <= '1';                           --#
--         else                                              --#
--             flag_fin_tb <= '0';                           --#
--         end if;                                           --#
--     end process;                                          --#
--                                                           --#
--###########################################################

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
        -- a SRAM externa --------------------------
        we_n => we_n_tb, oe_n => oe_n_tb,
        dio_sram => dio_sram_tb,
        ce_n => ce_n_tb, ub_n => ub_n_tb, lb_n => lb_n_tb,
		address_sram => address_sram_tb,
        -- a VGA ----------------------------------- 
	    red_o => red_o_tb,
		grn_o => grn_o_tb,
		blu_o => blu_o_tb,	
        hs => hs_tb, vs => vs_tb		
		);
  
    

		
end tp4_tb_arq;
