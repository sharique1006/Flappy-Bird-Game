library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity OLEDInit is
    Port(CLK : in std_logic;
         RST : in std_logic;
         EN : in std_logic;
         CS : out std_logic;
         SDO : out std_logic;
         SCLK : out std_logic;
         DC : out std_logic;
         RES : out std_logic;
         VBAT : out std_logic;
         VDD : out std_logic;
         FIN : out std_logic);
end OLEDInit;

architecture Behavioral of OLEDInit is

COMPONENT SPI_interface
    Port(CLK : in std_logic;
         RST : in std_logic;
         SPI_EN : in std_logic;
         SPI_DATA : in std_logic_vector(7 downto 0);
         CS : out std_logic;
         SDO : out std_logic;
         SCLK : out std_logic;
         SPI_FIN : out std_logic);
END COMPONENT;

COMPONENT Delay
    Port(CLK : in std_logic;
         RST : in std_logic;
         DELAY_MS : in std_logic_vector(11 downto 0);
         DELAY_EN : in std_logic;
         DELAY_FIN : out std_logic);
END COMPONENT;

type states is(Idle, VddOn, Wait1, DispOff, ResetOn, Wait2, ResetOff, ChargePump1, ChargePump2, PreCharge1, PreCharge2, VbatOn, Wait3, DispContrast1, DispContrast2, InvertDisp1, InvertDisp2, ComConfig1, ComConfig2, DispOn, FullDisp, Transition1, Transition2, Transition3, Transition4, Transition5, Done);
signal current_state : states := Idle;
signal after_state : states := Idle;

signal temp_dc : std_logic := '0';
signal temp_res : std_logic := '1';
signal temp_vbat : std_logic := '1';
signal temp_vdd : STD_LOGIC := '1';
signal temp_fin : STD_LOGIC := '0';

signal temp_delay_ms : STD_LOGIC_VECTOR (11 downto 0) := (others => '0');
signal temp_delay_en : STD_LOGIC := '0';
signal temp_delay_fin : STD_LOGIC;
signal temp_spi_en : STD_LOGIC := '0';
signal temp_spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal temp_spi_fin : STD_LOGIC;

begin 
    SPI_COMP : SPI_interface Port Map(
        CLK => CLK,
        RST => RST,
        SPI_EN => temp_spi_en,
        SPI_DATA => temp_spi_data,
        CS => CS,
        SDO => SDO,
        SCLK => SCLK,
        SPI_FIN => temp_spi_fin
    );

    DELAY_COMP : Delay Port Map (
        CLK => CLK,
        RST => RST,
        DELAY_MS => temp_delay_ms,
        DELAY_EN => temp_delay_en,
        DELAY_FIN => temp_delay_fin
    );

    DC<= temp_dc;
    RES <= temp_res;
    VBAT <= temp_vbat;
    VDD <= temp_vdd;
    FIN <= temp_fin;

-- Delay 100ms after VbatOn // check the pdf once...
    temp_delay_ms <= "000001100100" when (after_state = DispContrast1) else "000000000001";

    STATE_MACHINE : process(CLK)
    begin
        if(rising_edge(CLK)) then 
            if(RST = '1') then
                current_state <= Idle;
                temp_res<= '0';
            else
                temp_res <= '1';
                case current_state is
                    when Idle =>
                        if(EN = '1') then
                            temp_dc <= '0';
                            current_state <= VddOn;
                        end if;
                    when VddOn =>
                        temp_vdd <= '0';
                        current_state <= Wait1;
                    when Wait1 =>
                        after_state <= DispOff;
                        current_state <= Transition3;
                    when DispOff =>
                        temp_spi_data <= "10101110";
                        after_state <= ResetOn;
                        current_state <= Transition1;
                    when ResetOn =>
                        temp_res <= '0';
                        current_state <= Wait2;
                    when Wait2 =>
                        after_state <= ResetOff;
                        current_state <= Transition3;
                    when ResetOff =>
                        temp_res <= '1';
                        after_state<= ChargePump1;
                        current_state <= Transition3;
                    when ChargePump1 =>
                        temp_spi_data <= "10001101";
                        after_state <= ChargePump2;
                        current_state <= Transition1;
                    when ChargePump2 =>
                        temp_spi_data <= "00010100";
                        after_state <= PreCharge1;
                        current_state <= Transition1;
                    when PreCharge1 =>
                        temp_spi_data <= "11011001";
                        after_state <= PreCharge2;
                        current_state <= Transition1;
                    when PreCharge2 => 
                        temp_spi_data <= "11111001";
                        after_state <= VbatOn;
                        current_state <= Transition1;
                    when VbatOn =>
                        temp_vbat <= '0';
                        current_state <= Wait3;
                    when Wait3 => 
                        after_state <= DispContrast1;
                        current_state <= Transition3;
                    when DispContrast1 =>
                        temp_spi_data <= "10000001";
                        after_state <= DispContrast2;
                        current_state <= Transition1;
                    when DispContrast2 =>
                        temp_spi_data <= "00001111";
                        after_state <= InvertDisp1;
                        current_state <= Transition1;
                    when InvertDisp1 =>
                        temp_spi_data <= "10100001";
                        after_state <= InvertDisp2;
                        current_state <= Transition1;
                    when InvertDisp2 =>
                        temp_spi_data <= "11001000";
                        after_state <= ComConfig1;
                        current_state <= Transition1;
                    when ComConfig1 =>
                        temp_spi_data <= "11011010";
                        after_state <= ComConfig2;
                        current_state <= Transition1;
                    when ComConfig2 =>
                        temp_spi_data <= "00100000";
                        after_state <= DispOn;
                        current_state <= Transition1;
                    when DispOn =>
                        temp_spi_data <= "10101111";
                        after_state <= Done;
                        current_state <= Transition1;
                    when Done =>
                        if(EN = '0') then
                            temp_fin <= '0';
                            current_state <= Idle;
                        else
                            temp_fin <= '1';
                        end if;
                    
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
                    when FullDisp =>
                        temp_spi_data <= "10100101";
                        after_state <= Done;
                        current_state <= Transition1;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;
end Behavioral;