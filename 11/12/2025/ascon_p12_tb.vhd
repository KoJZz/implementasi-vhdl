library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;

entity ascon_p12_tb is
end ascon_p12_tb;

architecture behavior of ascon_p12_tb is

    ------------------------------------------------------------------
    -- DUT declaration
    ------------------------------------------------------------------
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

    ------------------------------------------------------------------
    -- Signals
    ------------------------------------------------------------------
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal start     : std_logic := '0';
    signal mode_load : std_logic := '0';
    signal data_in   : std_logic_vector(63 downto 0) := (others => '0');

    signal data_out  : std_logic_vector(63 downto 0);
    signal busy      : std_logic;
    signal done      : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    ------------------------------------------------------------------
    -- Instantiate DUT
    ------------------------------------------------------------------
    uut : ascon_p12_wrapper
        port map (
            clk       => clk,
            rst       => rst,
            start     => start,
            mode_load => mode_load,
            data_in   => data_in,
            data_out  => data_out,
            busy      => busy,
            done      => done
        );

    ------------------------------------------------------------------
    -- Clock generator
    ------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    ------------------------------------------------------------------
    -- Test stimulus
    ------------------------------------------------------------------
    stim_proc : process
    begin
        ------------------------------------------------------------------
        -- Reset
        ------------------------------------------------------------------
        rst <= '1';
        wait for 2 * CLK_PERIOD;
        wait until rising_edge(clk);
        rst <= '0';

        report "Reset released";

        ------------------------------------------------------------------
        -- LOAD PHASE
        ------------------------------------------------------------------
        report "Starting LOAD phase";

        -- Pulse start to enter LOAD
        start <= '1';
        mode_load <= '1';
        wait until rising_edge(clk);
        start <= '0';

        -- Word 0 (IV)
        data_in <= ASCON_XOF_IV_VAL;
        wait until rising_edge(clk);

        -- Word 1
        data_in <= (others => '0');
        wait until rising_edge(clk);

        -- Word 2
        data_in <= (others => '0');
        wait until rising_edge(clk);

        -- Word 3
        data_in <= (others => '0');
        wait until rising_edge(clk);

        -- Word 4
        data_in <= (others => '0');
        wait until rising_edge(clk);

        data_in <= (others => '0');
        mode_load <= '0';

        report "LOAD complete, waiting for core";

        ------------------------------------------------------------------
        -- WAIT FOR PROCESSING
        ------------------------------------------------------------------
        wait until rising_edge(clk) and done = '1';
        report "Core DONE";

        ------------------------------------------------------------------
        -- UNLOAD / VERIFY PHASE
        ------------------------------------------------------------------
        report "Starting UNLOAD / VERIFY phase";

        -- Word 0 is valid immediately after entering UNLOAD
        wait until rising_edge(clk);
        assert data_out = EXPECTED_X0
            report "Mismatch X0" severity error;

        -- Word 1
        start <= '1'; mode_load <= '0';
        wait until rising_edge(clk);
        start <= '0';
        wait until rising_edge(clk);
        assert data_out = EXPECTED_X1
            report "Mismatch X1" severity error;

        -- Word 2
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
        wait until rising_edge(clk);
        assert data_out = EXPECTED_X2
            report "Mismatch X2" severity error;

        -- Word 3
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
        wait until rising_edge(clk);
        assert data_out = EXPECTED_X3
            report "Mismatch X3" severity error;

        -- Word 4
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';
        wait until rising_edge(clk);
        assert data_out = EXPECTED_X4
            report "Mismatch X4" severity error;

        report "TEST PASSED SUCCESSFULLY";
        wait;
    end process;

end behavior;