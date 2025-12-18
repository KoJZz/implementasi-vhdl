library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity message_byte_counter is
	port (
		Clk	: in std_logic;
		En_msg : in std_logic;
		rst_msg : in std_logic;
		out4 : out std_logic_vector (3 downto 0)
	);
end entity;

architecture cnt of message_byte_counter is 
	signal cnt : unsigned(3 downto 0) := (others => '0');
begin

	process(Clk, rst_msg)
	begin
		if rst_msg = '1' then
            cnt <= (others => '0');
		elsif rising_edge(Clk) then
			if En_msg = '1' then
				cnt <= cnt + 1;	
			end if;
		end if;
	end process;
	out4 <= std_logic_vector(cnt);
end architecture;