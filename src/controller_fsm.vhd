----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( clk : in STD_LOGIC;
           i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
           
end controller_fsm;

architecture FSM of controller_fsm is
    type sm_state is (s_CLEAR, s_OP1, s_OP2, s_RESULT);
    signal f_state, f_next_state : sm_state;
    

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if i_reset = '1' then
                f_state <= s_CLEAR;
            else
                f_state <= f_next_state;
            end if;
        end if;
    end process;

    process(f_state, i_adv)
    begin
        f_next_state <= f_state;
        case f_state is
            when s_CLEAR =>
                if i_adv = '1' then f_next_state <= s_OP1;
                end if;
            when s_OP1 =>
                if i_adv = '1' then f_next_state <= s_OP2;
                end if;
             when s_OP2 =>
                if i_adv = '1' then f_next_state <= s_RESULT;
                end if;
            when s_RESULT =>
                if i_adv = '1' then f_next_state <= s_CLEAR;
                end if;
            when others => 
                f_next_state <= s_CLEAR;
        end case;
    end process;
    
process(clk)
    begin
        if rising_edge(clk) then
            if i_reset = '1' then
                o_cycle <= "0001";
            else
                case f_next_state is 
                    when s_CLEAR  => o_cycle <= "0001";
                    when s_OP1    => o_cycle <= "0010";
                    when s_OP2    => o_cycle <= "0100";
                    when s_RESULT => o_cycle <= "1000";
                    when others   => o_cycle <= "0000";
                end case;
            end if;
        end if;
    end process;
        

end FSM;
