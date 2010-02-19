
--Registers:												          Comments:
--$3F SREG Status Register									  Implemented in the AX8 core
--$3D SPL Stack Pointer Low									  Implemented in the AX8 core
--$35 MCUCR MCU General Control Register		  No power down
--$18 PORTB Data Register, Port B						  No pullup
--$17 DDRB Data Direction Register, Port B
--$16 PINB Input Pins, Port B

library IEEE;
use IEEE.std_logic_1164.all;
use work.AX_Pack.all;

entity A90Sandy is
	generic(
		SyncReset : boolean := true;
		TriState : boolean := false
	);
	port(
		Clk		: in std_logic;
		Reset_n	: in std_logic;
		Port_B	: inout std_logic_vector(7 downto 0)
	);
end A90Sandy;

architecture rtl of A90Sandy is

	constant	ROMAddressWidth		: integer := 10;
	constant	RAMAddressWidth		: integer := 8;
	constant	BigISet				: boolean := true;

	component ROMandy
		port(
			Clk	: in std_logic;
			A	: in std_logic_vector(ROMAddressWidth - 1 downto 0);
			D	: out std_logic_vector(15 downto 0)
		);
	end component;

	signal	Reset_s_n	: std_logic;
	
	--ROM bus
	signal	ROM_Addr	: std_logic_vector(ROMAddressWidth - 1 downto 0);
	signal	ROM_Data	: std_logic_vector(15 downto 0);
	
	--CPU Registers
	signal	SREG		: std_logic_vector(7 downto 0);
	signal	SP			: std_logic_vector(15 downto 0);
	
	--IO Address Space
	signal	IO_Rd		: std_logic;
	signal	IO_Wr		: std_logic;
	signal	IO_Addr		: std_logic_vector(5 downto 0);
	signal	IO_WData	: std_logic_vector(7 downto 0);
	signal	IO_RData	: std_logic_vector(7 downto 0);

	signal	Sleep_En	: std_logic;

  --Port A
  signal	PORTB_Sel	: std_logic;
	signal	DDRB_Sel	: std_logic;
	signal	PINB_Sel	: std_logic;
	signal	DirB  		: std_logic_vector(7 downto 0);
	signal	Port_InB	: std_logic_vector(7 downto 0);
	signal	Port_OutB	: std_logic_vector(7 downto 0);
	
	--Interrupt Trigger
	signal	Int_Trig	: std_logic_vector(15 downto 1);
	signal	Int_Acc		: std_logic_vector(15 downto 1);
begin
  --We don't currently use interrupts, so set everything to 0
  Int_Trig <= (others => '0');
  Int_Acc <= (others => '0');

	-- Synchronise reset
	process (Reset_n, Clk)
		variable Reset_v : std_logic;
	begin
		if Reset_n = '0' then
			if SyncReset then
				Reset_s_n <= '0';
				Reset_v := '0';
			end if;
		elsif Clk'event and Clk = '1' then
			if SyncReset then
				Reset_s_n <= Reset_v;
				Reset_v := '1';
			end if;
		end if;
	end process;

	g_reset : if not SyncReset generate
		Reset_s_n <= Reset_n;
	end generate;

	-- Registers/Interrupts
	process (Reset_s_n, Clk)
	begin
		if Reset_s_n = '0' then
			Sleep_En <= '0';
		elsif Clk'event and Clk = '1' then
			if IO_Wr = '1' and IO_Addr = "110101" then	-- $35 MCUCR
				Sleep_En <= IO_WData(5);
			end if;
		end if;
	end process;

	rom : ROMandy port map(
			Clk => Clk,
			A => ROM_Addr,
			D => ROM_Data);

	ax : AX8
		generic map(
			ROMAddressWidth => ROMAddressWidth,
			RAMAddressWidth => RAMAddressWidth,
			BigIset => BigIset)
		port map(
			Clk => Clk,
			Reset_n => Reset_s_n,
			ROM_Addr => ROM_Addr,
			ROM_Data => ROM_Data,
			Sleep_En => Sleep_En,
			Int_Trig => Int_Trig,
			Int_Acc => Int_Acc,
			SREG => SREG,
			SP => SP,
			IO_Rd => IO_Rd,
			IO_Wr => IO_Wr,
			IO_Addr => IO_Addr,
			IO_RData => IO_RData,
			IO_WData => IO_WData);


	PINB_Sel <= '1' when IO_Addr = "010101" else '0';
	DDRB_Sel <= '1' when IO_Addr = "010111" else '0';
	PORTB_Sel <= '1' when IO_Addr = "011000" else '0';
	porta : AX_Port port map(
			Clk => Clk,
			Reset_n => Reset_s_n,
			PORT_Sel => PORTB_Sel,
			DDR_Sel => DDRB_Sel,
			PIN_Sel => PINB_Sel,
			Wr => IO_Wr,
			Data_In => IO_WData,
			Dir => DirB,
			Port_Input => Port_InB,
			Port_Output => Port_OutB,
			IOPort  => Port_B);

	gNoTri : if not TriState generate
		with IO_Addr select
			IO_RData <= SREG when "111111",
				SP(7 downto 0) when "111101",
				SP(15 downto 8) when "111110",
				"00" & Sleep_En & "00000" when "110101",
				Port_InB when "010101",
				DirB when "010111",
				Port_OutB when "011000",
				"--------" when others;
	end generate;
	
	gTri : if TriState generate
		IO_RData <= SREG when IO_Addr = "111111" else "ZZZZZZZZ";
		IO_RData <= SP(7 downto 0) when IO_Addr = "111101" and BigIset else "ZZZZZZZZ";
		IO_RData <= SP(15 downto 8) when IO_Addr = "111110" and BigIset else "ZZZZZZZZ";

		IO_RData <= "00" & Sleep_En & "00000" when IO_Addr = "110101" else "ZZZZZZZZ";
		IO_RData <= Port_InB when PINB_Sel = '1' else "ZZZZZZZZ";
		IO_RData <= DirB when DDRB_Sel = '1' else "ZZZZZZZZ";
		IO_RData <= Port_OutB when PORTB_Sel = '1' else "ZZZZZZZZ";
  end generate;

end;
