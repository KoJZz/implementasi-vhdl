-- definisi library yang digunakan
library ieee;
use ieee.std_logic_1164.all;

-- definisi entity
entity ascon_state_register is
    port (
        -- control signal
        clk        : in std_logic;
        reset      : in std_logic; 
        enable     : in std_logic; 
        mux_select    : in std_logic_vector(1 downto 0); -- 00: Init, 01: Permutation, 10: Absorb
        
        -- input dari ascon-p dan hasil padding
        data_from_permutation : in std_logic_vector(319 downto 0);
        data_from_absorbing   : in std_logic_vector(319 downto 0);
        
        -- output
        current_state_out     : out std_logic_vector(319 downto 0);
        rate_out              : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of ascon_state_register is
    constant ASCON_IV : std_logic_vector(319 downto 0) := (319 downto 64 => '0') & x"0000080000cc0003"; -- IV untuk ascon-xof

    signal reg_current : std_logic_vector(319 downto 0);
    signal mux_output  : std_logic_vector(319 downto 0);

begin
    -- MUX
    process(mux_select, data_from_permutation, data_from_absorbing)
    begin
        case mux_select is
            when "00" => 
                mux_output <= ASCON_IV; -- pilih IV
                
            when "10" => 
                mux_output <= data_from_permutation; -- pilih hasil ascon-p
                
            when "01" => 
                mux_output <= data_from_absorbing; -- pilih hasil absorbing
                
            when others =>
                mux_output <= reg_current; 
        end case;
    end process;

    -- Register
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reg_current <= (others => '0');
            elsif enable = '1' then
                reg_current <= mux_output; -- Load the value selected by MUX
            end if;
        end if;
    end process;

    -- output
    rate_out <= reg_current(63 downto 0); -- output hanya rate
    current_state_out <= reg_current; -- output seluruh state

end architecture;