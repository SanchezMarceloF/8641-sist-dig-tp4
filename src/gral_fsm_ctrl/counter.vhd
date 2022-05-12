library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    generic (N : natural := 8);
    port(
        rst : in std_logic;
        clk : in std_logic;
        ena : in std_logic;
        count : out std_logic_vector(N-1 downto 0)
    );
end counter;

-- cuerpo de arquitectura
architecture behavioral of counter is

    -- señales
    signal aux_count : unsigned(N-1 downto 0);

begin

    process(clk,rst)
    begin
        if rst='1' then
            aux_count <= (others => '0');
        elsif clk = '1' and clk'event then
            if ena = '1' then
                aux_count <= aux_count + 1;
            end if;
        end if;
    end process;

    count <= std_logic_vector(aux_count);

end behavioral;
