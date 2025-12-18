architecture rtl of ascon_p12_wrapper is

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

    type state_type is (
        IDLE,
        LOAD,
        START_CORE,
        WAIT_CORE,
        UNLOAD
    );

    signal fsm_state    : state_type;
    signal word_index  : integer range 0 to 4;

    signal state_buf   : ascon_state_t;
    signal core_enable : std_logic;
    signal core_ready  : std_logic;
    signal core_out    : ascon_state_t;

begin

    inst_core : ascon_p12
        port map (
            clk       => clk,
            rst       => rst,
            enable    => core_enable,
            state_in  => state_buf,
            state_out => core_out,
            ready     => core_ready
        );

    ------------------------------------------------------------------
    -- FSM
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fsm_state   <= IDLE;
                word_index <= 0;
                state_buf  <= (others => (others => '0'));
                core_enable <= '0';
                busy <= '0';
                done <= '0';

            else
                -- defaults
                core_enable <= '0';
                done <= '0';

                case fsm_state is

                    when IDLE =>
                        busy <= '0';
                        word_index <= 0;
                        if start = '1' and mode_load = '1' then
                            busy <= '1';
                            fsm_state <= LOAD;
                        end if;

                    --------------------------------------------------
                    when LOAD =>
                        state_buf(word_index) <= data_in;
                        if word_index = 4 then
                            fsm_state <= START_CORE;
                        else
                            word_index <= word_index + 1;
                        end if;

                    --------------------------------------------------
                    when START_CORE =>
                        core_enable <= '1'; -- exactly 1 cycle
                        fsm_state <= WAIT_CORE;

                    --------------------------------------------------
                    when WAIT_CORE =>
                        if core_ready = '1' then
                            state_buf <= core_out;
                            done <= '1'; -- 1-cycle pulse
                            word_index <= 0;
                            fsm_state <= UNLOAD;
                        end if;

                    --------------------------------------------------
                    when UNLOAD =>
                        if start = '1' and mode_load = '0' then
                            if word_index = 4 then
                                fsm_state <= IDLE;
                            else
                                word_index <= word_index + 1;
                            end if;
                        end if;

                end case;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Output
    ------------------------------------------------------------------
    data_out <= state_buf(word_index) when fsm_state = UNLOAD
                else (others => '0');

end rtl;
