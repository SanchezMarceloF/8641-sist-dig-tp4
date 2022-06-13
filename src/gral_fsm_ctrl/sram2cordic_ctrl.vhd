library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram2cordic_ctrl is
    generic(
        COORD_W: natural := 13;
        DATA_W: natural := 16;
		ADDR_W: natural := 18
    );
    port(
        clk, rst, ena : in std_logic;
        -- a dual port ram
        wr_dpr_tick: out std_logic;
        -- hacia/desde rotador 3d
        flag_fin: in std_logic;
        x_coord: out std_logic_vector(COORD_W-1 downto 0);
        y_coord: out std_logic_vector(COORD_W-1 downto 0);
        z_coord: out std_logic_vector(COORD_W-1 downto 0);
        -- a SRAM externa
        we_n, oe_n: out std_logic;
        ad : out std_logic_vector(ADDR_W-1 downto 0);
        dio_a : inout std_logic_vector(DATA_W-1 downto 0);
        ce_a_n, ub_a_n, lb_a_n : out std_logic
    );
end sram2cordic_ctrl;

architecture sram2cordic_ctrl_arch of sram2cordic_ctrl is

    -- instanciacion de componentes --------------------------
 
    component sram_ctrl is
    generic(DATA_W: natural := 16;
			ADDR_W: natural := 18);
    port(
        clk, reset: in std_logic;
        -- to/from main system
        mem: in std_logic;
        rw: in std_logic;
        addr: in std_logic_vector(ADDR_W-1 downto 0);
        data_f2s: in std_logic_vector(DATA_W-1 downto 0);
        ready: out std_logic;
        data_s2f_r, data_s2f_ur: out std_logic_vector(DATA_W-1 downto 0);
        ce_in_n, lb_in_n, ub_in_n: in std_logic; 
        -- to/from chip
        ad: out std_logic_vector(ADDR_W-1 downto 0);
        we_n, oe_n: out std_logic;
        -- SRAM chip a
        dio_a: inout std_logic_vector(DATA_W-1 downto 0);
        ce_a_n, ub_a_n, lb_a_n: out std_logic
    );
    end component;

    component registro is
	generic(N: natural := 4);
	port(
		D: in std_logic_vector(N-1 downto 0);
		clk, rst, ena: in std_logic;
		Q: out std_logic_vector(N-1 downto 0)
	);
    end component;

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

    constant FLAG_Z: integer:= 3; -- contador para flag_z 
    signal ena_fsm       : std_logic := '0';
    signal rst_count_sinc: std_logic:= '0';
    -- para registros de coordenadas
    signal wr_reg_tick   : std_logic := '0';
    signal coord_aux     : std_logic_vector(COORD_W-1 downto 0);
    signal z_reg         : std_logic_vector(COORD_W-1 downto 0);
    signal y_reg         : std_logic_vector(COORD_W-1 downto 0);
    signal x_reg         : std_logic_vector(COORD_W-1 downto 0);
    -- para dual port ram
    signal wr_dpr_tick_aux : std_logic := '0';
    -- para contador (direcciones a sram)
    signal ena_count_tick : std_logic := '0';
    -- para SRAM externa
    signal mem_aux       : std_logic := '0';
    signal rw_aux        : std_logic := '1';
    signal ready_aux     : std_logic := '0';
    --signal flag_z        : std_logic := '0';
    signal addr_aux      : std_logic_vector(ADDR_W-1 downto 0) 
                         := (others => '0');
    signal addr_max      : std_logic_vector(ADDR_W-1 downto 0) 
                         :=
                         std_logic_vector(to_unsigned(27, ADDR_W));
    signal data_f2s_aux  : std_logic_vector(DATA_W-1 downto 0) 
                         := (others => '0');
    signal data_s2f_r_aux: std_logic_vector(DATA_W-1 downto 0) 
                         := (others => '0');
    signal data_s2f_ur_aux: std_logic_vector(DATA_W-1 downto 0); 
    -- variables de estado ---------------------------
    type t_estado is (REPOSO, LECTURA_SRAM, SHIFT_REG, ESPERA_SRAM,
                      ESCRITURA_DPR, ESPERA_CORDIC);
    signal estado_act, estado_sig : t_estado;
    signal zcount_act, zcount_sig: unsigned(1 downto 0);

    -- señales para visualizar los estados en gtkwave ------------------
    signal estado_actual        : std_logic_vector(2 downto 0) := "000";
    signal estado_siguiente     : std_logic_vector(2 downto 0) := "000";

