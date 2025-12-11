-- ascon_p12_tb.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;
use std.textio.all;

entity ascon_p12_tb is
end ascon_p12_tb;

architecture behavioral of ascon_p12_tb is
    -- Deklarasi Komponen (Entitas yang diuji)
    component ascon_p12
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            enable   : in  std_logic;
            state_in : in  ascon_state_t;
            
            state_out: out ascon_state_t;
            ready    : out std_logic
        );
    end component;

    -- Sinyal Clock dan Reset
    signal tb_clk     : std_logic := '0';
    signal tb_rst     : std_logic := '1';
    signal tb_enable  : std_logic := '0';
    
    -- Sinyal I/O P12
    signal tb_state_in  : ascon_state_t;
    signal tb_state_out : ascon_state_t;
    signal tb_ready     : std_logic;

    -- Constants
    constant CLOCK_PERIOD : time := 10 ns;

    -- ====================================================
    -- FUNGSI UNTUK KONVERSI KE STRING HEX (Menggunakan IF/ELSIF untuk kompatibilitas)
    -- ====================================================
    function To_Hex (A: std_logic_vector) return string is
        variable Result: string(1 to A'length/4);
        variable Hex_Char: character;
        variable nibble: std_logic_vector(3 downto 0); 
    begin
        for I in A'range loop
            if (I mod 4 = 3) then 
                nibble := A(I downto I-3);
                
                if nibble = "0000" then Hex_Char := '0';
                elsif nibble = "0001" then Hex_Char := '1';
                elsif nibble = "0010" then Hex_Char := '2';
                elsif nibble = "0011" then Hex_Char := '3';
                elsif nibble = "0100" then Hex_Char := '4';
                elsif nibble = "0101" then Hex_Char := '5';
                elsif nibble = "0110" then Hex_Char := '6';
                elsif nibble = "0111" then Hex_Char := '7';
                elsif nibble = "1000" then Hex_Char := '8';
                elsif nibble = "1001" then Hex_Char := '9';
                elsif nibble = "1010" then Hex_Char := 'A';
                elsif nibble = "1011" then Hex_Char := 'B';
                elsif nibble = "1100" then Hex_Char := 'C';
                elsif nibble = "1101" then Hex_Char := 'D';
                elsif nibble = "1110" then Hex_Char := 'E';
                else Hex_Char := 'F';
                end if;
                
                -- Hitung posisi string (dari kiri ke kanan)
                Result( (A'length - I)/4 ) := Hex_Char;
            end if;
        end loop;
        return Result;
    end function To_Hex;

begin
    -- Instansiasi Unit Under Test (UUT)
    UUT_P12 : ascon_p12
        port map (
            clk       => tb_clk,
            rst       => tb_rst,
            enable    => tb_enable,
            state_in  => tb_state_in,
            state_out => tb_state_out,
            ready     => tb_ready
        );

    -- Clock Generator
    CLK_PROC : process
    begin
        loop
            wait for CLOCK_PERIOD / 2;
            tb_clk <= not tb_clk;
        end loop;
    end process CLK_PROC;

    -- Stimulus Process
    STIM_PROC : process
        variable expected_state : ascon_state_t;
        variable output_line    : line;
    begin
        -- 1. Setup Nilai Awal
        report "--- Memulai Simulasi Ascon P12 Testbench ---" severity note;
        
        -- Load Initial State (ASCON-XOF IV)
        tb_state_in(0) <= ASCON_XOF_IV_VAL;
        tb_state_in(1) <= (others => '0');
        tb_state_in(2) <= (others => '0');
        tb_state_in(3) <= (others => '0');
        tb_state_in(4) <= (others => '0');

        -- Setup Expected State
        expected_state(0) := EXPECTED_X0;
        expected_state(1) := EXPECTED_X1;
        expected_state(2) := EXPECTED_X2;
        expected_state(3) := EXPECTED_X3;
        expected_state(4) := EXPECTED_X4;

        -- 2. Reset System
        tb_rst <= '1';
        wait for CLOCK_PERIOD * 2;
        tb_rst <= '0';
        wait for CLOCK_PERIOD * 2;
        
        report "Inisialisasi selesai. Memuat state awal..." severity note;
        
        -- 3. Mulai Permutasi P12 (Enable P12)
        tb_enable <= '1';
        wait until tb_ready = '1' and tb_clk = '1';
        tb_enable <= '0';
        
        report "P12 Selesai. Hasil state keluar." severity note;
        
        -- 4. Verifikasi Hasil
        wait for CLOCK_PERIOD; 

        -- Periksa semua 5 word
        if tb_state_out(0) = expected_state(0) and
           tb_state_out(1) = expected_state(1) and
           tb_state_out(2) = expected_state(2) and
           tb_state_out(3) = expected_state(3) and
           tb_state_out(4) = expected_state(4) then
            
            report "--- TEST BERHASIL: Hasil P12 cocok dengan nilai yang diharapkan. ---" severity note;
            
        else
            -- Laporan Kesalahan (Menggunakan writeline(output, ...) untuk TEXTIO)
            report "!!! TEST GAGAL: Hasil P12 TIDAK cocok dengan nilai yang diharapkan." severity error;
            
            write(output_line, string'("X0 Expected: ") & To_Hex(expected_state(0)));
            writeline(output, output_line); 
            
            write(output_line, string'("X0 Received: ") & To_Hex(tb_state_out(0)));
            writeline(output, output_line); 
            
            -- Hentikan simulasi
            assert false report "Simulasi Gagal." severity failure; 
        end if;
        
        wait;
    end process STIM_PROC;

end behavioral;