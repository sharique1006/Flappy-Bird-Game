library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Disp is
    Port(JUMP : in std_logic;
         CLK : in std_logic;
         RST : in std_logic;
         EN : in std_logic;
         CS : out std_logic;
         SDO : out std_logic;
         SCLK : out std_logic;
         DC : out std_logic;
         FIN : out std_logic);
end Disp;

architecture Behavioral of Disp is
COMPONENT SPI_interface
    PORT(
        CLK : IN  std_logic;
        RST : IN  std_logic;
        SPI_EN : IN  std_logic;
        SPI_DATA : IN  std_logic_vector(7 downto 0);
        CS : OUT  std_logic;
        SDO : OUT  std_logic;
        SCLK : OUT  std_logic;
        SPI_FIN : OUT  std_logic
       );
END COMPONENT;

COMPONENT Delay
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         DELAY_MS : IN  std_logic_vector(11 downto 0);
         DELAY_EN : IN  std_logic;
         DELAY_FIN : OUT  std_logic
        );
END COMPONENT;

COMPONENT ascii_rom
  PORT (
    clk : IN STD_LOGIC;
    addr : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
END COMPONENT;

signal game_cnt : std_logic_vector (7 downto 0) := X"30";
type states is (Idle, ClearDC, SetPage, PageNum, LeftColumn1, LeftColumn2, SetDC, SendChar1, SendChar2, Wait17, Wait18, Changelevel, Wait16, SendChar3, won, SendChar4, SendChar5, SendChar6, SendChar7, SendChar8, ReadMem, ReadMem2, Transition1, Transition2, Transition3, Transition4, Transition5, UpdateScreen, Command1, Command2, Command3, Command4, Command5, Command6, Command7, Command8, Command9, Command10, Command11, Command12, Command13, Command14, Command15, Command16, Command17, Command18, Command19, Command20, Command21, Command22, Command23, Command24, Command25, Command26, Command27, Command28, Command29, Command30, Command31, Command32, Wait1, Wait2, Wait3, Wait4, Wait5, Wait6, Wait7, Wait8, Wait9, Wait10, Wait11, Wait12, Wait13, Wait14, Wait15, Done);
type OledMem is array(0 to 3, 0 to 15) of std_logic_vector(7 downto 0);
signal current_screen : OledMem;
constant ccommand1 : OledMem  := ((X"30",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C",game_cnt),
                                 (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"EF",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand2 : OledMem  := ((X"30",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                 (X"EF",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand3 : OledMem  := ((X"31",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                 (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"20",X"EF",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand4 : OledMem  := ((X"31",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                 (X"20",X"EF",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand5 : OledMem  := ((X"32",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                 (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"20",X"20",X"EF",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));	
constant ccommand6 : OledMem  := ((X"32",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                 (X"20",X"20",X"EF",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand7 : OledMem  := ((X"33",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                 (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"20",X"20",X"20",X"EF",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));	
constant ccommand8 : OledMem  := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                 (X"20",X"20",X"20",X"47",X"41",X"4D",X"45",X"20",X"20",X"4F",X"56",X"45",X"52",X"20",X"20",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"30",X"33",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
constant ccommand9 : OledMem  := ((X"34",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                 (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                 (X"20",X"20",X"20",X"20",X"EF",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                 (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));	
constant ccommand10 : OledMem  := ((X"34",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"EF",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand11 : OledMem  := ((X"35",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"EF",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));	
constant ccommand12 : OledMem  := ((X"35",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"EF",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand13 : OledMem  := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                  (X"20",X"20",X"20",X"47",X"41",X"4D",X"45",X"20",X"20",X"4F",X"56",X"45",X"52",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"30",X"35",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
constant ccommand14 : OledMem  := ((X"36",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"EF",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand15 : OledMem  := ((X"37",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"EF",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand16 : OledMem  := ((X"37",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"EF",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand17 : OledMem  := ((X"38",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"EF",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand18 : OledMem  := ((X"38",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"EF",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand19 : OledMem  := ((X"39",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"EF",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand20 : OledMem  := ((X"39",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20", X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"EF",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand21 : OledMem  := ((X"31",X"30",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20", X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"EF",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand22 : OledMem  := ((X"31",X"30",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"EF",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand23 : OledMem  := ((X"31",X"31",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"EF",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand24 : OledMem  := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                  (X"20",X"20",X"20",X"47",X"41",X"4D",X"45",X"20",X"20",X"4F",X"56",X"45",X"52",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31",X"30",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
constant ccommand25 : OledMem  := ((X"31",X"32",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"EF",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand26 : OledMem  := ((X"31",X"32",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"EF",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand27 : OledMem  := ((X"31",X"33",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"EF",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand28 : OledMem  := ((X"31",X"33",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"EF",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand29 : OledMem  := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                  (X"20",X"20",X"20",X"47",X"41",X"4D",X"45",X"20",X"20",X"4F",X"56",X"45",X"52",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31",X"33",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));			
constant ccommand30 : OledMem  := ((X"31",X"34",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"EF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand31 : OledMem  := ((X"31",X"35",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"EF"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant ccommand32 : OledMem  := ((X"31",X"35",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"4C", game_cnt),
                                  (X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"EF"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"),
                                  (X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"FF",X"20"));
constant win : OledMem  := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                            (X"20",X"20",X"20",X"20",X"59",X"4F",X"55",X"20",X"20",X"57",X"4F",X"4E",X"20",X"20",X"20",X"20"),
                            (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                            (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
constant next_level : OledMem  := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                   (X"20",X"20",X"20",X"20",X"4C",X"45",X"56",X"45",X"4C",X"20",X"3A",X"20", game_cnt,X"20",X"20",X"20"),
                                   (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                   (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));


signal current_state : states := Idle;
signal after_state : states;
signal after_page_state : states;
signal after_char_state : states;
signal after_update_state : states;
signal temp_dc : std_logic := '0';
signal temp_delay_ms : std_logic_vector(11 downto 0);
signal temp_delay_en : std_logic := '0';
signal temp_delay_fin : std_logic;
signal temp_spi_en : std_logic := '0';
signal temp_spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal temp_spi_fin : STD_LOGIC;
signal temp_char : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal temp_addr : STD_LOGIC_VECTOR (10 downto 0) := (others => '0');
signal temp_dout : STD_LOGIC_VECTOR (7 downto 0);
signal temp_page : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
signal temp_index : integer range 0 to 15 := 0;
signal x_coord : integer := 0;
signal game_clk : std_logic := '0';
signal level_temp_delay_ms : std_logic_vector(11 downto 0) := "000111110100";
begin
    DC<= temp_dc;
    FIN <= '1' when (current_state = Done) else '0';
    SPI_COMP: SPI_interface PORT MAP (
        CLK => CLK,
        RST => RST,
        SPI_EN => temp_spi_en,
        SPI_DATA => temp_spi_data,
        CS => CS,
        SDO => SDO,
        SCLK => SCLK,
        SPI_FIN => temp_spi_fin
    );
    DELAY_COMP: Delay PORT MAP (
        CLK => CLK,
        RST => RST,
        DELAY_MS => temp_delay_ms,
        DELAY_EN => temp_delay_en,
        DELAY_FIN => temp_delay_fin
    );
    CHAR_LIB_COMP : ascii_rom PORT MAP (
        clk => CLK,
        addr => temp_addr,
        dout => temp_dout
    );
    process(CLK)
    begin
        if(rising_edge(CLK)) then
            if(RST = '1') then 
                level_temp_delay_ms <= "000111110100";
                game_cnt <= X"30";
                current_state <= Idle;
            end if;
            case(current_state) is 
                when Idle =>
                    if(EN = '1') then
                        current_state <= ClearDC;
                        if(JUMP = '0') then
                            after_page_state <= Command1;
                        else
                            after_page_state <= Command2;
                        end if;
                        temp_page <= "00";
                    end if;
                -- Game Begins
                when Command1 =>
                    current_screen <= ccommand1;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait1;
                when Wait1 =>
                    temp_delay_ms <= level_temp_delay_ms; --500
                    if(JUMP = '0') then 
                        after_state <= Command3;
                    else
                        after_state <= Command4;
                    end if;
                    current_state<= Transition3;
                when Command2 =>
                    current_screen<= ccommand2;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait1;
                when Command3 =>
                    current_screen <= ccommand3;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait2;
                when Command4 => 
                    current_screen <= ccommand4;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait2;
                when Wait2 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command5;
                    else
                        after_state <= Command6;
                    end if;
                    current_state<= Transition3;
                when Command5 =>
                    current_screen <= ccommand5;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait3;
                when Command6 =>
                    current_screen <= ccommand6;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait3;
                when Wait3 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command7;
                    else
                        after_state <= Command8;
                    end if;
                    current_state<= Transition3;
                when Command7 =>
                    current_screen <= ccommand7;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait4;
                when Command8 =>
                    current_screen <= ccommand8;
                    after_update_state <= Done;
                    current_state <= UpdateScreen;
                when Wait4 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command9;
                    else
                        after_state <= Command10;
                    end if;
                    current_state<= Transition3;
                when Command9 =>
                    current_screen <= ccommand9;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait5;
                when Command10 =>
                    current_screen <= ccommand10;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait5;
                when Wait5 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command11;
                    else
                        after_state <= Command12;
                    end if;
                    current_state<= Transition3;
                when Command11 =>
                    current_screen <= ccommand11;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait6;
                when Command12 =>
                    current_screen <= ccommand12;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait6;
                when Wait6 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command13;
                    else
                        after_state <= Command14;
                    end if;
                    current_state<= Transition3;
                when Command13 =>
                    current_screen <= ccommand13;
                    after_update_state <= Done;
                    current_state <= UpdateScreen;
                when Command14 =>
                    current_screen <= ccommand14;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait7;
                when Wait7 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command15;
                    else
                        after_state <= Command16;
                    end if;
                    current_state<= Transition3;
                when Command15 =>
                    current_screen <= ccommand15;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait8;
                when Command16 =>
                    current_screen <= ccommand16;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait8;
                when Wait8 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command17;
                    else
                        after_state <= Command18;
                    end if;
                    current_state<= Transition3;
                when Command17 =>
                    current_screen <= ccommand17;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait9;
                when Command18 =>
                    current_screen <= ccommand18;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait9;
                when Wait9 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command19;
                    else
                        after_state <= Command20;
                    end if;
                    current_state<= Transition3;
                when Command19 =>
                    current_screen <= ccommand19;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait10;
                when Command20 =>
                    current_screen <= ccommand20;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait10;
                when Wait10 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command21;
                    else
                        after_state <= Command22;
                    end if;
                    current_state<= Transition3;
                when Command21 =>
                    current_screen <= ccommand21;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait11;
                when Command22 =>
                    current_screen <= ccommand22;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait11;
                when Wait11 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command23;
                    else
                        after_state <= Command24;
                    end if;
                    current_state<= Transition3;
                when Command23 => 
                    current_screen <= ccommand23;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait12;
                when Command24 =>
                    current_screen <= ccommand24;
                    after_update_state <= Done;
                    current_state <= UpdateScreen;
                when Wait12 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command25;
                    else
                        after_state <= Command26;
                    end if;
                    current_state<= Transition3;
                when Command25 =>
                    current_screen <= ccommand25;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait13;
                when Command26 =>
                    current_screen <= ccommand26;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait13;
                when Wait13 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command27;
                    else
                        after_state <= Command28;
                    end if;
                    current_state<= Transition3;
                when Command27 =>
                    current_screen <= ccommand27;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait14;
                when Command28 =>
                    current_screen <= ccommand28;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait14;
                when Wait14=>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command29;
                    else
                        after_state <= Command30;
                    end if;
                    current_state<= Transition3;
                when Command29 =>
                    current_screen <= ccommand29;
                    after_update_state <= Done;
                    current_state <= UpdateScreen;
                when Command30 =>
                    current_screen <= ccommand30;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait15;
                when Wait15 =>
                    temp_delay_ms <= level_temp_delay_ms;
                    if(JUMP = '0') then 
                        after_state <= Command31;
                    else
                        after_state <= Command32;
                    end if;
                    current_state<= Transition3;
                when Command31 => 
                    current_screen <= ccommand31;
                    current_state <= UpdateScreen;
                    game_cnt <= game_cnt + 1;
                    level_temp_delay_ms <= level_temp_delay_ms - 50;
                    if(game_cnt = X"38") then
                        after_update_state <= Wait16;
                    else
                        after_update_state <= Wait17;
                    end if;
                when Command32 =>
                    current_screen <= ccommand32;
                    current_state <= UpdateScreen;
                    game_cnt <= game_cnt + 1;
                    level_temp_delay_ms <= level_temp_delay_ms - 50;
                    if(game_cnt = "00000100") then
                        after_update_state <= Wait16;
                    else
                        after_update_state <= Wait17;
                    end if;
                when Wait16 =>
                    temp_delay_ms <= "000111110100";
                    after_state <= won;
                    current_state <= Transition3;
                when Wait17 =>
                    temp_delay_ms <= "000111110100";
                    after_state <= Changelevel;
                    current_state <= Transition3;
                when Changelevel =>
                    current_screen <= next_level;
                    after_update_state <= Wait18;
                    current_state <= UpdateScreen;
                when Wait18 =>
                    temp_delay_ms <= "000111110100";
                    after_state <= Command1;
                    current_state <= Transition3;
                when won =>
                    current_screen <= win;
                    after_update_state <= Done;
                    current_state <= UpdateScreen;
                when Done => 
                    if(EN = '0') then
                        current_state <= Idle;
                    end if;
                when ClearDC =>
                    temp_dc<= '0';
                    current_state <= SetPage;
                when SetPage =>
                    temp_spi_data <= "00100010";
                    after_state <= PageNum;
					current_state <= Transition1;
				when PageNum =>
					temp_spi_data <= "000000" & temp_page;
					after_state <= LeftColumn1;
					current_state <= Transition1;
				when LeftColumn1 =>
					temp_spi_data <= "00000000";
					after_state <= LeftColumn2;
					current_state <= Transition1;
				when LeftColumn2 =>
					temp_spi_data <= "00010000";
					after_state <= SetDC;
					current_state <= Transition1;
				when SetDC =>
					temp_dc <= '1';
                    current_state <= after_page_state;


                when SendChar1 =>
					temp_addr <= temp_char & "000";
					after_state <= SendChar2;
					current_state <= ReadMem;
				when SendChar2 =>
					temp_addr <= temp_char & "001";
					after_state <= SendChar3;
					current_state <= ReadMem;
				when SendChar3 =>
					temp_addr <= temp_char & "010";
					after_state <= SendChar4;
					current_state <= ReadMem;
				when SendChar4 =>
					temp_addr <= temp_char & "011";
					after_state <= SendChar5;
					current_state <= ReadMem;
				when SendChar5 =>
					temp_addr <= temp_char & "100";
					after_state <= SendChar6;
					current_state <= ReadMem;
				when SendChar6 =>
					temp_addr <= temp_char & "101";
					after_state <= SendChar7;
					current_state <= ReadMem;
				when SendChar7 =>
					temp_addr <= temp_char & "110";
					after_state <= SendChar8;
					current_state <= ReadMem;
				when SendChar8 =>
					temp_addr <= temp_char & "111";
					after_state <= after_char_state;
					current_state <= ReadMem;
				when ReadMem =>
					current_state <= ReadMem2;
				when ReadMem2 =>
					temp_spi_data <= temp_dout;
					current_state <= Transition1;
                when Transition1 =>
					temp_spi_en <= '1';
					current_state <= Transition2;
				when Transition2 =>
					if(temp_spi_fin = '1') then
						current_state <= Transition5;
                    end if; 
                when Transition3 =>
					temp_delay_en <= '1';
					current_state <= Transition4;
				when Transition4 =>
					if(temp_delay_fin = '1') then
						current_state <= Transition5;
                    end if;
                when Transition5 =>
					temp_spi_en <= '0';
					temp_delay_en <= '0';
                    current_state <= after_state;

                when UpdateScreen => 
                    temp_char <= current_screen(CONV_INTEGER(temp_page),temp_index);
                    if(temp_index = 15) then	
                        temp_index <= 0;
                        temp_page <= temp_page + 1;
                        after_char_state <= ClearDC;
                        if(temp_page = "11") then
                            after_page_state <= after_update_state;
                        else	
                            after_page_state <= UpdateScreen;
                        end if;
                    else
                        temp_index <= temp_index + 1;
                        after_char_state <= UpdateScreen;
                    end if;
                    current_state <= SendChar1;
                when others =>
                    current_state <= Idle;
            end case;
        end if;
    end process;
    --process(JUMP, CLK)
    --begin
      --  if(JUMP = '1') then

    --CLK_GAME : process(CLK)
    --begin 
       -- if(rising_edge(CLK)) then
         --   if(game_cnt = 25000000) then
       --         game_cnt <= 0;
     --           game_clk <= not game_clk;
   --         else
    --            game_cnt <= game_cnt  +1;
    --        end if;
    --    end if;
    --end process;

end Behavioral;    
