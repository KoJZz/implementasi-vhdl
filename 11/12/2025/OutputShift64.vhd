library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity OutputShift64 is
    port (
        clk        : in  std_logic;
        En_output  : in  std_logic;                    -- Load 64-bit chunk
        shift_tx   : in  std_logic;                    -- Shift 8 bits
        data_in    : in  std_logic_vector(63 downto 0); -- From Ascon datapath (64-bit)
        data_out   : out std_logic_vector(7 downto 0)   -- To UART TX
    );
end entity;

architecture Behavioral of OutputShift64 is

    signal shift_reg : std_logic_vector(63 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then

            -- Load 64-bit from datapath
            if En_output = '1' then
                shift_reg <= data_in;

            -- UART requests next byte → shift 8 bits
            elsif shift_tx = '0' then
                shift_reg <= std_logic_vector(shift_right(unsigned(shift_reg), 8));
            end if;

        end if;
    end process;

    -- LSB byte goes to UART transmitter
    data_out <= shift_reg(7 downto 0);

end architecture Behavioral;
