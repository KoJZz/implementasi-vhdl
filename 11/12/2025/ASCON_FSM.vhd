library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCON_FSM is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;

        -- Datapath feedback
        p12_done        : in  std_logic;

        -- Control inputs
        start_op        : in  std_logic;
        message_end     : in  std_logic;
        done_padding    : in  std_logic;
        tx_ready        : in  std_logic;
        squeezing_done  : in  std_logic;
		  msg_count 		: in  std_logic_vector (3 downto 0); -- added buat mekanik done padding dari rx

        -- Control outputs
		  en_state_reg		: out std_logic; --enable state register ketika msg_count = 8/end message saat RX_MESSAGE. Selain state itu selalu 1
		  done_pad_fromRX : out std_logic;
        mux_select      : out std_logic_vector(1 downto 0);
        en_ascon        : out std_logic;
        rst_8           : out std_logic;
        en_8            : out std_logic;
        rst_msg         : out std_logic;
        receive         : out std_logic;
        shift_tx        : out std_logic;
        appl_pad        : out std_logic;
        transmit        : out std_logic;
        en_output       : out std_logic
    );
end entity ASCON_FSM;

architecture RTL of ASCON_FSM is

    -- ====================================================
    -- STATE DEFINITION
    -- ====================================================
    type State_Type is (
        IDLE,
        INITIALIZATION,
        ASCON_P12_START,
        ASCON_P12_WAIT,
        RX_MESSAGE,
        PADDING,
        SQUEEZING
    );

    signal Current_State : State_Type;
    signal Next_State    : State_Type;
	 signal s_rst_msg : std_logic;

begin

    -- ====================================================
    -- STATE REGISTER
    -- ====================================================
    process (clk, reset)
    begin
        if reset = '1' then
            Current_State <= IDLE;
        elsif rising_edge(clk) then
            Current_State <= Next_State;
        end if;
    end process;

    -- ====================================================
    -- NEXT STATE LOGIC
    -- ====================================================
    process (
        Current_State,
        start_op,
        p12_done,
        message_end,
        done_padding,
        squeezing_done
    )
    begin
        Next_State <= Current_State;

        case Current_State is

            when IDLE =>
                if start_op = '1' then
                    Next_State <= INITIALIZATION;
                end if;

            when INITIALIZATION =>
                Next_State <= ASCON_P12_START;

            when ASCON_P12_START =>
                Next_State <= ASCON_P12_WAIT;

            when ASCON_P12_WAIT =>
                if p12_done = '1' then
                    if message_end = '1' then -- tadinya done_padding = '1'
								if msg_count /= "1000" then
									Next_State <= SQUEEZING;
								elsif msg_count = "1000" then
									Next_State <= ASCON_P12_START;
								end if;
                    else
                        Next_State <= RX_MESSAGE;
                    end if;
                end if;

            when RX_MESSAGE =>
                if message_end = '1' OR msg_count = "1000" then
                    Next_State <= ASCON_P12_START; --tadinya PADDING, tp baru inget state PADDING ga perlu
                end if;

            when PADDING =>
                Next_State <= ASCON_P12_START;

            when SQUEEZING =>
                if squeezing_done = '1' then
                    Next_State <= IDLE;
                end if;

        end case;
    end process;

    -- ====================================================
    -- OUTPUT LOGIC
    -- ====================================================
    process (Current_State, Next_State, tx_ready, msg_count, message_end)
    begin
        -- Defaults
		  en_state_reg <= '1';
        mux_select  <= "11"; -- HOLD STATE
        en_ascon    <= '0';
        rst_8       <= '0';
        en_8        <= '0';
        rst_msg     <= '0';
        receive     <= '0';
        shift_tx    <= '0';
        appl_pad    <= '0';
        transmit    <= '0';
        en_output   <= '0';
		  done_pad_fromRX <= '0';

        case Current_State is

            when IDLE =>
                null;

            when INITIALIZATION =>
                mux_select <= "00"; -- Load IV

            when ASCON_P12_START =>
                en_ascon   <= '1';  -- 1-cycle start pulse
                rst_8      <= '1';
					 if message_end /= '1' then
						rst_msg    <= '1';
					 end if;
                mux_select <= "11"; -- HOLD

            when ASCON_P12_WAIT =>
                mux_select <= "11"; -- HOLD
                if p12_done = '1' then
                    mux_select <= "10"; -- Load permutation result
                end if;
					 if Next_State = ASCON_P12_START then
						rst_msg    <= '1'; -- DI SINI COBA KELUARIN OUTPUT
						done_pad_fromRX <= '1';
					 else
						rst_msg <= '0';
					 end if;

            when RX_MESSAGE =>
                --mux_select <= "01"; -- Absorb
                receive    <= '1';
					 mux_select <= "01"; -- Absorb
					 if message_end = '1' then -- NYOBA
					   en_state_reg <= '1'; -- kalo message_end enable state reg
						--if msg_count = "1000" then --DIGANTI NYOBA
							--done_pad_fromRX <= '1'; 
						--end if;
					 else
					   if msg_count = "1000" then
							en_state_reg <= '1'; -- enable state reg kalau 8 byte
						else
							en_state_reg <= '0'; -- disable sampai 8 byte
						end if;
					 end if;
					 
					 

            when PADDING =>
                mux_select <= "01";
                receive    <= '1';
                appl_pad   <= '1';

            when SQUEEZING =>
                mux_select <= "10";
                en_8       <= '1';
                if tx_ready = '1' then
                    transmit <= '1';
                    shift_tx <= '1';
                end if;

        end case;

        -- Enable output register exactly when entering SQUEEZING
        if (Current_State = ASCON_P12_WAIT and Next_State = SQUEEZING) then
            en_output <= '1';
        end if;

    end process;

end architecture RTL;
