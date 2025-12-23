library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pad is
       Port (
        -- Input
		  appl_pad : in std_logic;
        raw_buffer : in  STD_LOGIC_VECTOR (63 downto 0); -- buffer data sebelum padding
        byte_count : in  std_logic_vector(3 downto 0);          -- input counter byte ke-berapa

        -- Output
		  done_pad : out std_logic; -- ngetes done pad
        padded_out : out STD_LOGIC_VECTOR (63 downto 0)  -- hasil
		  
    );
end Pad;

architecture Behavioral of Pad is
begin
	 
    -- This process creates the Combinational MUX Logic
    process(raw_buffer, byte_count)
		  variable bc : integer range 0 to 8;
    begin
		  bc := to_integer(unsigned(byte_count));
        -- Iterate through all 8 Byte Lanes (Index 0 to 7)
		  --if appl_pad = '1' then
        for i in 0 to 7 loop
            
            -- CHECK: "Where am I relative to the counter?"
            
            if i < bc then
					 done_pad <= '0';
                -- CASE 1: Valid Data (Keep it)
                -- If count is 5, indices 0,1,2,3,4 enter here.
                padded_out(8*i + 7 downto 8*i) <= raw_buffer(8*i + 7 downto 8*i);
                
            elsif i = bc then
					 done_pad <= '0';
                -- CASE 2: The Padding Spot (Inject 0x80)
                -- If count is 5, index 5 enters here.
                padded_out(8*i + 7 downto 8*i) <= x"01";
                
            else -- (i > byte_count)
                -- CASE 3: Empty/Garbage Space (Force to 0)
                -- If count is 5, indices 6,7 enter here.
					 done_pad <= '1';
                padded_out(8*i + 7 downto 8*i) <= x"00";
                
            end if;
            
        end loop;
		  --end if;
    end process;

end Behavioral;