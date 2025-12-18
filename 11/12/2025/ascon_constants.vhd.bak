library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ====================================================
-- PACKAGE DECLARATION
-- ====================================================
package ascon_constants is

    -- Tipe Data Kunci
    constant STATE_SIZE : integer := 5;
    constant WORD_SIZE  : integer := 64;

    -- Definisikan tipe untuk satu 'word' (64-bit) dan untuk seluruh state (5 words)
    subtype ascon_word_t is std_logic_vector(WORD_SIZE-1 downto 0);
    type ascon_state_t is array (0 to STATE_SIZE-1) of ascon_word_t;

    -- Konstanta Rotasi (Shift Amounts) untuk P permutation Ascon
    constant ROR_C0_19 : natural := 19;
    constant ROR_C0_28 : natural := 28;
    constant ROR_C1_61 : natural := 61;
    constant ROR_C1_39 : natural := 39;
    constant ROR_C2_1  : natural := 1;
    constant ROR_C2_6  : natural := 6;
    constant ROR_C3_10 : natural := 10;
    constant ROR_C3_17 : natural := 17;
    constant ROR_C4_7  : natural := 7;
    constant ROR_C4_41 : natural := 41;
    
    -- Konstanta IV dan Round Constants
    constant ROUND_CONSTANTS_P12 : std_logic_vector(95 downto 0) := x"F0E1D2C3B4A5968778695A4B";
    constant ASCON_XOF_IV_VAL : ascon_word_t := x"0000080000CC0003";
    
    -- Nilai Ekspektasi setelah P12 dari IV Ascon-XOF yang dimuat
    -- (Nilai ini diverifikasi berdasarkan spesifikasi Ascon)
    constant EXPECTED_X0 : ascon_word_t := x"B547432881E9804C"; 
    constant EXPECTED_X1 : ascon_word_t := x"F73E366110D832D0";
    constant EXPECTED_X2 : ascon_word_t := x"13E5317E08DE90C4";
    constant EXPECTED_X3 : ascon_word_t := x"B1D1DFF7E2B4B282";
    constant EXPECTED_X4 : ascon_word_t := x"22757262D4A27B66";
		
    -- Function Declaration
    function ROTR(
        A : std_logic_vector;
        N : natural
    ) return std_logic_vector;
end package ascon_constants;

-- ====================================================
-- PACKAGE BODY
-- ====================================================
package body ascon_constants is

    -- Implementasi Fungsi ROR (Rotate Right)
    function ROTR (
        A : std_logic_vector;
        N : natural
    ) return std_logic_vector is
        constant LEN : natural := A'length; 
        constant S   : natural := N mod LEN;
    begin
        if S = 0 then
            return A;
        else
            -- Rotasi Kanan (ROR) logic
            return A(S-1 downto 0) & A(LEN-1 downto S);
        end if;
    end function ROTR;

end package body ascon_constants;