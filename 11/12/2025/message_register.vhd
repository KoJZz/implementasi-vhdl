-- definisi library
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

-- definisi entity
entity message_register is
	port (
		Clk : in std_logic;
		En_msg : in std_logic; -- uart rx done (terima 1 byte)
		new8 : in std_logic_vector (7 downto 0); -- input 8 bit message yang diterima dari UART Rx
		reading : in std_logic; -- nandain kalau data sedang dipake. Jika iya, countnya kurangin
		
		-- output
		out_count : out std_logic_vector (3 downto 0); -- count message yang sedang diproses
		out64 : out std_logic_vector (63 downto 0) -- output 64 bit blok message
	);
end entity;

-- definisi architecture
architecture structural of message_register is
	signal reg_data : std_logic_vector(127 downto 0) := (others => '0'); -- signal untuk buffer data, 2 blok message buat jaga2
	signal byte_count : unsigned (7 downto 0);
	
begin
	process(Clk)
	begin
	if rising_edge(Clk) then
		if En_msg = '1' then -- jika rising edge dan register ter-enable, maka buffer diupate dengan 8 bit data baru pada LSB dan sisa 56 bit diisi 0:55 bit yang lama
			reg_data <= reg_data(55 downto 0) & new8;
			--reg_data <= new8 & reg_data(63 downto 8);
		end if;
	end if;
	end process;
	
	process(Clk)
	begin
	if rising_edge(Clk) then
		if reading = '1' then
			if byte_count >= 8 then
				out_count <= "1000";
				byte_count <= byte_count - 8;
			else
				out_count <= std_logic_vector(byte_count(3 downto 0));
				byte_count <= 0;
			end if;
		end if;
	end if;
	end process;
	
	out64 <= reg_data(63 downto 0); --outputkan buffer data
end architecture;