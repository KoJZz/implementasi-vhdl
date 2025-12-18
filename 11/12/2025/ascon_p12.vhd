library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;

entity ascon_p12 is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        enable    : in  std_logic;
        state_in  : in  ascon_state_t;
        state_out : out ascon_state_t;
        ready     : out std_logic
    );
end ascon_p12;

architecture rtl of ascon_p12 is

    component ascon_round
        port (
            state_in  : in  ascon_state_t;
            round_c   : in  std_logic_vector(7 downto 0);
            state_out : out ascon_state_t
        );
    end component;

    -- FSM states
    type state_type is (IDLE, ROUND_SETUP, ROUND_LATCH, FINISH);
    signal fsm_state : state_type;

    signal round_counter : unsigned(3 downto 0); -- 0 .. 11

    signal current_state : ascon_state_t;
    signal round_in      : ascon_state_t;
    signal round_out     : ascon_state_t;
    signal round_c_sig   : std_logic_vector(7 downto 0);

begin

    -- ASCON round (pure combinational)
    U_ASCON_ROUND : ascon_round
        port map (
            state_in  => round_in,
            round_c   => round_c_sig,
            state_out => round_out
        );

    -- Output handshake
    state_out <= current_state;
    ready     <= '1' when fsm_state = FINISH else '0';

    ------------------------------------------------------------------
    -- FSM
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fsm_state     <= IDLE;
                round_counter <= (others => '0');
                current_state <= (others => (others => '0'));
                round_in      <= (others => (others => '0'));
                round_c_sig   <= (others => '0');
            else
                case fsm_state is

                    --------------------------------------------------
                    when IDLE =>
                        if enable = '1' then
                            current_state <= state_in;
                            round_counter <= (others => '0');
                            fsm_state     <= ROUND_SETUP;
                        end if;

                    --------------------------------------------------
                    when ROUND_SETUP =>
                        -- Setup input & round constant
                        round_in <= current_state;
                        round_c_sig <= ROUND_CONSTANTS_P12(
                            (11 - to_integer(round_counter)) * 8 + 7 downto
                            (11 - to_integer(round_counter)) * 8
                        );
                        fsm_state <= ROUND_LATCH;

                    --------------------------------------------------
                    when ROUND_LATCH =>
                        -- Latch result of combinational round
                        current_state <= round_out;

                        if round_counter = 11 then
                            fsm_state <= FINISH;
                        else
                            round_counter <= round_counter + 1;
                            fsm_state <= ROUND_SETUP;
                        end if;

                    --------------------------------------------------
                    when FINISH =>
                        if enable = '0' then
                            fsm_state <= IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process;

end rtl;
