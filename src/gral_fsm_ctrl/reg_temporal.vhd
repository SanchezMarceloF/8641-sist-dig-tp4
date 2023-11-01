library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_temporal is
	generic(
		COORD_W: natural := 13;
		DATA_W: natural := 16;
		ADDR_W: natural := 18
	);
	port(
		clk, rst, ena: in std_logic;
		-- a dual port ram
		wr_dpr_tick: out std_logic;
		-- hacia/desde rotador 3d
		x_coord: out std_logic_vector(COORD_W-1 downto 0);
		y_coord: out std_logic_vector(COORD_W-1 downto 0);
		z_coord: out std_logic_vector(COORD_W-1 downto 0);
		-- a uart
		data_in: in std_logic_vector(DATA_W-1 downto 0);
		mem: in std_logic;
		ready_uart: out std_logic
	);
end reg_temporal;

architecture reg_temporal_arch of reg_temporal is

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
	-- para uart ----------------------------------------------
	signal ready_aux: std_logic;	
	-- para registros de coordenadas
	signal wr_reg_tick  : std_logic := '0';
	signal coord_aux    : std_logic_vector(COORD_W-1 downto 0);
	signal x_reg        : std_logic_vector(COORD_W-1 downto 0);
	signal y_reg         : std_logic_vector(COORD_W-1 downto 0);
	signal z_reg         : std_logic_vector(COORD_W-1 downto 0);
	-- para dual port ram
	signal wr_dpr_tick_aux : std_logic := '0';
	-- variables de estado ---------------------------
	type t_estado is (REPOSO, LECTURA_UART, SHIFT_REG,
					  AVANCE_UART, ESCRITURA_DPR);
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
  
	prox_estado: process(estado_act, zcount_act, ena, mem, data_in)
	begin
		-- asignaciones por defecto
		estado_sig <= estado_act;
		zcount_sig <= zcount_act;
		case estado_act is
			when REPOSO =>
				if (ena = '1') then
					estado_sig <= LECTURA_UART;
				end if;        
			when LECTURA_UART => -- espera hasta terminar lectura UART
				if (mem = '1') then
					estado_sig <= SHIFT_REG;
				end if;	
			when SHIFT_REG => -- duración 1 ciclo
				if data_in = EOF_WORD then
					estado_sig <= REPOSO;
				else 
					estado_sig <= AVANCE_UART;
				end if;
			when AVANCE_UART =>
				if (zcount_act = FLAG_Z-1) then
					estado_sig <= ESCRITURA_DPR;
					zcount_sig <= (others => '0');
				else    
					estado_sig <= LECTURA_UART;
					zcount_sig <= zcount_act + 1;
				end if;
			when ESCRITURA_DPR => 	
				if (ena = '0') then
					estado_sig <= REPOSO;
				elsif (zcount_act = FLAG_DPR-1) then
					estado_sig <= LECTURA_UART;
					zcount_sig <= (others => '0');
				else
					zcount_sig <= zcount_act + 1;
				end if;
		end case;
	end process;
    
	-- salidas del fsm -----------------------------------------

	salidas: process(estado_act)
	begin
	-- asignación por defecto 
		wr_reg_tick <= '0';	-- avance registros de coordenadas
		ready_aux <= '0'; -- avance registros uart
		wr_dpr_tick_aux <= '0'; -- habilitación escritura dual port ram
		case estado_act is
			when REPOSO =>
			when LECTURA_UART =>
			when SHIFT_REG =>
				wr_reg_tick <= '1';
			when AVANCE_UART =>
				ready_aux <= '1';
			when ESCRITURA_DPR =>
				wr_dpr_tick_aux <= '1';
		end case;
	end process;

	-- Salidas ------------------------------------------------
	-- ########################################################
	
	ready_uart <= ready_aux;
	wr_dpr_tick <= wr_dpr_tick_aux;
	x_coord <= x_reg;
	y_coord <= y_reg;
	z_coord <= z_reg;
    
--######################################################################    
--#------ Señales para visualizar los estados en gtkwave --------------#
	estado_actual  	<= 	"000" when estado_act = REPOSO else       --# 
						"001" when estado_act = LECTURA_UART else  --#
						"010" when estado_act = SHIFT_REG else  	--#
						"011" when estado_act = AVANCE_UART else 	--#
						"100" when estado_act = ESCRITURA_DPR else --#
						"101";                               --#
                                                                   --#
	estado_siguiente <=	"000" when estado_sig = REPOSO else       --#
						"001" when estado_sig = LECTURA_UART else  --#
						"010" when estado_sig = SHIFT_REG else  	--#
						"011" when estado_sig = AVANCE_UART else 	--#
						"100" when estado_sig = ESCRITURA_DPR else --#
						"101";                               --#  
--#####################################################################    

end reg_temporal_arch;    
 
