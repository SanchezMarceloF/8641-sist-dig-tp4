library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart2sram is
    generic(
        -- Default setting:
        -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
        DBIT_UART: integer:=8;     -- # data bits
        SB_TICK_UART: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
        DVSR_UART: integer:= 163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
        DVSR_BIT_UART: integer:=8; -- # bits of DVSR
        FIFO_W_UART: integer:=2;    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
        DATA_W: natural := 16;
		ADDR_W: natural := 18
    );
    port(
        clk, rst, ena : in std_logic;
        rx : in std_logic;
        tx : out std_logic;
        -- a sram_ctrl
        data_out : out std_logic_vector(DATA_W-1 downto 0);
        mem   : out std_logic;
        ready : in std_logic;
        addr_tick : out std_logic
    );
end uart2sram;

architecture uart2sram_arch of uart2sram is

    -- instanciacion de componentes --------------------------
 
    component uart is
    generic(
        -- Default setting:
        -- 19,200 baud, 8 data bis, 1 stop its, 2^2 FIFO
        DBIT: integer:=8;     -- # data bits
        SB_TICK: integer:=16; -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
        DVSR: integer:= 163;  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
        DVSR_BIT: integer:=8; -- # bits of DVSR
        FIFO_W: integer:=2    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
    );
    port(
        clk, reset: in std_logic;
        rd_uart, wr_uart: in std_logic;
        rx: in std_logic;
        w_data: in std_logic_vector(DBIT_UART-1 downto 0);
        tx_full, rx_empty: out std_logic;
        r_data: out std_logic_vector(DBIT_UART-1 downto 0);
        tx: out std_logic
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

     -- señales ----------------------------------------------
    signal addr_tick_aux : std_logic := '0';
    -- sram_ctrl --------------------------------------------                     
    signal mem_aux       : std_logic := '0';
    -- uart -------------------------------------------------
    signal wr_uart_tick  : std_logic := '0';
    signal rx_empty_aux  : std_logic := '0';
    signal tx_full_aux   : std_logic := '0';
    signal r_data_aux    : std_logic_vector(DBIT_UART-1 downto 0) 
                         := (others => '0');
    signal ub_data       : std_logic_vector(DBIT_UART-1 downto 0) 
                         := (others => '0');
    signal w_data_aux    : std_logic_vector(DBIT_UART-1 downto 0) 
                         := (others => '0');
    
    -- variables de estado ---------------------------------------
                         
    type t_estado is (REPOSO, LECTURA_UB, ESCRITURA, LIMPIEZA_UART,
                      ESPERA_SRAM) ;
    signal estado_act, estado_sig : t_estado;

    -- señales para visualizar los estados en gtkwave
    signal estado_actual        : std_logic_vector(2 downto 0) := "000";
    signal estado_siguiente     : std_logic_vector(2 downto 0) := "000";
    signal flag_ub_act, flag_ub_sig : std_logic:='0';

begin

 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                       Conexión de componentes                           |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+
    
    uart_inst: uart
    generic map(
        DBIT     => DBIT_UART,    -- # data bits
        SB_TICK  => SB_TICK_UART, -- # ticks for stop bits, 16/24/32
                            --   for 1/1.5/2 stop bits
        DVSR     => DVSR_UART,  -- baud rate divisor
                            -- DVSR = 50M/(16*baud rate)
        DVSR_BIT => DVSR_BIT_UART, -- # bits of DVSR
        FIFO_W   => FIFO_W_UART    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
    )
    port map(
        clk     => clk,
        reset   => rst,
        rd_uart => wr_uart_tick,
        wr_uart => '0',
        rx      => rx,
        w_data  => w_data_aux,
        tx_full => tx_full_aux,
        rx_empty=> rx_empty_aux,
        r_data  => r_data_aux,
        tx      => tx
    );

    reg_upper_bit: registro
	generic map(N => DBIT_UART)
	port map(
		D => r_data_aux, 
		clk => clk, rst => rst, ena => wr_uart_tick,
		Q => ub_data
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
            flag_ub_act <= '0';
        elsif rising_edge(clk) then
	        estado_act <= estado_sig;
            flag_ub_act <= flag_ub_sig;
 	    end if;
	end process;
   
	-- logica de proximo estado -------------------------
  
    prox_estado: process(estado_act, ena, ready, rx_empty_aux, flag_ub_act)
	begin
        estado_sig <= estado_act;
        flag_ub_sig <= flag_ub_act;
	    case estado_act is
            when REPOSO =>
                if ena = '1' and rx_empty_aux = '0' then
                    if flag_ub_act = '0' then
                        estado_sig <= LECTURA_UB;
                    else 
                        estado_sig <= ESCRITURA;
                        flag_ub_sig <= '0';
                    end if;
                end if;
            when LECTURA_UB => -- permanece 1 ciclo
                estado_sig <= REPOSO;
                flag_ub_sig <= '1';
            when ESCRITURA => -- permanece 1 ciclo
                estado_sig <= LIMPIEZA_UART;
            when LIMPIEZA_UART => -- permanece 1 ciclo
                estado_sig <= ESPERA_SRAM;
            when ESPERA_SRAM => 
                if ready = '1' then
                    if rx_empty_aux = '1' then -- buffer uart vacío
                        estado_sig <= REPOSO;
                    else  -- buffer uart con datos    
                        estado_sig <= LECTURA_UB;
                    end if;
                end if;    
        end case;
    end process;
    

 -- +-------------------------------------------------------------------------+
 -- |                                                                         |
 -- |                               Salidas                                   |
 -- |                                                                         |
 -- +-------------------------------------------------------------------------+
 
    -- salidas del fsm -----------------------------------------

    salidas: process(estado_act)
    begin
        -- asignación por defecto  
        mem_aux <= '0';  
        wr_uart_tick <= '0';
        addr_tick_aux <= '0';
        case estado_act is
            when REPOSO =>
            when LECTURA_UB =>
                wr_uart_tick <= '1';
            when ESCRITURA =>
                mem_aux <= '1';
		    when LIMPIEZA_UART =>
                wr_uart_tick <= '1';
                addr_tick_aux <= '1';
            when ESPERA_SRAM =>
        end case;
    end process;

    -- salidas uart2sram ------------------------------------------

    data_out <= ub_data & r_data_aux;
    mem <= mem_aux;
    addr_tick <= addr_tick_aux;


--####################################################################
    -- Señales para mostrar los estados en gktwave ------------------#
                                                                   --#
    estado_actual    <= "000" when estado_act = REPOSO else        --#
                        "001" when estado_act = LECTURA_UB else    --# 
                        "010" when estado_act = ESCRITURA else     --# 
                        "011" when estado_act = LIMPIEZA_UART else --#
                        "100";                                     --#
                                                                   --#
    estado_siguiente <= "000" when estado_sig = REPOSO else        --#
                        "001" when estado_sig = LECTURA_UB else    --# 
                        "010" when estado_sig = ESCRITURA else     --# 
                        "011" when estado_sig = LIMPIEZA_UART else --#
                        "100";                                     --#
--################################################################

end uart2sram_arch;    
 
