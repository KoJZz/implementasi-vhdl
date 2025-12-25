library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_to_word_fifo is
    Generic (
        FIFO_DEPTH : integer := 4  -- Stores 4 blocks of 64-bits
    );
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        
        -- UART Interface (8-bit Input)
        uart_wr_en  : in  std_logic;
        uart_din    : in  std_logic_vector(7 downto 0);
        
        -- Ascon Interface (64-bit Output)
        ascon_rd_en : in  std_logic;
        ascon_dout  : out std_logic_vector(63 downto 0);
        
        -- Status Flags
        empty       : out std_logic;
        full        : out std_logic;
        block_count : out integer range 0 to FIFO_DEPTH
    );
end uart_to_word_fifo;

architecture Behavioral of uart_to_word_fifo is

    -- Signals
    signal temp_reg    : std_logic_vector(63 downto 0); 
    signal byte_idx    : integer range 0 to 7 := 0;
    signal word_ready  : std_logic := '0';

    -- FIFO Memory
    type memory_type is array (0 to FIFO_DEPTH-1) of std_logic_vector(63 downto 0);
    signal fifo_mem : memory_type := (others => (others => '0'));

    -- Pointers
    signal head : integer range 0 to FIFO_DEPTH-1 := 0;
    signal tail : integer range 0 to FIFO_DEPTH-1 := 0;
    signal count : integer range 0 to FIFO_DEPTH := 0;

begin

    -- PROCESS 1: Little Endian Byte Assembler
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                byte_idx <= 0;
                temp_reg <= (others => '0');
                word_ready <= '0';
            else
                word_ready <= '0'; 
                
                if uart_wr_en = '1' then
                    -- LITTLE ENDIAN LOGIC:
                    -- Shift the old data down (Right) and put new byte at the Top (MSB)
                    -- After 8 shifts, the 1st byte received will be at the bottom (LSB).
                    temp_reg <= uart_din & temp_reg(63 downto 8);
                    
                    if byte_idx = 7 then
                        byte_idx <= 0;
                        word_ready <= '1'; -- Push to FIFO
                    else
                        byte_idx <= byte_idx + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- PROCESS 2: 64-bit FIFO Manager (Same as before)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                head  <= 0;
                tail  <= 0;
                count <= 0;
                ascon_dout <= (others => '0');
            else
                -- Write and Read same time
                if (word_ready = '1' and ascon_rd_en = '1') then
                    fifo_mem(head) <= temp_reg;
                    if head = FIFO_DEPTH - 1 then head <= 0; else head <= head + 1; end if;
                    
                    ascon_dout <= fifo_mem(tail);
                    if tail = FIFO_DEPTH - 1 then tail <= 0; else tail <= tail + 1; end if;

                -- Write Only
                elsif (word_ready = '1' and count < FIFO_DEPTH) then
                    fifo_mem(head) <= temp_reg;
                    if head = FIFO_DEPTH - 1 then head <= 0; else head <= head + 1; end if;
                    count <= count + 1;

                -- Read Only
                elsif (ascon_rd_en = '1' and count > 0) then
                    ascon_dout <= fifo_mem(tail);
                    if tail = FIFO_DEPTH - 1 then tail <= 0; else tail <= tail + 1; end if;
                    count <= count - 1;
                end if;
            end if;
        end if;
    end process;

    -- Output Flags
    block_count <= count;
    empty <= '1' when count = 0 else '0';
    full  <= '1' when count = FIFO_DEPTH else '0';

end Behavioral;