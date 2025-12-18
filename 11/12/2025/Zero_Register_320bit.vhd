library ieee;
use ieee.std_logic_1164.all;

entity Zero_Register_320bit is
    generic (
        DATA_WIDTH : integer := 320;
        LSB_WIDTH  : integer := 64    -- Lebar bit yang dimuat dari input (0 hingga 63)
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic; 
        En          : in  std_logic;  -- Enable dari FSM
        
        -- Input 64-bit yang akan mengisi bit 0-63
        data_in_64  : in  std_logic_vector(LSB_WIDTH - 1 downto 0); 
        
        -- Output 320-bit yang diumpankan ke XOR
        data_out_320 : out std_logic_vector(DATA_WIDTH - 1 downto 0) 
    );
end entity Zero_Register_320bit;


architecture RTL of Zero_Register_320bit is

    -- Sinyal internal untuk menyimpan nilai register
    signal state_internal : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Sinyal yang membawa data 320-bit baru (0 pada MSB, data_in_64 pada LSB)
    signal data_in_modified : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

    -- =======================================================
    -- PROCESS KOMBINATORIAL: Modifikasi Input Data 320-bit
    -- =======================================================
    -- Tugas: Isi bit 0-63 dari data_in_64, dan sisanya (64-319) dengan '0'.
    data_in_modified <= (DATA_WIDTH - 1 downto LSB_WIDTH => '0') & data_in_64;
    -- Artinya: bit 319 downto 64 diisi '0', digabungkan dengan data_in_64 (bit 63 downto 0)

    
    -- =======================================================
    -- PROCESS SEQUENTIAL: Register Pembaruan
    -- =======================================================
    process (clk, reset) is
    begin
        if reset = '1' then
            -- Reset semua bit menjadi '0'
            state_internal <= (others => '0'); 
            
        elsif rising_edge(clk) then
            -- Pemuatan Data (Hanya 64 LSB yang diisi)
            if En = '1' then
                state_internal <= data_in_modified;
            end if;
        end if;
    end process;
    
    -- Menghubungkan sinyal internal ke port output
    data_out_320 <= state_internal;

end architecture RTL;