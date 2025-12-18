-- definisi library
library ieee;
use ieee.std_logic_1164.all;

-- definisi entity
entity message_register is
	port (
		Clk : in std_logic;
		En_msg : in std_logic;
		new8 : in std_logic_vector (7 downto 0); -- input 8 bit message yang diterima dari UART Rx
		out64 : out std_logic_vector (63 downto 0) -- output 64 bit blok message
	);
end entity;

-- definisi architecture
architecture structural of message_register is
	signal reg_data : std_logic_vector(63 downto 0) := (others => '0'); -- signal untuk buffer data
begin
	process(Clk)
	begin
	if rising_edge(Clk) then
		if En_msg = '1' then -- jika rising edge dan register ter-enable, maka buffer diupate dengan 8 bit data baru pada LSB dan sisa 56 bit diisi 0:55 bit yang lama
			reg_data <= reg_data(63 downto 8) & new8;
		end if;
	end if;
	end process;
	
	out64 <= reg_data; --outputkan buffer data
end architecture;