begin

    --###################  Registro de las coordenadas #####################--
    coord_aux <= data_s2f_r_aux(COORD_W-1 downto 0); 
	x_coord_reg: registro generic map(COORD_W) 
                          port map(coord_aux, clk, rst, wr_reg_tick, z_reg);
    y_coord_reg: registro generic map(COORD_W)
                          port map(z_reg, clk, rst, wr_reg_tick, y_reg);
	z_coord_reg: registro generic map(COORD_W) 
                          port map(y_reg, clk, rst, wr_reg_tick, x_reg);
    --######################################################################--

   
    sram_ctrl_inst: sram_ctrl
    generic map(
        DATA_W => DATA_W,
		ADDR_W => ADDR_W
    )
    port map(
        clk     => clk,
        reset   => rst,
        -- to/from main system
        mem         => mem_aux,
        rw          => rw_aux,
        addr        => addr_aux,
        data_f2s    => data_f2s_aux,
        ready       => ready_aux,
        data_s2f_r  => data_s2f_r_aux,
        data_s2f_ur => data_s2f_ur_aux,
        ce_in_n     => '0',
        lb_in_n     => '0',
        ub_in_n     => '0',
        -- to/from chip
        ad      => ad,          
        we_n    => we_n,
        oe_n    => oe_n,
        -- SRAM chip a
        dio_a   => dio_a,
        ce_a_n  => ce_a_n,
        ub_a_n  => ub_a_n,
        lb_a_n  => lb_a_n 
    );

    gen_addr: counter
    generic map(N => ADDR_W)
    port map(
        rst   => rst,
        rst_sync => rst_count_sinc,
        clk   => clk,
        ena   => ena_count_tick,
        count => addr_aux
    );

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
  
    ena_fsm <= ena;

    prox_estado: process(estado_act, zcount_act, ena_fsm, ready_aux, flag_fin)
	begin
        -- asignaciones por defecto
        estado_sig <= estado_act;
        zcount_sig <= zcount_act;
	    case estado_act is
            when REPOSO =>
                if (ena_fsm = '1' and ready_aux = '1') then
                    estado_sig <= LECTURA_SRAM;
                end if;        
            when LECTURA_SRAM => -- duración 1 ciclo
                estado_sig <= ESPERA_SRAM;
            when ESPERA_SRAM => 
                if (ready_aux = '1') then
                    estado_sig <= SHIFT_REG;
                end if;
            when SHIFT_REG => -- duración 1 ciclo
                if (zcount_act = FLAG_Z-1) then
                    estado_sig <= ESCRITURA_DPR;
                    zcount_sig <= (others => '0');
                else    
                    estado_sig <= LECTURA_SRAM;
                    zcount_sig <= zcount_act + 1;
                end if;        
            when ESCRITURA_DPR => -- duración 1 ciclo
                 estado_sig <= ESPERA_CORDIC;
            when ESPERA_CORDIC => 
                if (addr_aux >= addr_max) then
                    estado_sig <= REPOSO;
                elsif (flag_fin = '1') then
                    estado_sig <= LECTURA_SRAM;
                end if;    
        end case;
    end process;
    
    -- salidas del fsm -----------------------------------------

    salidas: process(estado_act)
    begin
        -- asignación por defecto 
        rst_count_sinc <= '0';
        mem_aux <= '0';  
        wr_reg_tick <= '0';
        ena_count_tick <= '0';
        wr_dpr_tick_aux <= '0';
        case estado_act is
            when REPOSO =>
                rst_count_sinc <= '1';
            when LECTURA_SRAM =>
                mem_aux <= '1';
		    when SHIFT_REG =>
                wr_reg_tick <= '1';
                ena_count_tick <= '1';
            when ESPERA_SRAM =>
            when ESCRITURA_DPR =>
                wr_dpr_tick_aux <= '1';
            when ESPERA_CORDIC =>    
        end case;
    end process;

    -- Salidas ------------------------------------------------
    -- ########################################################

    wr_dpr_tick <= wr_dpr_tick_aux;
    x_coord <= x_reg;
    y_coord <= y_reg;
    z_coord <= z_reg;
    
--####################################################################    
--#------ Señales para visualizar los estados en gtkwave ------------#
    estado_actual    <= "000" when estado_act = REPOSO else        --# 
                        "001" when estado_act = LECTURA_SRAM else  --#
                        "010" when estado_act = ESPERA_SRAM else --#
                        "011" when estado_act = SHIFT_REG else  --#
                        "100" when estado_act = ESCRITURA_DPR else --#
                        "101" when estado_act = ESPERA_CORDIC else --#
                        "111";                                     --#
                                                                   --#
    estado_siguiente <= "000" when estado_sig = REPOSO else        --#
                        "001" when estado_sig = LECTURA_SRAM else  --#
                        "010" when estado_sig = ESPERA_SRAM else --#
                        "011" when estado_sig = SHIFT_REG else  --#
                        "100" when estado_sig = ESCRITURA_DPR else --#
                        "101" when estado_sig = ESPERA_CORDIC else --#
                        "111";                                     --#  
--####################################################################    

end sram2cordic_ctrl_arch;    
 
