library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCON_FSM is
    port (
        -- Sinyal Input Kontrol Clock/Reset
        clk             : in  std_logic;
        reset           : in  std_logic;

        p12_done        : in  std_logic; -- Input from Datapath (ascon_ready)
        
        -- Input Kontrol Transisi (Next State Logic)
        start_op        : in  std_logic;      -- Mulai operasi dari IDLE
        message_end     : in  std_logic;      -- Akhir pesan tercapai
        done_padding    : in  std_logic;      -- Transisi PADDING/ASCON-P12 ke SQUEEZING
        tx_ready        : in  std_logic;      -- Kontrol Output SQUEEZING (Mealy Input)
        squeezing_done  : in  std_logic;      -- Kondisi keluar dari SQUEEZING ke IDLE
        
        -- Sinyal Output Kontrol (Output Logic)
        mux_select      : out std_logic_vector(1 downto 0);
        en_ascon         : out std_logic;
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

    -- Definisi Tipe Status
    type State_Type is (
        IDLE, 
        INITIALIZATION, 
        ASCON_P12, 
        RX_MESSAGE, 
        PADDING, 
        SQUEEZING
    );

    -- Sinyal Status Saat Ini dan Status Berikutnya
    signal Current_State : State_Type;
    signal Next_State    : State_Type;

begin
    
    -- =======================================================
    -- PROCESS 1: State Register (Update Status Pada Edge Clock)
    -- =======================================================
    process (clk, reset) is
    begin
        if reset = '1' then
            Current_State <= IDLE;
        elsif rising_edge(clk) then
            Current_State <= Next_State;
        end if;
    end process;
    
    -- =======================================================
    -- PROCESS 2: Next State Logic (Logika Transisi)
    -- =======================================================
    process (Current_State, start_op, message_end, done_padding, squeezing_done) is
    begin
        -- Default: Tetap di status saat ini
        Next_State <= Current_State;

        case Current_State is
            when IDLE =>
                if start_op = '1' then
                    Next_State <= INITIALIZATION;
                end if;

            when INITIALIZATION =>
                -- Asumsi: Pindah setelah 1 siklus
                Next_State <= ASCON_P12;

            when ASCON_P12 =>
                if p12_done = '1' then
                    if done_padding = '0' then
                        Next_State <= RX_MESSAGE;
                    elsif done_padding = '1' then
                        Next_State <= SQUEEZING;
                    end if;
                else
                    Next_State <= ASCON_P12;
                end if;

            when RX_MESSAGE =>
                if message_end = '1' then
                    Next_State <= PADDING;
                elsif message_end = '0' then
                    Next_State <= RX_MESSAGE; -- Loop memproses data masuk
                end if;

            when PADDING =>
                -- Transisi PADDING -> SQUEEZING saat done_padding = 1
                if done_padding = '1' then
                    Next_State <= SQUEEZING;
                end if;

            when SQUEEZING =>
                -- Transisi SQUEEZING -> IDLE saat squeezing_done = 1
                if squeezing_done = '1' then
                    Next_State <= IDLE;
                -- Jika belum selesai, loop tetap di SQUEEZING
                end if;

        end case;
    end process;

    -- =======================================================
    -- PROCESS 3: Output Logic (Moore & Mealy)
    -- =======================================================
    process (Current_State, tx_ready) is
        -- Inisialisasi default untuk output agar aman
        variable v_mux_select : std_logic_vector(1 downto 0);
        variable v_en_asco, v_rst_8, v_en_8, v_rst_msg, v_receive, v_shift_tx, v_appl_pad, v_transmit, v_en_output : std_logic;
    begin
        -- Set default values
        v_mux_select := "00"; v_en_asco := '0'; v_rst_8 := '0'; v_en_8 := '0';
        v_rst_msg := '0'; v_receive := '0'; v_shift_tx := '0'; v_appl_pad := '0';
        v_transmit := '0'; v_en_output := '0';

        case Current_State is
            when IDLE =>
                -- Semua 00/0
                null; 

            when INITIALIZATION =>
                -- Semua 00/0
                null; 

            when ASCON_P12 =>
                v_mux_select := "10";
                v_en_asco    := '1'; v_rst_8 := '1'; 
                v_rst_msg    := '1'; 

            when RX_MESSAGE =>
                v_mux_select := "01";
                v_receive    := '1';

            when PADDING =>
                v_mux_select := "01";
                v_receive    := '1';
                v_appl_pad   := '1';

            when SQUEEZING =>
                v_mux_select := "10";
                v_en_8       := '1';

                -- MEALY OUTPUT dari tabel kedua (SQUEEZING -> SQUEEZING)
                if tx_ready = '1' then
                    v_transmit   := '1';
                    v_shift_tx   := '1';
                else
                    v_transmit   := '0';
                    v_shift_tx   := '0';
                end if;

        end case;
        
        -- MEALY OUTPUT untuk Transisi (En_output = 1 pada transisi ke SQUEEZING)
        -- Ini hanya berlaku jika output benar-benar tergantung pada transisi.
        -- Kami menggunakan logika di luar case untuk En_output.
        if (Current_State = ASCON_P12 or Current_State = PADDING) and Next_State = SQUEEZING then
            v_en_output := '1';
        end if;


        -- Tetapkan variabel ke port output
        mux_select  <= v_mux_select;
        en_ascon     <= v_en_asco;
        rst_8       <= v_rst_8;
        en_8        <= v_en_8;
        rst_msg     <= v_rst_msg;
        receive     <= v_receive;
        shift_tx    <= v_shift_tx;
        appl_pad    <= v_appl_pad;
        transmit    <= v_transmit;
        en_output   <= v_en_output;
        
    end process;

end architecture RTL;