library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- g_CLKS_Per_Bit (25000000 clks/s / 115200 bps) = 217
-- UART Comm, we want to sample bits at middle to avoid transition between bits (could give faulty data)
entity UART_TX is
    generic (
        g_CLKS_PER_BIT : integer := 217
    );
    port (
        i_Clk       : in  std_logic;
        i_TX_DV     : in  std_logic;
        i_TX_Byte   : in  std_logic_vector(7 downto 0);
        o_TX_Active : out std_logic;
        o_TX_Serial : out std_logic;
        o_TX_Done   : out std_logic
    );
end entity;

architecture rtl of UART_TX is

    --creating type to define states for UART TX communication
    type t_SM_Main is (s_idle, s_startbit, s_databits, s_stopbit, s_cleanup);

    signal r_SM_Main : t_SM_Main := s_idle;
    signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
    signal r_Bit_Index : integer range 0 to 7 := 0;
    signal r_TX_Data : std_logic_vector(7 downto 0) := (others => '0'); 
    signal r_TX_Done : std_logic := '0';

begin
   p_UART_TX: process(i_Clk)
   begin
       if rising_edge(i_Clk) then
           r_TX_Done <= '0';  --initially no comm

           case r_SM_Main is
               when s_idle =>
                   o_TX_Active <= '0';
                   o_TX_Serial <= '1'; -- drive serial high to indicate no start
                   r_Clk_Count <= 0;
                   r_Bit_Index <= 0;

                   if i_TX_DV = '1' then
                       r_TX_Data <= i_TX_Byte;
                       r_SM_Main <= s_startbit;
                   else
                       r_SM_Main <= s_idle;
                   end if;

               when s_startbit =>
                   o_TX_Active <= '1'; -- comm is now active
                   o_TX_Serial <= '0'; --- drive serial low to indicate startbit

                   --stay in state for one clock cycle (length of start bit)
                   if r_Clk_Count < g_CLKS_PER_BIT-1 then
                       r_Clk_Count <= r_Clk_Count + 1;
                       r_SM_Main <= s_startbit;
                   else
                       r_Clk_Count <= 0;
                       r_SM_Main <= s_databits;
                   end if;

               when s_databits => 
                   o_TX_Serial <= r_TX_Data(r_Bit_Index); --send data bits at appropriate index
                   
                   
                   --stay in state for one clock cycle (length of bit)
                   if r_Clk_Count < g_CLKS_PER_BIT-1 then
                       r_Clk_Count <= r_Clk_Count + 1;
                       r_SM_Main <= s_databits;
                   else
                       r_Clk_Count <= 0;
                        
                       if r_Bit_Index < 7 then-- check to ensure all bits sent
                           r_Bit_Index <= r_Bit_Index + 1;
                           r_SM_Main <= s_databits;
                       else
                           r_Bit_Index <= 0;
                           r_SM_Main <= s_stopbit;
                       end if;
                   end if;

               when s_stopbit =>
                   o_TX_Serial <= '1';-- sending out stop bit

                   --stay in state for one clock cycle (length of bit)
                   if r_Clk_Count < g_CLKS_PER_BIT-1 then
                       r_Clk_Count <= r_Clk_Count + 1;
                       r_SM_Main <= s_stopbit;
                   else
                       r_TX_Done <= '1';
                       r_Clk_Count <= 0;
                       r_SM_Main <= s_cleanup;
                   end if;

               when s_cleanup =>
                   o_TX_Active <= '0';
                   r_SM_Main <= s_idle;

               when others =>
                   r_SM_Main <= s_idle;
           end case;
       end if;
   end process p_UART_TX;

   o_TX_Done <= r_TX_Done; -- indicate completion

end architecture;
