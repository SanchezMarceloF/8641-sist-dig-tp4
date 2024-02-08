library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram2cordic is
	generic(
		COORD_W: natural := 13;
		DATA_W: natural := 16;
		ADDR_W: natural := 18
	);
	port(
		clk, rst, ena : in std_logic;
		-- hacia/desde rotador 3d
		coord_ready: out std_logic;
		flag_fin3d: in std_logic;
		x_coord: out std_logic_vector(COORD_W-1 downto 0);
		y_coord: out std_logic_vector(COORD_W-1 downto 0);
		z_coord: out std_logic_vector(COORD_W-1 downto 0);
		-- a gral_ctrl
		flag_eof: out std_logic;
		-- a sram_ctrl
		data_in: in std_logic_vector(DATA_W-1 downto 0);
		mem: out std_logic;
		ready: in std_logic;
		ena_count_tick: out std_logic
	);
end sram2cordic;

architecture sram2cordic_arch of sram2cordic is

    -- instanciacion de componentes --------------------------
 
	component registro is
	generic(N: natural := 4);
	port(
		D: in std_logic_vector(N-1 downto 0);
		clk, rst, ena: in std_logic;
		Q: out std_logic_vector(N-1 downto 0)
	);
	end component;

    -- señales ----------------------------------------------
    constant EOF_WORD: std_logic_vector(DATA_W-1 downto 0)
                     := (others => '1');
	constant FLAG_Z: integer:= 3; -- contador para flag_z
	constant FLAG_DPR: integer:= 2; -- contador para we dual port ram
	-- a gral_ctrl
	signal flag_eof_aux: std_logic;
    -- para registros de coordenadas
    signal wr_reg_tick   : std_logic := '0';
    signal coord_aux     : std_logic_vector(COORD_W-1 downto 0);
    signal z_reg         : std_logic_vector(COORD_W-1 downto 0);
    signal y_reg         : std_logic_vector(COORD_W-1 downto 0);
    signal x_reg         : std_logic_vector(COORD_W-1 downto 0);
    -- para dual port ram
    signal coord_ready_aux : std_logic := '0';
    -- para contador (direcciones a sram)
    signal ena_count_aux : std_logic := '0';
    -- para SRAM externa
    signal mem_aux       : std_logic := '0';
    -- variables de estado ---------------------------
    type t_estado is (REPOSO, LECTURA_SRAM, SHIFT_REG, ESPERA_SRAM,
                      ESPERA_ROTADOR);
    signal estado_act, estado_sig : t_estado;
    signal zcount_act, zcount_sig: unsigned(1 downto 0);

    -- señales para visualizar los estados en gtkwave ------------------
    signal estado_actual        : std_logic_vector(2 downto 0) := "000";
    signal estado_siguiente     : std_logic_vector(2 downto 0) := "000";

begin

	--###################  Registro de las coordenadas #####################--
	coord_aux <= data_in(COORD_W-1 downto 0); 
	x_coord_reg: registro generic map(COORD_W) 
                          port map(coord_aux, clk, rst, wr_reg_tick, z_reg);
	y_coord_reg: registro generic map(COORD_W)
                          port map(z_reg, clk, rst, wr_reg_tick, y_reg);
	z_coord_reg: registro generic map(COORD_W) 
                          port map(y_reg, clk, rst, wr_reg_tick, x_reg);
	--######################################################################--

   
    -- Máquina de estados ------------------------------
    --##################################################

    -- estados ----------------------------------------- 

    estados: process(clk,rst)
	begin
	    if (rst = '1') then
            estado_act <= REPOSO;
            zcount_act <= (others => '0');
        elsif rising_edge(clk) then
	        estado_act <= estado_sig;
            zcount_act <= zcount_sig;
 	    end if;
	end process;
   
	-- lógica de próximo estado -------------------------
  
	prox_estado: process(estado_act, zcount_act, ena, ready, data_in, flag_fin3d)
	begin
		-- asignaciones por defecto
		estado_sig <= estado_act;
		zcount_sig <= zcount_act;
		flag_eof_aux <= '0';
		case estado_act is
			when REPOSO =>
				if (ena = '1' and ready = '1') then
					estado_sig <= LECTURA_SRAM;
					end if;        
			when LECTURA_SRAM => -- duración 1 ciclo
					estado_sig <= ESPERA_SRAM;
			when ESPERA_SRAM =>
				if (ready = '1') then
					estado_sig <= SHIFT_REG;
				end if;
			when SHIFT_REG => -- duración 1 ciclo
				if data_in = EOF_WORD then
					estado_sig <= REPOSO;
					zcount_sig <= (others => '0');
					flag_eof_aux <= '1';
				elsif (zcount_act = FLAG_Z-1) then
					estado_sig <= ESPERA_ROTADOR;
					zcount_sig <= (others => '0');
				else    
					estado_sig <= LECTURA_SRAM;
					zcount_sig <= zcount_act + 1;
				end if;
			when ESPERA_ROTADOR => 	
				if (ena = '0') then
					estado_sig <= REPOSO;
				elsif (flag_fin3d = '1') then
					estado_sig <= LECTURA_SRAM;
				end if;    
		end case;
	end process;
    
    -- salidas del fsm -----------------------------------------

	salidas: process(estado_act)
	begin
	-- asignación por defecto 
		mem_aux <= '0';  
		wr_reg_tick <= '0';
		ena_count_aux <= '0';
		coord_ready_aux <= '0';
		case estado_act is
			when REPOSO =>
			when LECTURA_SRAM =>
				mem_aux <= '1';
			when SHIFT_REG =>
				wr_reg_tick <= '1';
				ena_count_aux <= '1';
			when ESPERA_SRAM =>
			when ESPERA_ROTADOR =>
				coord_ready_aux <= '1';
		end case;
	end process;

    -- Salidas ------------------------------------------------
    -- ########################################################

    mem <= mem_aux;
    ena_count_tick <= ena_count_aux;
    coord_ready <= coord_ready_aux;
    x_coord <= x_reg;
    y_coord <= y_reg;
    z_coord <= z_reg;
	flag_eof <= flag_eof_aux;
    
--####################################################################    
--#------ Señales para visualizar los estados en gtkwave ------------#
    estado_actual    <= "000" when estado_act = REPOSO else        --# 
                        "001" when estado_act = LECTURA_SRAM else  --#
                        "010" when estado_act = ESPERA_SRAM else --#
                        "011" when estado_act = SHIFT_REG else  --#
                        "100" when estado_act = ESPERA_ROTADOR else --#
                        "101";                    --#
                                                                   --#
    estado_siguiente <= "000" when estado_sig = REPOSO else        --#
                        "001" when estado_sig = LECTURA_SRAM else  --#
                        "010" when estado_sig = ESPERA_SRAM else --#
                        "011" when estado_sig = SHIFT_REG else  --#
                        "100" when estado_sig = ESPERA_ROTADOR else --#
                        "101";                              --#  
--####################################################################    

end sram2cordic_arch;    
 
