-- definisi library yang digunakan
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.ascon_constants.all;

-- definisi entity
entity datapath is
	port (
		Clk	: in std_logic;
		out_length : in std_logic_vector (7 downto 0);
		
		-- input dari FSM/top
		mux_select : in std_logic_vector (1 downto 0);
		en_ascon : in std_logic;
		rst_8 : in std_logic;
		en_8 : in std_logic;
		rst_msg : in std_logic;
		receive : in std_logic;
		shift_tx : in std_logic;
		appl_pad : in std_logic; -- 
		Transmit : in std_logic;
		En_output : in std_logic;
		done_pad_fromRX : in std_logic; -- dari FSM
		en_state_reg : in std_logic; -- dari FSM buat enable state_reg
		reading			: in std_logic; --tandain kalo udah 8 byte (ato msg end) dan data dipad

		
		-- out ke top/FSM
		rx_done, tx_done : in std_logic;
		in_rx : in std_logic_vector (7 downto 0);
		out_tx : out std_logic_vector (7 downto 0);
		done_message : out std_logic;
		done_output : out std_logic;
		done_padding_fromDP : out std_logic;
		done_ascon : out std_logic;
		cnt_8 : out std_logic_vector (3 downto 0);
		msg_count 		: out std_logic_vector (3 downto 0); -- added buat mekanik done padding dari rx
		
		debug_state_x0 : out ascon_word_t
	);
end entity;

-- definisi architecture
architecture path of datapath is
-- definsi signal
signal absorbed_data, zero_out_320, state_reg_out, ascon_p_out : ascon_state_t;
signal pad_out_64, message_reg_out, state_rate_out : std_logic_vector (63 downto 0);
signal rx_byte_count, s_temp_byt_count: std_logic_vector (3 downto 0);
signal Reset, default_en, ascon_ready, s_done_pad_fromPad : std_logic;

-- definisi component yang digunakan
component ascon_p12 is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        enable   : in  std_logic;      -- Mulai permutasi
        state_in : in  ascon_state_t;
        
        state_out: out ascon_state_t;  -- State setelah P12
        ready    : out std_logic       -- '1' ketika P12 selesai
    );
end component;

component Zero_Register_320bit is
    port (
        --clk         : in  std_logic;
        reset       : in  std_logic; 
        En          : in  std_logic; 
        data_in_64  : in  ascon_word_t; 
        
        state_out : out ascon_state_t 
    );
end component;

component SilenceTimer is
    generic (
        MAX_COUNT : unsigned(31 downto 0) := to_unsigned(100000, 32)  
        -- 100,000 clock = 1 ms @ 100 MHz
    );
    port (
        clk          : in  std_logic;
        en           : in  std_logic;               
        rst          : in  std_logic;               
        done_message : out std_logic                -- 1 jika silence ≥ 1ms
    );
end component;

component Pad is
    Port (
		  appl_pad : in std_logic;
        raw_buffer : in  STD_LOGIC_VECTOR (63 downto 0); 
        byte_count : in  std_logic_vector(3 downto 0);
		  done_pad : out std_logic; -- ngetes done pad		  
        padded_out : out STD_LOGIC_VECTOR (63 downto 0)  
    );
end component;


component OutputShift64 is
    port (
        clk        : in  std_logic;
        En_output  : in  std_logic;                   
        shift_tx   : in  std_logic;                   
        data_in    : in  std_logic_vector(63 downto 0);
        data_out   : out std_logic_vector(7 downto 0)  
    );
end component;

component message_register is
	port (
		Clk : in std_logic;
		En_msg : in std_logic; -- uart rx done (terima 1 byte)
		new8 : in std_logic_vector (7 downto 0); -- input 8 bit message yang diterima dari UART Rx
		reading : in std_logic; -- nandain kalau data sedang dipake. Jika iya, countnya kurangin BARU
		
		-- output
		out_count : out std_logic_vector (3 downto 0); -- count message yang sedang diproses BARU
		out64 : out std_logic_vector (63 downto 0) -- output 64 bit blok message 
	);
end component;

