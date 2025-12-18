library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity L_Downcounter is
    port (
        clk         : in  std_logic;                           -- Clock
        done        : in  std_logic;                           -- Pulsa dari UART Tx
        length      : in  std_logic_vector(7 downto 0);        -- Panjang L
        done_output : out std_logic                             -- 1 saat count = 0
    );
end entity;

architecture Behavioral of L_Downcounter is

    signal count_reg      : unsigned(7 downto 0) := (others => '0');
    signal length_loaded  : std_logic := '0';

begin

    -------------------------------------------------------------------------
    -- Tanpa reset: length hanya dimuat sekali saat start
    -- Setelah itu setiap done = 1 --> decrement
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            -- Load once at the beginning
            if length_loaded = '0' then
                count_reg     <= unsigned(length);
                length_loaded <= '1';

            else
                -- Decrement only when done = 1
                if done = '1' then
                    if count_reg /= 0 then
                        count_reg <= count_reg - 1;
                    end if;
                end if;
            end if;

        end if;
    end process;

    -------------------------------------------------------------------------
    -- Output: 1 jika counter sudah 0
    -------------------------------------------------------------------------
    done_output <= '1' when count_reg = 0 else '0';

end architecture Behavioral;
