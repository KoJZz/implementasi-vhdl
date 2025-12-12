library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ascon_constants.all;

entity ascon_p12_wrapper is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        
        -- Control Signals
        start       : in  std_logic;                    -- Trigger start of operation
        mode_load   : in  std_logic;                    -- '1' = Load Data, '0' = Read Result
        
        -- Data Interface (reduced to 64-bit to save pins)
        data_in     : in  std_logic_vector(63 downto 0);
        data_out    : out std_logic_vector(63 downto 0);
        
        -- Status Signals
        busy        : out std_logic;
        done        : out std_logic                     -- Pulse when P12 is complete
    );
end ascon_p12_wrapper;

architecture behavioral of ascon_p12_wrapper is

    -- Component Declaration for your original P12 core
    component ascon_p12
        port (
            clk       : in  std_logic;
            rst       : in  std_logic;
            enable    : in  std_logic;
            state_in  : in  ascon_state_t;
            state_out : out ascon_state_t;
            ready     : out std_logic
        );
    end component;

    -- Internal Registers
    signal r_state_buffer : ascon_state_t; -- Holds the 320-bit state internally
    signal load_counter   : integer range 0 to 5 := 0;
    
    -- Signals for connecting to P12 Core
    signal core_enable    : std_logic;
    signal core_state_out : ascon_state_t;
    signal core_ready     : std_logic;

    -- FSM State
    type state_type is (IDLE, LOADING, PROCESSING, UNLOADING, FINISHED);
    signal current_state : state_type;

begin

    -- Instantiate the P12 Core
    -- Note: We map state_in to our internal buffer
    inst_core: ascon_p12
    port map (
        clk       => clk,
        rst       => rst,
        enable    => core_enable,
        state_in  => r_state_buffer,
        state_out => core_state_out,
        ready     => core_ready
    );

    -- Main Control Process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state  <= IDLE;
                load_counter   <= 0;
                core_enable    <= '0';
                busy           <= '0';
                done           <= '0';
                r_state_buffer <= (others => (others => '0'));
            else
                case current_state is
                    
                    when IDLE =>
                        done <= '0';
                        load_counter <= 0;
                        if start = '1' then
                            if mode_load = '1' then
                                busy <= '1';
                                current_state <= LOADING;
                            end if;
                        else
                            busy <= '0';
                        end if;

                    when LOADING =>
                        -- Load 64-bits at a time into the buffer
                        -- Uses 'start' as a write enable strobe for each word if you want, 
                        -- or simply loads continuously. Here we assume continuous burst.
                        if load_counter < 5 then
                            r_state_buffer(load_counter) <= data_in;
                            load_counter <= load_counter + 1;
                        else
                            -- Loading complete, start processing
                            current_state <= PROCESSING;
                            core_enable   <= '1'; -- Trigger the core
                        end if;

                    when PROCESSING =>
                        core_enable <= '0'; -- Pulse enable only once
                        
                        if core_ready = '1' then
                            -- Core finished, capture the result back to buffer
                            r_state_buffer <= core_state_out;
                            current_state  <= UNLOADING;
                            load_counter   <= 0; -- Reset counter for unloading
                            done           <= '1'; -- Signal completion
                        end if;

                    when UNLOADING =>
                        done <= '0';
                        -- Wait for user to read out data (logic simplified for testbench)
                        -- User should clock out data now.
                        -- We will hold here until reset or manual restart
                        if start = '1' and mode_load = '0' then
                             -- Logic to shift read pointer could go here
                             if load_counter < 4 then
                                 load_counter <= load_counter + 1;
                             else
                                 current_state <= IDLE;
                                 busy <= '0';
                             end if;
                        end if;
                        
                    when others =>
                        current_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- Output Logic (Asynchronous Read)
    -- Outputs the word currently pointed to by load_counter
    data_out <= r_state_buffer(load_counter) when (current_state = UNLOADING) else (others => '0');

end behavioral;