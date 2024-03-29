library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gral_ctrl is
    generic(
        COORD_W: natural := 13;
        DATA_W: natural := 16;
		ADDR_W: natural := 23 
    );
    port(
        clk, rst, ena : in std_logic;
        -- a sram2cordic
        ena_sram2cordic: out std_logic;
        addr_tick_cordic: in std_logic;
        mem_cordic: in std_logic;
		 flag_eof: in std_logic;
        -- a uart2sram
        ena_uart2sram: out std_logic;
        rx_uart_empty: in std_logic;
        addr_tick_uart: in std_logic;
        mem_uart: in std_logic;
        -- a sram_ctrl
        data_f2s: in std_logic_vector(DATA_W-1 downto 0);
        data_s2f_r: in std_logic_vector(DATA_W-1 downto 0);
        addr_sram: out std_logic_vector(ADDR_W-1 downto 0);
        mem: out std_logic;
        rw: out std_logic;
		-- para 7 segmentos
		state: out std_logic_vector(2 downto 0);
		-- a rotador3d
		flag_rotnew: in std_logic;
		-- a borrador dual port ram
		clear_fin: in std_logic;
		borrar: out std_logic;
		-- switch externo
		ena_rot_ext: in std_logic
    );
end gral_ctrl;

architecture gral_ctrl_arch of gral_ctrl is

    -- instanciacion de componentes --------------------------
 
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

    -- señales ----------------------------------------------

	constant EOF_WORD: std_logic_vector(DATA_W-1 downto 0)
					 := (others => '1');   
	signal rst_addr_sync: std_logic:= '0';
	-- contador (direcciones a sram)---------------------------
	signal addr_tick: std_logic := '0';
	-- uart2sram ---------------------------------------------
	signal ena_uart2sram_aux : std_logic := '0';
	-- sram2cordic --------------------------------------------
	signal ena_sram2cordic_aux : std_logic := '0';
	signal mem_aux : std_logic := '0';
	signal rw_aux  : std_logic := '1';
	signal addr_sram_aux : std_logic_vector(ADDR_W-1 downto 0) 
						 := (others => '0');
	signal word          : std_logic_vector(DATA_W-1 downto 0) 
						 := (others => '0');
	-- a borrador dual port ram
	signal borrar_aux: std_logic;
	-- variables de estado --------------------------------------
	type t_estado is (REPOSO, CARGA_DATOS, ROTACION, ESPERA_ANG, REFRESH_DPR);
	signal estado_act, estado_sig : t_estado;

	-- señales para visualizar los estados en gtkwave ------------------
	signal estado_actual        : std_logic_vector(2 downto 0) := "000";
	signal estado_siguiente     : std_logic_vector(2 downto 0) := "000";

