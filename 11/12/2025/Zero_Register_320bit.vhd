-- New Zero Register using ascon_state_t
library ieee;
use ieee.std_logic_1164.all;
use work.ascon_constants.all;  -- contains ascon_state_t, ascon_word_t

entity Zero_Register_AsconState is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        en         : in  std_logic;

        -- 64-bit word to be absorbed
        data_in_64 : in  ascon_word_t;

        -- ASCON state output
        state_out  : out ascon_state_t
    );
end entity;

architecture rtl of Zero_Register_AsconState is
    signal state_reg : ascon_state_t;
begin

    process (clk, reset)
    begin
        if reset = '1' then
            -- clear entire ASCON state
            state_reg <= (others => (others => '0'));

        elsif rising_edge(clk) then
            if en = '1' then
                -- default: zero everything
                state_reg <= (others => (others => '0'));

                -- absorb into x0 (change index if needed)
                state_reg(0) <= data_in_64;
            end if;
        end if;
    end process;

    state_out <= state_reg;

end architecture rtl;