component message_byte_counter is
	port (
		Clk	: in std_logic;
		En_msg : in std_logic;
		rst_msg : in std_logic;
		out4 : out std_logic_vector (3 downto 0)
	);
end component;

component L_Downcounter is
    port (
        clk         : in  std_logic;                           -- Clock
        done        : in  std_logic;                           -- Pulsa dari UART Tx
        length      : in  std_logic_vector(7 downto 0);        -- Panjang L
        done_output : out std_logic                             -- 1 saat count = 0
    );
end component;

component ascon_state_register is
    port (
		  done_pad_fromRX : in std_logic; --DIUPDATE done_pad dari RX (message kelipatan 64)
        clk        : in std_logic;
        reset      : in std_logic;
        enable     : in std_logic; 
        mux_select    : in std_logic_vector(1 downto 0); -- 00: Init, 01: Permutation, 10: Absorb
        
        data_from_permutation : in ascon_state_t;
        data_from_absorbing   : in ascon_state_t;
        
        current_state_out     : out ascon_state_t;
		  rate_out              : out ascon_word_t
    );
end component;

begin
default_en <= '1';
Reset <= '0';
absorbed_data <= xor_state(zero_out_320, state_reg_out);
debug_state_x0 <= state_reg_out(0);
done_padding_fromDP <= s_done_pad_fromPad XOR done_pad_fromRX;
msg_count <= rx_byte_count; --panjang message

-- port mapping components
p12 : ascon_p12
	port map(
		clk      => Clk,
        rst      => Reset,
        enable   => en_ascon, 
        state_in => state_reg_out,
        state_out=> ascon_p_out,  -- State setelah P12
        ready    =>done_ascon 
	);

zero_reg : Zero_Register_320bit
	port map(
		--clk         => Clk, -- hapus ntar
		reset       => Reset,
		En          => default_en,
		data_in_64  => pad_out_64,
		state_out => zero_out_320
	);
	
silence : SilenceTimer
	port map(
		clk          =>Clk,
		en           =>receive,               
		rst          =>rx_done,               
		done_message =>done_message 
	);
	
padding : Pad
	port map(
	   appl_pad   => appl_pad,
		raw_buffer =>message_reg_out, 
		byte_count => rx_byte_count,
	   done_pad => s_done_pad_fromPad,
		padded_out =>pad_out_64  
	);
	
output_reg : OutputShift64
	port map(
		clk        =>Clk, 
		En_output  =>En_output,                   
		shift_tx   =>shift_tx,                   
		data_in    =>state_rate_out, 
		data_out   =>out_tx 	
	);
	
msg_reg : message_register
	port map(
		Clk =>Clk, 
		En_msg =>rx_done, 
		new8 =>in_rx,
		reading => reading, --kyknya ini dari FSM ngepulse
		out_count => rx_byte_count, -- ini ke tempat2 sekarang msg_byt_count
		out64 =>message_reg_out
	);
	
msg_byte_cnt : message_byte_counter
	port map(
		Clk	=>Clk,
		En_msg =>rx_done, 
		rst_msg =>rst_msg, -- kyknya ini udah ga perlu
		out4 =>s_temp_byt_count -- ga kehubung ke mana-mana
	);

counter_8 : message_byte_counter
	port map(
		Clk	=>Clk,
		En_msg =>tx_done,
		rst_msg =>rst_8,
		out4 =>cnt_8
	);

downcounter : L_Downcounter
	port map(
		clk         =>Clk,                           -- Clock
		done        =>tx_done,                          -- Pulsa dari UART Tx
		length      =>out_length,        -- Panjang L
		done_output =>done_output      
	);

state_reg : ascon_state_register
	port map(
	   done_pad_fromRX => done_pad_fromRX, -- DIUPATE buat pad kelipatan 64
		clk        =>Clk,
		reset      =>Reset,
		enable     =>en_state_reg, 
		mux_select    =>mux_select, -- 00: Init, 01: Permutation, 10: Absorb

		data_from_permutation =>ascon_p_out, -- add hasil ascon-p
		data_from_absorbing   =>absorbed_data,

		current_state_out     =>state_reg_out,
		rate_out			  =>state_rate_out
	);

end architecture;