begin

 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                       Conexión de componentes                           |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+

	gen_addr: counter
	generic map(N => ADDR_W)
	port map(
		rst   => rst,
		rst_sync => rst_addr_sync,
		clk   => clk,
		ena   => addr_tick,
		count => addr_sram_aux 
	);


 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                         Maquina de estados                              |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+

    -- estados ----------------------------------------- 

	estados: process(clk,rst)
	begin
		if (rst = '1') then
		estado_act <= REPOSO;
		elsif rising_edge(clk) then
		estado_act <= estado_sig;
		end if;
	end process;
	
	-- lógica de próximo estado -------------------------
 
    word <= data_f2s when estado_act = CARGA_DATOS else
            data_s2f_r;

    prox_estado: process(estado_act, ena, rx_uart_empty, word, mem_uart,
						 flag_eof, clear_fin, flag_rotnew, ena_rot_ext)
	begin
		-- asignaciones por defecto
		estado_sig <= estado_act;
		case estado_act is
			when REPOSO =>
				if ena = '1' then
					if ena_rot_ext = '1' then
						estado_sig <= ROTACION;
					elsif rx_uart_empty = '0' then 
						estado_sig <= CARGA_DATOS;
					else 
						estado_sig <= REPOSO;
					end if; 
				end if;        
			when CARGA_DATOS =>
			-- acá llega al final del archivo, luego me aseguro que
			-- se escriba en memoria leyendo el bit mem_uart
				if (word = EOF_WORD and mem_uart= '1') then
					estado_sig <= ROTACION;
				end if;        
			when ROTACION => 
				-- if (word = EOF_WORD) then
				if (flag_eof = '1' and word = EOF_WORD) then
					estado_sig <= ESPERA_ANG;
				end if;
			when ESPERA_ANG =>
				if ena = '1' then
					if flag_rotnew = '1' then
						estado_sig <= REFRESH_DPR;
					else 
						estado_sig <= ESPERA_ANG;
					end if;
				else
					estado_sig <= REPOSO;
				end if;
			when REFRESH_DPR => 
				if ena = '1' then
					if clear_fin = '1' then
						estado_sig <= ROTACION;
					else
						estado_sig <= REFRESH_DPR;
					end if;
				else 
					estado_sig <= REPOSO;
				end if;
		end case;
	end process;
    
 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                               Salidas                                   |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+
    
    
    
    
    -- Salidas del fsm -----------------------------------------

	salidas: process(estado_act, mem_uart, mem_cordic, addr_tick_uart,
                     addr_tick_cordic)
	begin
		-- asignación por defecto 
		rst_addr_sync <= '0'; -- reseteo de direccionamiento
		mem_aux <= '0'; -- comienzo de operacion sram (r ó w)
		rw_aux <= '1'; -- [0]: escritura; [1]: lectura
		addr_tick <= '0'; -- avance de direccionamiento
		ena_uart2sram_aux <= '0'; -- habilitación proceso uart2sram
		ena_sram2cordic_aux <= '0'; --habilitación proceso sram2cordic
		borrar_aux <= '0'; -- para refrescar vga cuando termina rotación
		case estado_act is
			when REPOSO =>
				rst_addr_sync <= '1';
			when CARGA_DATOS => -- proceso uart2sram
				mem_aux <= mem_uart;
				rw_aux <= '0';
				addr_tick <= addr_tick_uart;
				ena_uart2sram_aux <= '1';
			when ROTACION => -- proceso sram2cordic
				mem_aux <= mem_cordic;
				rw_aux <= '1';
				ena_sram2cordic_aux <= '1';
				addr_tick <= addr_tick_cordic;
			when ESPERA_ANG => 
			when REFRESH_DPR =>
				borrar_aux <= '1';
				rst_addr_sync <= '1';
				--mem_aux <= mem_cordic;
				--rw_aux <= '1';
				--addr_tick <= addr_tick_cordic;
				--ena_sram2cordic_aux <= '1';
		end case;
	end process;

    -- señales de salida ---------------
 
	addr_sram <= addr_sram_aux;
	rw <= rw_aux;
	mem <= mem_aux;
	ena_uart2sram <= ena_uart2sram_aux;
	ena_sram2cordic <= ena_sram2cordic_aux;
	borrar <= borrar_aux;
	-- Salida a 7 Segmentos
	state <= estado_actual; 


--#####################################################################    
--#       Señales para visualizar los estados en gtkwave 			--#
	estado_actual   <= "000" when estado_act = REPOSO else      	--# 
						"001" when estado_act = CARGA_DATOS else  	--#
						"010" when estado_act = ROTACION else     --#
						"011" when estado_act = ESPERA_ANG else   	--#
						"100" when estado_act = REFRESH_DPR else	--#
						"111";                             	--#
	estado_siguiente <=	"000" when estado_sig = REPOSO else     	--# 
						"001" when estado_sig = CARGA_DATOS else  	--#
						"010" when estado_sig = ROTACION else     --#
						"011" when estado_sig = ESPERA_ANG else	--#
						"100" when estado_sig = REFRESH_DPR else	--#
						"111";                                --#
--#####################################################################

end gral_ctrl_arch;    
 
