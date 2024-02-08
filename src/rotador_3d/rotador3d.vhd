-- declaracion de librerias y paquetes
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- la entrada X_0 = x0,y0,z0 se ingresa en formato complemento al módulo
-- alfa, beta, gamma son los angulos a rotar de los ejes x ,y ,z respectivamente.
-- la salida xn,yn,zn sale con módulo 2.72*|X_0| aprox en el mismo formato
-- Para utilizarlo en pto fijo, Se deja 1 bit para el signo y 2 para los enteros,
-- los restantes para los decimales
--'ctrl' on/off del rotador.
--'flag_rot' se pone en "1" cuando termina de rotar.

-- declaracion de entidad

entity rotador3d is
	generic(COORD_W: natural := 13;		--longitud de los vectores
			ANG_WIDE: natural := 15;	--longitud de los angulos
			ADDR_DP_W: natural := 9);	--longitud direcciones dpr
	port(
		rst, ena, clk: in std_logic;
		-- desde botones 
		pulsadores: in std_logic_vector(3 downto 0);
		-- hacia gral_ctrl
		rotnew: out std_logic;
		-- desde/hacia sram2cordic
		x_0, y_0, z_0: in std_logic_vector(COORD_W-1 downto 0);
		coord_ready: in std_logic;
		coord_ok: out std_logic;
		-- hacia dual port ram
		addr_dpr: out std_logic_vector(2*ADDR_DP_W-1 downto 0);
		dpr_tick: out std_logic
	);
end;

--declaracion de arquitectura

architecture rotador3d_arq of rotador3d is

	component registro is
	generic(N: natural := 4);
	port(
		D: in std_logic_vector(N-1 downto 0);
		clk, rst, ena: in std_logic;
		Q: out std_logic_vector(N-1 downto 0)
	);
	end component;
	
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

	component rotacion_ctrl is
		generic(M: integer := 15; 	--longitud del angulo a rotar
				N: integer := 13);	--longitud del dato a rotar
		port(
			clk, rst, ena: in std_logic;
			sel: in std_logic_vector(5 downto 0);
			alfa, beta, gamma: out std_logic_vector(M-1 downto 0)
	);
	end component;
	
	component cordic3d is
	generic(VECT_WIDE: natural := 13;
			ANG_WIDE: natural := 15);
	port(
		x_0, y_0, z_0: in std_logic_vector(VECT_WIDE-1 downto 0);
		alfa, beta, gama: in std_logic_vector(ANG_WIDE-1 downto 0);
		ctrl: in std_logic;		--'0' => x_0; '1' => x_i (comienza a rotar)
		clk: in std_logic;
		x_n, y_n, z_n: out std_logic_vector(VECT_WIDE-1 downto 0);
		flag_rot: out std_logic	
		);
	end component;
	
	component generador_direcciones is
	
	generic(N: integer := 13;	--longitud de los vectores
			L: integer := 9);	--longitud de las direcciones
	port(
		--flag: in std_logic;	--me avisa cuando termina de rotar.
		x, y: in std_logic_vector(N-1 downto 0);
		Addrx, Addry: out std_logic_vector(L-1 downto 0)
		--grabar: out std_logic
	);
	end component;
	
	-- señales ----------------------------------------------------------
	-- a registros
	signal regin_tick, regout_tick : std_logic:= '0';
	-- a Cordic 3d
	signal rot_ctrl, flag_fin : std_logic:= '0';
	signal x0_aux, y0_aux, z0_aux: std_logic_vector(COORD_W-1 downto 0);
	signal xn_aux, yn_aux, zn_aux: std_logic_vector(COORD_W-1 downto 0);
	-- salidas
	signal xn_reg, yn_reg, zn_reg: std_logic_vector(COORD_W-1 downto 0);
	signal dpr_tick_aux : std_logic:= '0';
	-- a rotacion_ctrl
	signal alfa_aux: std_logic_vector(ANG_WIDE-1 downto 0):= "000000000000000";
	signal beta_aux: std_logic_vector(ANG_WIDE-1 downto 0):= "000000000000000";
	signal gamma_aux: std_logic_vector(ANG_WIDE-1 downto 0):= "000000000000000";
	signal ena_ang, ena_rot : std_logic:= '0';
	signal eje_sel, rot: std_logic_vector(1 downto 0);
	signal sel_aux: std_logic_vector(5 downto 0);
	-- generador_direcciones 
	signal addrx_aux, addry_aux: std_logic_vector(ADDR_DP_W-1 downto 0);
	
	-- variables de estado ---------------------------
	type t_estado is (REPOSO, SHIFT_REG, ROTAR, SHIFT_REG_DPR,
						ESCRITURA_DPR);
	signal estado_act, estado_sig : t_estado;
	-- señales para visualizar los estados en gtkwave ------------------
	signal estado_actual		: std_logic_vector(2 downto 0) := "000";
	signal estado_siguiente   	: std_logic_vector(2 downto 0) := "000";

