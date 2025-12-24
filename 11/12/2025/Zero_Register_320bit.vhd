-- New Zero Register using ascon_state_t
library ieee;
use ieee.std_logic_1164.all;
use work.ascon_constants.all;  -- contains ascon_state_t, ascon_word_t

entity Zero_Register_320bit is
    port (
        --clk        : in  std_logic; -- hapus ntar
        reset      : in  std_logic;
        en         : in  std_logic;

        -- 64-bit word to be absorbed
        data_in_64 : in  ascon_word_t;

        -- ASCON state output
        state_out  : out ascon_state_t
    );
end entity;

architecture rtl of Zero_Register_320bit is
begin
    -- No process, no clock. Immediate update.
    process(data_in_64, en)
    begin
        -- Default to all zeros
        state_out <= (others => (others => '0'));
        
        -- If enabled, put data in the first word
        if en = '1' then
            state_out(0) <= data_in_64;
        end if;
    end process;
end architecture rtl;
