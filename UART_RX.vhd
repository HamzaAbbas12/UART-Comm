library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- g_CLKS_Per_Bit (25000000 clks/s / 115200 bps) = 217
-- UART Comm, we want to sample bits at middle to avoid transition between bits (could give faulty data)
entity UART_RX is
    generic (
        g_CLKS_PER_BIT : integer := 217
    );
    port (
        i_Clk   : in std_logic;
        i_RX_Serial : in std_logic;
        o_RX_DV : out std_logic;
        o_RX_Byte : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of UART_RX is
    --creating our own type for each state during UART comm 
    type t_SM_Main is (s_idle, s_startbit, s_databits, s_stopbit, s_cleanup);

    signal r_SM_Main : t_SM_Main := s_idle; -- setting initial state to idle (nothing happened yet)
    
    signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0; -- 8 total bits
    signal r_RX_Byte : std_logic_vector(7 downto 0) := (others => '0');
    signal r_RX_DV : std_logic := '0';

begin
    -- create process that controls the UART RX State Machine
    p_UART_RX: process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            case r_SM_Main is

                when s_idle =>
                    r_RX_DV <= '0';
                    r_Clk_Count <= 0;
                    r_Bit_Index <= 0;

                    if i_RX_Serial = '0' then -- start bit
                        r_SM_Main <= s_startbit;
                    else
                        r_SM_Main <= s_idle;
                    end if;
                
                when s_startbit =>
                    if r_Clk_Count = (g_CLKS_PER_BIT - 1) / 2 then -- finding the middle of the bits to ensure correct data
                        if i_RX_Serial = '0' then
                            r_Clk_Count <= 0; -- middle found, counter is reset
                            r_SM_Main <= s_databits;
                        else
                            r_SM_Main <= s_idle; -- if the center isn't 0, start bit incorrect, restart at idle
                        end if;
                    else
                        r_Clk_Count <= r_Clk_Count + 1; -- increment counter
                        r_SM_Main <= s_startbit; -- keep looking for start bit
                    end if;

                when s_databits =>
                    if r_Clk_Count < g_CLKS_PER_BIT - 1 then -- wait for center of data bit to be reached, increment if not
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_databits;
                    else
                        r_Clk_Count <= 0;
                        r_RX_Byte(r_Bit_Index) <= i_RX_Serial; -- take the data bit, add it to the byte at correct index
                        
                        if r_Bit_Index < 7 then -- increment that bit index until 8 bits received
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_SM_Main <= s_databits; -- 8 bits not received, keep collecting data
                        else
                            r_Bit_Index <= 0; -- 8 bits received, restart bit index and go to stop bit state
                            r_SM_Main <= s_stopbit;
                        end if;
                    end if;

                when s_stopbit =>
                    -- wait for stop bit to finish
                    if r_Clk_Count < g_CLKS_PER_BIT - 1 then
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_stopbit;
                    else
                        r_RX_DV <= '1';
                        r_Clk_Count <= 0;
                        r_SM_Main <= s_cleanup;
                    end if;
                    
                when s_cleanup =>
                    r_SM_Main <= s_idle;
                    r_RX_DV <= '0';

                when others =>
                    r_SM_Main <= s_idle;
            end case;
        end if;
    end process p_UART_RX;

    o_RX_DV <= r_RX_DV;
    o_RX_Byte <= r_RX_Byte;

end architecture;
