library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_7seg is
    port(
		clk, rst: in std_logic;
		-- a sram2cordic
		gral_ctrl_state: in std_logic_vector(2 downto 0);
		uart2sram_state: in std_logic_vector(2 downto 0);
		sram2cordic_state: in std_logic_vector(2 downto 0);
		rotador3d_state: in std_logic_vector(2 downto 0);
		sal_7seg: out std_logic_vector(11 downto 0)
	);
end ctrl_7seg;

architecture ctrl_7seg_arch of ctrl_7seg is

    -- instanciacion de componentes --------------------------
 
	component ena_20mili is
	generic (
		N: natural := 1024	-- cantidad de ciclos a contar
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ena: in std_logic;
		sal: out std_logic	--
		--out_2: out std_logic  --
	);
	end component;
	
	component deco_BCDa7seg is
	port(
	inBCD : in std_logic_vector (3 downto 0);
	segm : out std_logic_vector (7 downto 0)
	);
	end component;


    -- señales ----------------------------------------------

	constant COUNT: natural := 262144; -- = 2**18
	signal tick: std_logic:= '0';
	-- a decodificador
	signal inBCD_aux : std_logic_vector(3 downto 0);
	signal segm_aux: std_logic_vector(7 downto 0);
	-- a salida
	signal display_sel: std_logic_vector(3 downto 0);
	-- variables de estado --------------------------------------
	type t_estado is (GRAL_CTRL, UART2SRAM, SRAM2CORDIC, ROTADOR3D);
	signal estado_act, estado_sig : t_estado;
	-- señales para visualizar los estados en gtkwave ------------------
	signal estado_actual        : std_logic_vector(1 downto 0) := "00";
	--signal estado_siguiente     : std_logic_vector(2 downto 0) := "000";

begin

 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                       Conexión de componentes                           |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+

	gen_tick: ena_20mili --habilita cada ~ 5 ms el cambio display
	generic map( N => COUNT )	-- cantidad de ciclos a contar
	-- generic map( N => 512)	-- cantidad de ciclos a contar
	port map(
			clk => clk, rst => rst, ena => '1',
			sal => tick
	);
	
	deco7segm_inst: deco_BCDa7seg
	port map (
	inBCD => inBCD_aux,
	segm => segm_aux
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
		estado_act <= GRAL_CTRL;
		elsif rising_edge(clk) then
		estado_act <= estado_sig;
		end if;
	end process;
	
	-- lógica de próximo estado -------------------------

   prox_estado: process(estado_act, tick)
	begin
		-- asignaciones por defecto
		estado_sig <= estado_act;
		case estado_act is
			when GRAL_CTRL =>
				if tick = '1' then
					estado_sig <= UART2SRAM;
				end if;        
			when UART2SRAM =>
				if tick = '1' then
					estado_sig <= SRAM2CORDIC;
				end if;
			when SRAM2CORDIC =>
				if tick = '1' then
					estado_sig <= ROTADOR3D;
				end if;
			when ROTADOR3D =>
				if tick = '1' then
					estado_sig <= GRAL_CTRL;
				end if; 
		end case;
	end process;
    
 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                               Salidas                                   |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+
    
  
    -- Salidas del fsm -----------------------------------------

	salidas: process(estado_act, gral_ctrl_state, uart2sram_state, 
					 sram2cordic_state, rotador3d_state)
	begin
		-- asignación por defecto 
		display_sel <= "1110";
		inBCD_aux <= "0" & gral_ctrl_state;
		case estado_act is
			when GRAL_CTRL =>
			when UART2SRAM =>
				display_sel <= "1101";
				inBCD_aux <= "0" & uart2sram_state;
			when SRAM2CORDIC =>
				display_sel <= "1011";
				inBCD_aux <= "0" & sram2cordic_state;
			when ROTADOR3D => 
				display_sel <= "0111";
				inBCD_aux <= "0" & rotador3d_state;
		end case;
	end process;

   -- señales de salida ---------------
 
	sal_7seg <= display_sel & segm_aux;


--#####################################################################    
--#       Señales para visualizar los estados en gtkwave 			--#
	estado_actual   <= "00" when estado_act = GRAL_CTRL else      	--# 
						"01" when estado_act = UART2SRAM else  	--#
						"10" when estado_act = SRAM2CORDIC else     --#
						"11";                             	--#
	-- estado_siguiente <=	"000" when estado_sig = REPOSO else     	--# 
						-- "001" when estado_sig = CARGA_DATOS else  	--#
						-- "010" when estado_sig = ROTACION else     --#
						-- "011" when estado_sig = ESPERA_ANG else	--#
						-- "100" when estado_sig = REFRESH_DPR else	--#
						-- "111";                                --#
--#####################################################################

end ctrl_7seg_arch;    
 
