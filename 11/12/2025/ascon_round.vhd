library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;

entity ascon_round is
    port (
        state_in  : in  ascon_state_t;
        round_c   : in  std_logic_vector(7 downto 0);
        state_out : out ascon_state_t
    );
end ascon_round;

architecture behavioral of ascon_round is

    -- Local Rotate Right Function to ensure correct bit ordering
    function rotr64(x : std_logic_vector; n : integer) return std_logic_vector is
    begin
        -- Rotates right: LSB moves to MSB position
        return x(n-1 downto 0) & x(63 downto n);
    end function;

begin

    process(state_in, round_c)
        variable x  : ascon_state_t; 
        variable t  : ascon_state_t;
    begin
        -- 1. Load Input
        x := state_in;

        -- 2. Addition of Round Constant (ARC)
        -- Ascon adds constant to the LEAST Significant Byte of x2 (Bits 7..0)
        x(2)(7 downto 0) := x(2)(7 downto 0) xor round_c;

        -- 3. Substitution Layer (S-Box)
        -- Step A: Linear Start
        x(0) := x(0) xor x(4);
        x(4) := x(4) xor x(3);
        x(2) := x(2) xor x(1);

        -- Step B: Non-linear (Chi)
        -- We calculate all 't' values based on the 'x' values from Step A
        t(0) := x(0) xor ((not x(1)) and x(2));
        t(1) := x(1) xor ((not x(2)) and x(3));
        t(2) := x(2) xor ((not x(3)) and x(4));
        t(3) := x(3) xor ((not x(4)) and x(0));
        t(4) := x(4) xor ((not x(0)) and x(1));

        -- Step C: Linear End
        -- Note: These must follow the C reference sequence strictly
        t(1) := t(1) xor t(0);
        t(0) := t(0) xor t(4);
        t(3) := t(3) xor t(2);
        t(2) := not t(2);

        -- 4. Linear Diffusion Layer
        -- Apply rotations to the result of the S-Box (t)
        x(0) := t(0) xor rotr64(t(0), 19) xor rotr64(t(0), 28);
        x(1) := t(1) xor rotr64(t(1), 61) xor rotr64(t(1), 39);
        x(2) := t(2) xor rotr64(t(2), 1)  xor rotr64(t(2), 6);
        x(3) := t(3) xor rotr64(t(3), 10) xor rotr64(t(3), 17);
        x(4) := t(4) xor rotr64(t(4), 7)  xor rotr64(t(4), 41);

        -- Output
        state_out <= x;
    end process;

end behavioral;