library ieee;
use ieee.std_logic_1164.all;

entity UART_Loopback is
    port (
        i_Clk  : in std_logic;
        
        i_UART_RX : in std_logic;
        o_UART_TX : out std_logic;

        -- Upper Digit 
        o_Segment1_A : out std_logic;
        o_Segment1_B : out std_logic;
        o_Segment1_C : out std_logic;
        o_Segment1_D : out std_logic;
        o_Segment1_E : out std_logic;
        o_Segment1_F : out std_logic;
        o_Segment1_G : out std_logic;

        -- Lower Digit
        o_Segment2_A : out std_logic;
        o_Segment2_B : out std_logic;
        o_Segment2_C : out std_logic;
        o_Segment2_D : out std_logic;
        o_Segment2_E : out std_logic;
        o_Segment2_F : out std_logic;
        o_Segment2_G : out std_logic
    );
end entity;

architecture rtl of UART_Loopback is

    signal w_RX_DV : std_logic;
    signal w_RX_Byte : std_logic_vector(7 downto 0);
    signal w_TX_Active : std_logic;
    signal w_TX_Serial : std_logic;

    signal w_Segment1_A, w_Segment2_A : std_logic;
    signal w_Segment1_B, w_Segment2_B : std_logic;
    signal w_Segment1_C, w_Segment2_C : std_logic;
    signal w_Segment1_D, w_Segment2_D : std_logic;
    signal w_Segment1_E, w_Segment2_E : std_logic;
    signal w_Segment1_F, w_Segment2_F : std_logic;
    signal w_Segment1_G, w_Segment2_G : std_logic;

begin
    UART_RX_Inst : entity work.UART_RX
        generic map (
            g_CLKS_PER_BIT => 217 -- 25000000 frequency, 115200 bps = cycles per period
        )
        port map (
            i_Clk => i_Clk,  
            i_RX_Serial => i_UART_RX,
            o_RX_DV => w_RX_DV,
            o_RX_Byte => w_RX_Byte
        );
    UART_TX_Inst : entity work.UART_TX
        generic map (
            g_CLKS_PER_BIT => 217)               -- 25,000,000 / 115,200 = 217
        port map (
            i_Clk       => i_Clk,
            i_TX_DV     => w_RX_DV,
            i_TX_Byte   => w_RX_Byte,
            o_TX_Active => w_TX_Active,
            o_TX_Serial => w_TX_Serial,
            o_TX_Done   => open
        );
    
    --drive UART line high when transmitter inactive
    o_UART_TX <= w_TX_Serial when w_TX_Active = '1' else '1';

    SevenSeg1_Inst : entity work.Binary_To_7Segment
        port map (
            i_Clk => i_Clk,
            i_Binary_Num => w_RX_Byte(7 downto 4), -- given it the bits 7-4 to display first number
            o_Segment_A => w_Segment1_A,
            o_Segment_B => w_Segment1_B,
            o_Segment_C => w_Segment1_C,
            o_Segment_D => w_Segment1_D,
            o_Segment_E => w_Segment1_E,
            o_Segment_F => w_Segment1_F,
            o_Segment_G => w_Segment1_G
        );

    o_Segment1_A <= not w_Segment1_A; -- segments turn on by driving it to a logic low, why we not the output
    o_Segment1_B <= not w_Segment1_B;
    o_Segment1_C <= not w_Segment1_C;
    o_Segment1_D <= not w_Segment1_D;
    o_Segment1_E <= not w_Segment1_E;
    o_Segment1_F <= not w_Segment1_F;
    o_Segment1_G <= not w_Segment1_G;

    SevenSeg2_Inst : entity work.Binary_To_7Segment
        port map (
            i_Clk => i_Clk,
            i_Binary_Num => w_RX_Byte(3 downto 0), -- displaying bits 3 to 0
            o_Segment_A => w_Segment2_A,
            o_Segment_B => w_Segment2_B,
            o_Segment_C => w_Segment2_C,
            o_Segment_D => w_Segment2_D,
            o_Segment_E => w_Segment2_E,
            o_Segment_F => w_Segment2_F,
            o_Segment_G => w_Segment2_G
        );

    o_Segment2_A <= not w_Segment2_A; -- segments turn on by driving it to a logic low, why we not the output
    o_Segment2_B <= not w_Segment2_B;
    o_Segment2_C <= not w_Segment2_C;
    o_Segment2_D <= not w_Segment2_D;
    o_Segment2_E <= not w_Segment2_E;
    o_Segment2_F <= not w_Segment2_F;
    o_Segment2_G <= not w_Segment2_G;

end architecture rtl;
