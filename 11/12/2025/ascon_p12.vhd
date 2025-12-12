library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;

entity ascon_p12 is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        enable   : in  std_logic;      -- Mulai permutasi
        state_in : in  ascon_state_t;
        
        state_out: out ascon_state_t;  -- State setelah P12
        ready    : out std_logic       -- '1' ketika P12 selesai
    );
end ascon_p12;

architecture structural of ascon_p12 is
    -- Komponen Round Function (Tanpa clk/rst)
    component ascon_round
        port (
            state_in : in  ascon_state_t;
            round_c  : in  std_logic_vector(7 downto 0);
            state_out: out ascon_state_t
        );
    end component;

    -- Sinyal internal untuk menyimpan state yang diperbarui
    signal current_state : ascon_state_t;
    -- Counter untuk 12 putaran (0 sampai 11)
    signal round_counter : unsigned(3 downto 0);
    -- Sinyal untuk Round Constant
    signal round_c_sig   : std_logic_vector(7 downto 0);
    -- Sinyal untuk I/O Round
    signal round_in  : ascon_state_t;
    signal round_out : ascon_state_t;
    -- Status FSM
    type state_type is (IDLE, ROUND_EXEC, FINISH);
    signal p12_state : state_type;
    
begin
    -- Instansiasi Komponen Round Function
    U_ASCON_ROUND: ascon_round
        port map (
            state_in  => round_in,
            round_c   => round_c_sig,
            state_out => round_out
        );
        
    -- Output ketika selesai
    state_out <= current_state when p12_state = FINISH else (others => (others => '0'));
    ready     <= '1' when p12_state = FINISH else '0';
    
    -- FSM untuk mengontrol 12 putaran
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                p12_state     <= IDLE;
                round_counter <= (others => '0');
                current_state <= (others => (others => '0'));
                round_c_sig   <= (others => '0');
            else
                case p12_state is
                    when IDLE =>
                        if enable = '1' then
                            -- Mulai P12
                            p12_state     <= ROUND_EXEC;
                            round_counter <= (others => '0'); -- Putaran ke-0
                            current_state <= state_in;
                            -- Inisialisasi input round untuk putaran 0
                            round_in      <= state_in;
                        end if;

                    when ROUND_EXEC =>
                        -- Round Constant untuk putaran saat ini
                        round_c_sig <= ROUND_CONSTANTS_P12(
                            (11 - to_integer(round_counter))*8 + 7 downto 
                            (11 - to_integer(round_counter))*8
                        );
                        
                        -- Update state setelah round selesai (mengambil round_out dari siklus sebelumnya)
                        current_state <= round_out;
                        
                        -- Round Counter
                        if round_counter = 11 then -- Putaran ke-11 selesai, total 12 putaran
                            p12_state <= FINISH;
                        else
                            round_counter <= round_counter + 1;
                            -- Set input round_in untuk round berikutnya
                            round_in <= round_out;
                        end if;
                        
                    when FINISH =>
                        if enable = '0' then
                            p12_state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

end structural;