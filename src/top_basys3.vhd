--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic;
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    
    component ALU is
        Port ( i_A  :   in std_logic_vector(7 downto 0);
               i_B  :   in std_logic_vector(7 downto 0);
               i_op :   in std_logic_vector(2 downto 0);
               
               o_result :   out std_logic_vector(7 downto 0);
               o_flags  :   out std_logic_vector(3 downto 0));
    end component;
    
    component controller_fsm is
        port (  clk     : in std_logic;
                i_reset : in std_logic;
                i_adv   : in std_logic;
                
                o_cycle :   out std_logic_vector(3 downto 0));
    end component;
    
    component sevenseg_decoder is
        port ( i_Hex : in std_logic_vector(3 downto 0);
               o_seg_n : out std_logic_vector(6 downto 0));
    end component;
    
    --signals
    
    signal v_count_tdm  :   unsigned(15 downto 0) := (others => '0');
    signal w_tdm_sel    :   std_logic_vector(1 downto 0);
    
    signal w_btnC_reg1, w_btnC_reg2, w_adv  :   std_logic;
    
    signal w_cycle  :   std_logic_vector(3 downto 0);
    signal w_op1, w_op2, w_alu_out  :   std_logic_vector(7 downto 0);
    signal w_mux_out    :   std_logic_vector(7 downto 0);
    
    signal w_mag    :   std_logic_vector(7 downto 0);
    signal w_sign   :   std_logic;
    signal w_hund, w_tens, w_ones   :   std_logic_vector(3 downto 0);
    signal w_seg_data  :   std_logic_vector(3 downto 0);
    signal w_seg_out    :   std_logic_vector(6 downto 0);
  
    signal v_bounce_count : unsigned(19 downto 0) := (others => '0');
    signal w_btnC_clean : std_logic := '0';
    
begin
	-- PORT MAPS ----------------------------------------
    alu_inst    :   ALU
    port map (
        i_A         => w_op1,
        i_B         => w_op2,
        i_op        => sw(15 downto 13),
        o_result    => w_alu_out,
        o_flags     => led(15 downto 12)
        );
	
	fsm_inst   :   controller_fsm
	port map ( 
	   clk     => clk,
	   i_reset => btnU,
	   i_adv   => w_adv,
	   o_cycle => w_cycle
	   );
	   
	   seg_inst    :   sevenseg_decoder
	   port map ( 
	       i_Hex => w_seg_data,
	       o_seg_n => w_seg_out
	       );
	
	-- CONCURRENT STATEMENTS ----------------------------
	process(clk, btnL)
	begin  
	   if btnL = '1' then
	      v_count_tdm <= (others => '0');
	   elsif rising_edge(clk) then
	       v_count_tdm <= v_count_tdm + 1;
	   end if;
	end process;
	w_tdm_sel <= std_logic_vector(v_count_tdm(15 downto 14));
	
	process(clk)
begin
    if rising_edge(clk) then
        if btnC = '1' then
            if v_bounce_count < x"FFFFF" then -- wait ~10ms
                v_bounce_count <= v_bounce_count + 1;
            else
                w_btnC_clean <= '1';
            end if;
        else
            v_bounce_count <= (others => '0');
            w_btnC_clean <= '0';
        end if;

        w_btnC_reg1 <= w_btnC_clean;
        w_btnC_reg2 <= w_btnC_reg1;
    end if;
end process;

w_adv <= w_btnC_reg1 and not w_btnC_reg2;
    
process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                w_op1 <= (others => '0');
                w_op2 <= (others => '0');
            else
                if w_cycle = "0010" then
                    w_op1 <= sw(7 downto 0);
                    w_op2 <= w_op2;

                elsif w_cycle = "0100" then
                    w_op1 <= w_op1;
                    w_op2 <= sw(7 downto 0);

                else
                    w_op1 <= w_op1;
                    w_op2 <= w_op2;
                end if;
            end if;
        end if;
    end process;
    
    w_mux_out <= x"00"  when w_cycle(0) = '1' else
                 w_op1  when w_cycle(1) = '1' else
                 w_op2  when w_cycle(2) = '1' else
                 w_alu_out when w_cycle(3) = '1' else
                 x"00";
    
    w_sign <= w_mux_out(7);
    w_mag <= std_logic_vector(unsigned(not w_mux_out) + 1) when w_sign = '1' else w_mux_out;
    
    
    
    process(w_mag)
        variable v_temp : integer;
    begin
        v_temp := to_integer(unsigned(w_mag));
        w_hund <= std_logic_vector(to_unsigned(v_temp / 100, 4));
        w_tens <= std_logic_vector(to_unsigned((v_temp rem 100) / 10, 4));
        w_ones <= std_logic_vector(to_unsigned(v_temp rem 10, 4));
    end process;
	
	process(w_tdm_sel, w_hund, w_tens, w_ones, w_sign)
	begin 
	   case w_tdm_sel is
	       when "00" => 
	           w_seg_data <= w_ones;
	           an <= "1110";
	       when "01" => 
	           w_seg_data <= w_tens;
	           if w_hund = x"0" and w_tens = x"0" then
	               an <= "1111";
	           else
	               an <= "1101";
	           end if;
	       when "10" =>
	           w_seg_data <= w_hund;
	           if w_hund = x"0" then
	               an <= "1111";
	           else
	               an <= "1011";
	           end if;
	       when others => 
	           w_seg_data <= x"0";
	           if w_sign = '1' then
	               an <= "0111";
	           else
	               an <= "1111";
	           end if;
	       end case;
	   end process;
	   
	   
	   seg <= "0111111" when (w_tdm_sel = "11" and w_sign = '1') else w_seg_out;
	   
       led(11 downto 4) <= (others => '0');
       led(3 downto 0) <= w_cycle;	   
	
end top_basys3_arch;
