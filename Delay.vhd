library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Delay is 
    Port( CLK : in std_logic;
          RST : in std_logic;
          DELAY_MS : in std_logic_vector(11 downto 0); -- check whether it can be int or vector
          DELAY_EN : in std_logic;
          DELAY_FIN : out std_logic);
end Delay;

architecture Behavioral of Delay is

    type states is (Idle, Hold, Done);
    signal current_state : states := Idle;
    signal clk_counter : std_logic_vector(16 downto 0) := (others => '0');
    signal ms_counter : std_logic_vector (11 downto 0) := (others => '0');

    begin 
        DELAY_FIN <= '1' when (current_state = Done and DELAY_EN = '1') else '0';
        
        STATE_MACHINE : process(CLK)
        begin 
            if(rising_edge(clk)) then 
                if(RST = '1') then 
                    current_state <= Idle;
                else
                    case current_state is
                        when Idle=>
                            if(DELAY_EN = '1') then 
                                current_state <= Hold;
                            end if;
                        when Hold => 
                            if(ms_counter = DELAY_MS) then
                                current_state <= Done;
                            end if;
                        when others =>
                            current_state <= Idle;
                    end case;
                end if;
            end if;
        end process;

        CLK_DIV : process(CLK)
        begin 
            if(CLK'event and CLK = '1') then 
                if(current_state = Hold) then 
                    if(clk_counter = "11000011010100000") then 
                        clk_counter <= (others => '0');
                        ms_counter <= ms_counter + 1;
                    else
                        clk_counter <= clk_counter + 1;
                    end if;
                else
                    clk_counter <= (others => '0');
                    ms_counter <= (others => '0');
                end if;
            end if;
        end process;
    end Behavioral;