-- definisi library yang digunakan
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

-- definisi entity
entity datapath is
	port (
		Clk	: in std_logic;
		out_length : in std_logic_vector (7 downto 0);
		
		mux_select : in std_logic_vector (1 downto 0);
		en_ascon : in std_logic;
		rst_8 : in std_logic;
		en_8 : in std_logic;
		rst_msg : in std_logic;
		receive : in std_logic;
		shift_tx : in std_logic;
		appl_pad : in std_logic;
		Transmit : in std_logic;
		En_output : in std_logic;
		
		
		rx_done, tx_done : in std_logic;
		in_rx : in std_logic_vector (7 downto 0);
		out_tx : out std_logic_vector (7 downto 0);
		done_message : out std_logic;
		done_output : out std_logic;
		done_padding : out std_logic;
		done_ascon : out std_logic;
		cnt_8 : out std_logic_vector (3 downto 0)
	);
end entity;

-- definisi architecture
architecture path of datapath is
-- definsi signal
signal zero_out_320, state_reg_out, ascon_p_out : std_logic_vector(319 downto 0);
signal pad_out_64, message_reg_out, state_rate_out : std_logic_vector (63 downto 0);
signal rx_byte_count: std_logic_vector (3 downto 0);
signal Reset, default_en, ascon_ready : std_logic;

-- definisi component yang digunakan
component ascon_p12 is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        enable   : in  std_logic;      -- Mulai permutasi
        state_in : in  std_logic_vector(319 downto 0);
        
        state_out: out std_logic_vector(319 downto 0);  -- State setelah P12
        ready    : out std_logic       -- '1' ketika P12 selesai
    );
end component;

component Zero_Register_320bit is
    generic (
        DATA_WIDTH : integer := 320;
        LSB_WIDTH  : integer := 64  
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic; 
        En          : in  std_logic; 
        data_in_64  : in  std_logic_vector(LSB_WIDTH - 1 downto 0); 
        
        data_out_320 : out std_logic_vector(DATA_WIDTH - 1 downto 0) 
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
        raw_buffer : in  STD_LOGIC_VECTOR (63 downto 0); 
        byte_count : in  INTEGER range 0 to 8;           
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
		En_msg : in std_logic;
		new8 : in std_logic_vector (7 downto 0); 
		out64 : out std_logic_vector (63 downto 0) 
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
        clk        : in std_logic;
        reset      : in std_logic;
        enable     : in std_logic; 
        mux_select    : in std_logic_vector(1 downto 0); -- 00: Init, 01: Permutation, 10: Absorb
        
        data_from_permutation : in std_logic_vector(319 downto 0);
        data_from_absorbing   : in std_logic_vector(319 downto 0);
        
        current_state_out     : out std_logic_vector(319 downto 0);
		rate_out              : out std_logic_vector(63 downto 0)
    );
end component;

begin
default_en <= '1';
Reset <= '0';

-- port mapping components
p12 : ascon_p12
	port map(
		clk      => Clk,
        rst      => Reset,
        enable   => default_en, 
        state_in => state_reg_out,
        state_out=>ascon_p_out,  -- State setelah P12
        ready    =>done_ascon 
	);

zero_reg : Zero_Register_320bit
	port map(
		clk         =>Clk,
		reset       =>Reset,
		En          =>default_en,
		data_in_64  =>pad_out_64,
		data_out_320 =>zero_out_320
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
		raw_buffer =>message_reg_out, 
		byte_count => to_integer(unsigned(rx_byte_count)), 
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
		out64 =>message_reg_out
	);
	
msg_byte_cnt : message_byte_counter
	port map(
		Clk	=>Clk,
		En_msg =>rx_done, 
		rst_msg =>rst_msg, 
		out4 =>rx_byte_count
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
		clk        =>Clk,
		reset      =>Reset,
		enable     =>default_en, 
		mux_select    =>mux_select, -- 00: Init, 01: Permutation, 10: Absorb

		data_from_permutation =>ascon_p_out, -- add hasil ascon-p
		data_from_absorbing   =>zero_out_320 xor state_reg_out,

		current_state_out     =>state_reg_out,
		rate_out			  =>state_rate_out
	);

end architecture;

