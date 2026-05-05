----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

begin

process(i_A, i_B, i_op)
    variable v_A_uns, v_B_uns   :   unsigned(8 downto 0);
    variable v_res_uns          :   unsigned(8 downto 0);
    variable v_result_8bit      :   std_logic_vector(7 downto 0);
    
begin
    v_A_uns :=  unsigned('0' & i_A);
    v_B_uns :=  unsigned('0' & i_B);
    
    case i_op is
        when "000" =>
            v_res_uns       := v_A_uns + v_B_uns;
            v_result_8bit   := std_logic_vector(v_res_uns(7 downto 0));
            o_flags(1)      <= std_logic(v_res_uns(8));
            
            if (i_A(7) = '0' and i_B(7) = '0' and v_result_8bit(7) = '1')
            or (i_A(7) = '1' and i_B(7) = '1' and v_result_8bit(7) = '0') then
                o_flags(0)  <= '1';
            else
                o_flags(0)  <= '0';
            end if;
            
         when "001" =>
            v_res_uns       :=  v_A_uns - v_B_uns;
            v_result_8bit   := std_logic_vector(signed(i_A) - signed(i_B));
            o_flags(1)      <= std_logic(v_res_uns(8));
            
            if (i_A(7) = '0' and i_B(7) = '1' and v_result_8bit(7) = '1') 
            or (i_A(7) = '1' and i_B(7) = '0' and v_result_8bit(7) = '0') then
                o_flags(0) <= '1';
            else
                o_flags(0) <= '0';
            end if;
            
         when "010" => 
            v_result_8bit   := i_A and i_B;
            o_flags(1)      <= '0';
            o_flags(0)      <= '0';
            
        when "011" =>
            v_result_8bit       := i_A or i_B;
            o_flags(1)          <= '0';
            o_flags(0)          <= '0';
            
        when others =>
            v_result_8bit   := (others => '0');
            o_flags(1)      <= '0';
            o_flags(0)      <= '0';
    end case;
    
    
    o_result <= v_result_8bit;
    
    o_flags(3) <= v_result_8bit(7);
    
    if v_result_8bit = "00000000" then
        o_flags(2)  <= '1';
    else
        o_flags(2)  <= '0';
    end if;
end process;

            
            

end Behavioral;
