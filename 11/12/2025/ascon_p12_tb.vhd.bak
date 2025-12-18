library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;

entity ascon_p12_tb is
end ascon_p12_tb;

architecture behavior of ascon_p12_tb is

    component ascon_p12_wrapper
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            start       : in  std_logic;
            mode_load   : in  std_logic;
            data_in     : in  std_logic_vector(63 downto 0);
            data_out    : out std_logic_vector(63 downto 0);
            busy        : out std_logic;
            done        : out std_logic
        );
    end component;

    -- Inputs
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal start     : std_logic := '0';
    signal mode_load : std_logic := '0';
    signal data_in   : std_logic_vector(63 downto 0) := (others => '0');

    -- Outputs
    signal data_out  : std_logic_vector(63 downto 0);
    signal busy      : std_logic;
    signal done      : std_logic;

    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: ascon_p12_wrapper port map (
        clk       => clk,
        rst       => rst,
        start     => start,
        mode_load => mode_load,
        data_in   => data_in,
        data_out  => data_out,
        busy      => busy,
        done      => done
    );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset state
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- =========================================================
        -- 1. LOAD PHASE
        -- =========================================================
        report "Starting Load Phase...";
        
        start <= '1';
        mode_load <= '1'; -- Set to Write Mode
        
        -- Input Word 0 (IV)
        data_in <= ASCON_XOF_IV_VAL;
        wait for CLK_PERIOD; 
        
        -- Input Word 1 (Zero)
        data_in <= (others => '0');
        wait for CLK_PERIOD;
        
        -- Input Word 2 (Zero)
        data_in <= (others => '0');
        wait for CLK_PERIOD;
        
        -- Input Word 3 (Zero)
        data_in <= (others => '0');
        wait for CLK_PERIOD;
        
        -- Input Word 4 (Zero)
        data_in <= (others => '0');
        wait for CLK_PERIOD;
        
        -- Stop Loading
        start <= '0';
        mode_load <= '0';
        data_in <= (others => '0');

        report "Load Complete. Core processing...";

        -- =========================================================
        -- 2. WAIT FOR PROCESSING
        -- =========================================================
        wait until done = '1';
        report "Core Processing Done!";
        wait for CLK_PERIOD;

        -- =========================================================
        -- 3. UNLOAD / VERIFY PHASE
        -- =========================================================
        -- To read out, we pulse 'start' with mode_load='0' to advance the read pointer
        
        -- Read Word 0
        -- Note: Wrapper outputs Word 0 immediately upon entering UNLOADING state
        start <= '0'; 
        wait for 1 ns; -- Delta delay to read
        assert data_out = EXPECTED_X0 report "Mismatch Word 0" severity error;
        
        -- Advance to Word 1
        start <= '1'; mode_load <= '0'; 
        wait for CLK_PERIOD; -- Rising edge increments pointer
        start <= '0'; wait for 1 ns;
        assert data_out = EXPECTED_X1 report "Mismatch Word 1" severity error;

        -- Advance to Word 2
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0'; wait for 1 ns;
        assert data_out = EXPECTED_X2 report "Mismatch Word 2" severity error;

        -- Advance to Word 3
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0'; wait for 1 ns;
        assert data_out = EXPECTED_X3 report "Mismatch Word 3" severity error;

        -- Advance to Word 4
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0'; wait for 1 ns;
        assert data_out = EXPECTED_X4 report "Mismatch Word 4" severity error;

        report "TEST COMPLETED SUCCESSFULLY";
        wait;
    end process;

end behavior;