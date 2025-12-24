 -- definisi library yang digunakan
library ieee;
use ieee.std_logic_1164.all;
use work.ascon_constants.all;

-- definisi entity
entity ascon_state_register is
    port (
        -- control signal
		  done_pad_fromRX : in std_logic; --DIUPDATE done_pad dari RX (message kelipatan 64)
        clk        : in std_logic;
        reset      : in std_logic; 
        enable     : in std_logic; 
        mux_select    : in std_logic_vector(1 downto 0); -- 00: Init, 10: Permutation, 01: Absorb
        
        -- input dari ascon-p dan hasil padding
        data_from_permutation : in ascon_state_t;
        data_from_absorbing   : in ascon_state_t;
        
        -- output
        current_state_out     : out ascon_state_t;
        rate_out              : out ascon_word_t
    );
end entity;

architecture rtl of ascon_state_register is
	constant ASCON_IV : ascon_state_t := (
		 0 => x"0000080000cc0003", -- x0 (LSB word)
		 1 => (others => '0'),
		 2 => (others => '0'),
		 3 => (others => '0'),
		 4 => (others => '0')
	);
    signal reg_current : ascon_state_t;
    signal mux_output  : ascon_state_t;

begin
    -- MUX
    process(mux_select, data_from_permutation, data_from_absorbing, reg_current)
    begin
        case mux_select is
            when "00" =>
                mux_output <= ASCON_IV;
            when "10" =>
                mux_output <= data_from_permutation;
            when "01" =>
                mux_output <= data_from_absorbing;
            when others =>
                mux_output <= reg_current;
        end case;
    end process;

    -- Register
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reg_current <= ASCON_IV;
            elsif enable = '1' then
                reg_current <= mux_output;
					 if done_pad_fromRX = '1' then -- DIUPDATE buat pad message kelipatan 64
						reg_current(0)(0) <= not mux_output(0)(0);
					 end if;
            end if;
        end if;
    end process;
	 
    -- output
    rate_out <= reg_current(0); -- output hanya rate
    current_state_out <= reg_current; -- output seluruh state

end architecture;