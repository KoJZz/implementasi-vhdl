library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;

entity ascon_round is
    port (
        state_in : in  ascon_state_t;
        round_c  : in  std_logic_vector(7 downto 0);
        state_out: out ascon_state_t
    );
end ascon_round;

architecture behavioral of ascon_round is
    
    -- Sinyal internal untuk menyimpan nilai state
    signal t : ascon_state_t;
    signal s_temp : ascon_state_t;

begin
    -- Sambungkan input state ke sinyal temporer untuk diproses
    s_temp <= state_in;

    process(state_in, round_c)
        
        variable v_t : ascon_state_t;
        variable v_s : ascon_state_t;
        
    begin
        -- Muat variable dari input langsung
        v_s := state_in;
        
        -- --- 1. Addition of Round Constant (ARC) ---
        v_s(2) := v_s(2) xor ("00000000000000000000000000000000000000000000000000000000" & round_c);

        -- --- 2. Substitution Layer (S-Box) ---
        v_t(0) := (v_s(4) and v_s(1)) xor v_s(3) xor ((not v_s(2)) and v_s(1)) xor v_s(2) xor (v_s(1) and v_s(0)) xor v_s(1) xor v_s(0);
        v_t(1) := v_s(4) xor ((v_s(3)) and v_s(2)) xor (v_s(3) and v_s(1)) xor v_s(3) xor (v_s(2) and v_s(1)) xor v_s(2) xor v_s(1) xor v_s(0);
        v_t(2) := (v_s(4) and v_s(3)) xor v_s(4) xor v_s(2) xor v_s(1) xor x"0000000000000001";
        v_t(3) := (v_s(4) and v_s(0)) xor v_s(4) xor (v_s(3) and v_s(0)) xor v_s(3) xor v_s(2) xor v_s(1) xor v_s(0);
        v_t(4) := (v_s(4) and v_s(1)) xor v_s(4) xor v_s(3) xor (v_s(1) and v_s(0)) xor v_s(1);
        
        -- --- 3. Linear Diffusion Layer ---
        v_s(0) := v_t(0) xor ROTR(v_t(0), ROR_C0_19) xor ROTR(v_t(0), ROR_C0_28);
        v_s(1) := v_t(1) xor ROTR(v_t(1), ROR_C1_61) xor ROTR(v_t(1), ROR_C1_39);
        v_s(2) := v_t(2) xor ROTR(v_t(2), ROR_C2_1)  xor ROTR(v_t(2), ROR_C2_6);
        v_s(3) := v_t(3) xor ROTR(v_t(3), ROR_C3_10) xor ROTR(v_t(3), ROR_C3_17);
        v_s(4) := v_t(4) xor ROTR(v_t(4), ROR_C4_7)  xor ROTR(v_t(4), ROR_C4_41);

        -- Output assigned immediately (Combinatorial)
        state_out <= v_s;
    end process;
end behavioral;