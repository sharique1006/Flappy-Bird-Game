library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SPI_interface is
    Port (CLK : in std_logic;
          RST : in std_logic;
          SPI_EN : in std_logic;
          SPI_DATA : in std_logic_vector (7 downto 0);
          CS : out std_logic;
          SDO : out std_logic;
          SCLK : out std_logic;
          SPI_FIN : out std_logic);
end SPI_interface;

architecture Behavioral of SPI_interface is

    type state is (Idle, Send, Done);
    signal current_state : state := Idle;
    signal sclk_temp : std_logic := '1';
    signal counter : integer := 0;
    signal send_counter : integer := 0;
    signal temp_sdo : std_logic := '1';
    signal temp_data : std_logic_vector(7 downto 0) := "00000000";
    signal falling : std_logic := '1';

begin
    SDO<=temp_sdo;
    SCLK<= sclk_temp;
    CS<= '1' when (current_state = Idle and SPI_EN = '0') else '0';
    SPI_FIN<= '1' when(current_state = Done) else '0';

    process(CLK)
        begin
            if(rising_edge(CLK)) then 
                if(RST = '1') then
                    current_state <= Idle;
                else
                    case(current_state) is 
                        when Idle=>
                            if(SPI_EN = '1') then
                                current_state<= Send;
                            end if;
                            counter<= 0;
                            send_counter <= 0;
                            temp_data <= SPI_DATA;
                            temp_sdo <= '1';
                        when Send=>
                            if(send_counter = 8 and falling = '1') then
                                current_state <= Done;
                            end if;
                            if(counter = 0) then
                                falling <= '1';
                            elsif(counter = 15) then 
                                sclk_temp <= '0';
                            elsif(counter = 16 and falling = '1') then
                                temp_sdo <= temp_data(7 - send_counter);
                                falling <= '0';
                                send_counter <= send_counter + 1;
                            elsif(counter = 31) then 
                                sclk_temp <= '1';
                            end if;
                            if(counter = 31) then 
                                counter <= 0;
                            else
                                counter <= counter + 1;
                            end if;
                        when Done =>
                            if(SPI_EN = '0') then
                                current_state <= Idle;
                            end if;
                        when others=> 
                                current_state <= Idle;
                    end case;
                end if;
            end if;
    end process;
end Behavioral;
