library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SilenceTimer is
    generic (
        MAX_COUNT : unsigned(31 downto 0) := to_unsigned(100000, 32)  
        -- 100,000 clock = 1 ms @ 100 MHz
    );
    port (
        clk          : in  std_logic;
        en           : in  std_logic;               -- counter aktif
        rst          : in  std_logic;               -- reset ketika UART menerima byte
        done_message : out std_logic                -- 1 jika silence ≥ 1ms
    );
end entity;

architecture Behavioral of SilenceTimer is

    signal counter   : unsigned(31 downto 0) := (others => '0');
    signal done_reg  : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                counter  <= (others => '0');
                done_reg <= '0';

            elsif en = '1' then
                if done_reg = '0' then
                    counter <= counter + 1;

                    if counter = MAX_COUNT then
                        done_reg <= '1';        -- silence ≥ 1 ms
                    end if;
                end if;
            end if;

        end if;
    end process;

    done_message <= done_reg;

end architecture Behavioral;