begin

	--############  Registro de las coordenadas de entrada ###############--
	x_0_reg: registro generic map(COORD_W) 
                          port map(x_0, clk, rst, regin_tick, x0_aux);
	y_0_reg: registro generic map(COORD_W)
                          port map(y_0, clk, rst, regin_tick, y0_aux);
	z_0_reg: registro generic map(COORD_W) 
                          port map(z_0, clk, rst, regin_tick, z0_aux);
	--#############  Registro de las coordenadas de salida ################--
	x_n_reg: registro generic map(COORD_W) 
                          port map(xn_aux, clk, rst, regout_tick, xn_reg);
	y_n_reg: registro generic map(COORD_W)
                          port map(yn_aux, clk, rst, regout_tick, yn_reg);
	z_n_reg: registro generic map(COORD_W) 
                          port map(zn_aux, clk, rst, regout_tick, zn_reg);
	--######################################################################--
	
	rotador: cordic3d
	generic map(VECT_WIDE => COORD_W,
				ANG_WIDE => ANG_WIDE)
	port map(
		x_0 => x0_aux, y_0 => y0_aux, z_0 => z0_aux,
		alfa => alfa_aux, beta => beta_aux, gama => gamma_aux,
		ctrl => rot_ctrl,  clk => clk,	--'0' => X_0; '1' => X_i (comienza a rotar)
		x_n => xn_aux, y_n => yn_aux, z_n => zn_aux,
		flag_rot => flag_fin
	);

   	-- Máquina de estados ------------------------------
	--##################################################

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
  
	prox_estado: process(estado_act, ena, coord_ready, flag_fin, xn_aux)
	begin
		-- asignaciones por defecto
		estado_sig <= estado_act;
		-- zcount_sig <= zcount_act;
		case estado_act is
			when REPOSO =>
				if (ena = '1' and coord_ready = '1') then
					estado_sig <= SHIFT_REG;
					end if;        
			when SHIFT_REG => -- duración 1 ciclo
					estado_sig <= ROTAR;
			when ROTAR =>
				if (flag_fin = '1') then
					if (signed(xn_aux) >= 0) then -- elimina transparencia
						estado_sig <= SHIFT_REG_DPR;
					else 
						estado_sig <= ESCRITURA_DPR;
					end if;
				end if;
			when SHIFT_REG_DPR => -- duración 1 ciclo
				estado_sig <= ESCRITURA_DPR;
			when ESCRITURA_DPR => -- duración 1 ciclo
				if (ena = '1' and coord_ready = '1') then
					estado_sig <= SHIFT_REG;
				else
					estado_sig <= REPOSO;
				end if;
 		end case;
	end process;
	
    -- salidas del fsm -----------------------------------------

	salidas: process(estado_act)
	begin
	-- asignación por defecto 
		regin_tick <= '0';  
		regout_tick <= '0';
		rot_ctrl <= '0';
		dpr_tick_aux <= '0';
		case estado_act is
			when REPOSO =>
			when SHIFT_REG =>
				regin_tick <= '1';
			when ROTAR =>
				rot_ctrl <= '1';
			when SHIFT_REG_DPR =>
				regout_tick <= '1';
			when ESCRITURA_DPR =>
				dpr_tick_aux <= '1';
		end case;
	end process;
	
	-- Generación de los ángulos

	eje_sel <= pulsadores(3 downto 2);
	rot <= pulsadores(1 downto 0);
	
	eje_select: process(eje_sel) -- selección del eje a rotar
	begin
		if eje_sel = "00" then
			sel_aux <= "000000";
		elsif eje_sel = "01" then
			sel_aux <= rot & "0000";
		elsif eje_sel = "10" then
			sel_aux <= "00" & rot & "00";
		else
			sel_aux <= "0000" & rot;
		end if;
	end process;
	
	enable_ang: ena_20mili --habilita cada 20 ms el cambio de angulo
	--generic map( N => 512 )
	generic map( N => 1048576 )	-- cantidad de ciclos a contar
	port map(
			clk => clk, rst => rst, ena => ena,
			sal => ena_ang
	);
	
	ena_rot <= ena and ena_ang;
	
	ctrl_rot: rotacion_ctrl
		generic map(M => ANG_WIDE, 	--longitud del angulo a rotar
				N => COORD_W) 	--longitud del dato a rotar
		port map(
			clk => clk, rst => rst, ena => ena_rot,
			sel => sel_aux,
			alfa => alfa_aux, beta => beta_aux, gamma => gamma_aux
			-- alfa => open, beta => open, gamma => open
	);
	
	gen_dir: generador_direcciones
	generic map(
		N => COORD_W, 
		L => ADDR_DP_W --longitud de las direcciones
	)
	port map(
		--x => xn_reg, y => yn_reg,
		x => yn_reg, y => zn_reg,
		Addrx => addrx_aux, Addry => addry_aux --direcciones a port A dual port RAM
	);
	
	-- Salidas ------------------------------------------------
	-- ########################################################

	coord_ok <= regin_tick;
	addr_dpr <= addrx_aux & addry_aux;
	dpr_tick <= dpr_tick_aux;
	rotnew <= ena_rot and (eje_sel(1) or eje_sel(0)) and (rot(1) or rot(0));
	   
--####################################################################    
--#------ Señales para visualizar los estados en gtkwave ------------#
    estado_actual    <= "000" when estado_act = REPOSO else        --# 
                        "001" when estado_act = SHIFT_REG else  --#
                        "010" when estado_act = ROTAR else --#
                        "011" when estado_act = SHIFT_REG_DPR else  --#
                        "100" when estado_act = ESCRITURA_DPR else --#
                        "111"; 			                    --#
                                                                   --#
    estado_siguiente <= "000" when estado_sig = REPOSO else        --#
                        "001" when estado_sig = SHIFT_REG else  --#
                        "010" when estado_sig = ROTAR else --#
                        "011" when estado_sig = SHIFT_REG_DPR else  --#
                        "100" when estado_sig = ESCRITURA_DPR else --#
                        "111";                                     --#  
--#################################################################### 

end;
