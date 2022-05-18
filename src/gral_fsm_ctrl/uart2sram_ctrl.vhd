library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart2sram_ctrl is
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
        clk, rst : in std_logic;
        sw : in std_logic;
        rx : in std_logic;
        tx : out std_logic;
        we_n, oe_n: out std_logic;
        ad : out std_logic_vector(ADDR_W-1 downto 0);
        dio_a : inout std_logic_vector(DATA_W-1 downto 0);
        ce_a_n, ub_a_n, lb_a_n : out std_logic
    );
end uart2sram_ctrl;

architecture uart2sram_ctrl_arch of uart2sram_ctrl is

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
        w_data: in std_logic_vector(7 downto 0);
        tx_full, rx_empty: out std_logic;
        r_data: out std_logic_vector(7 downto 0);
        tx: out std_logic
    );
    end component;

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
        -- to/from chip
        ad: out std_logic_vector(ADDR_W-1 downto 0);
        we_n, oe_n: out std_logic;
        -- SRAM chip a
        dio_a: inout std_logic_vector(DATA_W-1 downto 0);
        ce_a_n, ub_a_n, lb_a_n: out std_logic
    );
    end component;

    component detect_flanco is
	port(
		clk, rst: in std_logic;
		secuencia: in std_logic;
		salida: out std_logic
		);
    end component;

    component debounce is
    port(
        clk, reset: in std_logic;
        sw: in std_logic;
        db_level, db_tick: out std_logic
    );
    end component;

    component counter is
    generic (N : natural := 8);
    port(
        rst : in std_logic;
        clk : in std_logic;
        ena : in std_logic;
        count : out std_logic_vector(N-1 downto 0)
    );
    end component;

    component mux is
    generic(N :integer:= 17);
    port (
	    A_0: in std_logic_vector(N-1 downto 0);
	    A_1: in std_logic_vector(N-1 downto 0);
	    sel: in std_logic;
	    sal: out std_logic_vector(N-1 downto 0) 
	);
    end component;


    -- señales ----------------------------------------------
    
    signal ena_fsm       : std_logic := '0';
    signal wr_uart_tick      : std_logic := '0';
    signal rx_empty_aux  : std_logic := '0';
    signal tx_full_aux   : std_logic := '0';
    signal sel_addr      : std_logic := '0';
    signal ena_count_tick : std_logic := '0';
    signal mem_aux       : std_logic := '0';
    signal rw_aux        : std_logic := '0';
    signal ready_aux     : std_logic := '0';
    signal r_data_aux    : std_logic_vector(7 downto 0) 
                         := (others => '0');
    signal addr_aux      : std_logic_vector(ADDR_W-1 downto 0) 
                         := (others => '0');
    signal data_f2s_aux  : std_logic_vector(DATA_W-1 downto 0) 
                         := (others => '0');
    signal data_s2f_r_aux: std_logic_vector(DATA_W-1 downto 0) 
                         := (others => '0');
    signal data_s2f_ur_aux: std_logic_vector(DATA_W-1 downto 0); 
    signal count_aux     : std_logic_vector(ADDR_W-1 downto 0) 
                         := (others => '0');
    signal addr_cordic   : std_logic_vector(ADDR_W-1 downto 0) 
                         := "000011110000111100";
    
    --signal reposo_count : unsigned(1 downto 0) := 0;
    -- variables de estado ----------------
                         
    type t_estado is (REPOSO, ESCRIBIENDO_1, ESCRIBIENDO_2);
    signal estado_act, estado_sig : t_estado;

    -- señales para visualizar los estados en gtkwave
    signal estado_actual        : std_logic_vector(1 downto 0) := "00";
    signal estado_siguiente     : std_logic_vector(1 downto 0) := "00";
begin
   
    -- estados ----------------------------------------- 

    estados: process(clk,rst)
	begin
	    if (rst = '1') then
            estado_act <= REPOSO;
        elsif rising_edge(clk) then
	        estado_act <= estado_sig;    
 	    end if;
	end process;
   
	-- logica de proximo estado -------------------------
  
    prox_estado: process(estado_act, ena_fsm, ready_aux, rx_empty_aux,
        wr_uart_tick)
	begin
	    case estado_act is
            when REPOSO =>
                if ena_fsm = '1' then
                    if (rx_empty_aux = '0' and ready_aux = '1'
                        and wr_uart_tick = '0') then 
                        estado_sig <= ESCRIBIENDO_1;
                    else
                        estado_sig <= REPOSO;
                    end if;
                else        
                    estado_sig <= REPOSO;
                end if;        
            when ESCRIBIENDO_1 =>
			    if ena_fsm = '1' then
                    if ready_aux = '1' then
                        estado_sig <= ESCRIBIENDO_1;
                    else    
                        estado_sig <= ESCRIBIENDO_2;
                    end if;    
                else
                    estado_sig <= REPOSO;
			    end if;
             when ESCRIBIENDO_2 =>
			    if ena_fsm = '1' then
                    if ready_aux = '0' then
                        estado_sig <= ESCRIBIENDO_2;
                    else    
                        estado_sig <= REPOSO;
                    end if;    
                else
                    estado_sig <= REPOSO;
			    end if;
   
        end case;
    end process;
    
    -- mapeo pines componentes -------------- ----------------
    
    mux_addr: mux
    generic map(N => ADDR_W)
    port map(
	    A_0 => count_aux,
	    A_1 => addr_cordic,
	    sel => sel_addr,
	    sal => addr_aux
	);


    contador: counter
    generic map(N => ADDR_W)
    port map(
        rst   => rst,
        clk   => clk, 
        ena   => ena_count_tick,
        count => count_aux
    );

    
    --antirebote: debounce
    --port map(
    --    clk      => clk, 
    --    reset    => rst,
    --    sw       => sw,
    --    db_level => ena_fsm,
    --    db_tick  => wr_uart_tick
    --);

    ena_fsm <= sw;

    addr_sig : detect_flanco 
	port map(
		clk       => clk,
        rst       => rst,
		secuencia => ready_aux,
		salida    => ena_count_tick
	);

    wr_uart_tick <= ena_count_tick;

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
        w_data  => data_s2f_r_aux(7 downto 0),
        tx_full => tx_full_aux,
        rx_empty=> rx_empty_aux,
        r_data  => r_data_aux,
        tx      => tx
    );
   
    data_f2s_aux <= "00000000" & r_data_aux; 

    sram_ctrl_inst : sram_ctrl
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




    -- salidas -----------------------------------------------

    mem_aux     <= '1' when estado_act = ESCRIBIENDO_1 else 
                            -- estado_act = ESCRIBIENDO_2) else
                   '0';
    rw_aux      <= '0' when (estado_act = ESCRIBIENDO_1 or
                             estado_act = ESCRIBIENDO_2) else
                   '1';
    sel_addr    <= '0' when (estado_act = ESCRIBIENDO_1 or 
                             estado_act = ESCRIBIENDO_2)  else
                   '1';
    estado_actual    <= "00" when estado_act = REPOSO else 
                        "01" when estado_act = ESCRIBIENDO_1 else
                        "10" when estado_act = ESCRIBIENDO_2 else
                        "11";

    estado_siguiente <= "00" when estado_sig = REPOSO else 
                        "01" when estado_sig = ESCRIBIENDO_1 else
                        "10" when estado_sig = ESCRIBIENDO_2 else
                        "11";
end uart2sram_ctrl_arch;    
 
