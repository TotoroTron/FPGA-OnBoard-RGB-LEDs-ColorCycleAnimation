library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity rgb_control is
    port(
        clk : in std_logic;
        rgb1, rgb2 : out std_logic_vector(2 downto 0)
    );
end entity;

architecture Behavioral of rgb_control is
    type STATE_TYPE is (INIT, GET_DATA, INCR_DUTY, SHIFT_COLOR);
    signal state, next_state : STATE_TYPE;
    type COLOR_TRANSITIONS is (RED_MAGENTA, MAGENTA_BLUE, BLUE_CYAN, CYAN_GREEN, GREEN_YELLOW, YELLOW_RED);
    signal phase, next_phase : COLOR_TRANSITIONS;
    signal di : std_logic_vector(23 downto 0) := X"FF0000"; --24bit color depth
    signal next_di : std_logic_vector(23 downto 0);
    signal duty, next_duty : integer range 0 to 255; --8bits per color: 256 levels for each color
    signal rep_count, next_rep_count: integer;
    signal next_rgb1, next_rgb2 : std_logic_vector(2 downto 0);
    signal clk2 : std_logic;
    constant delay : integer := 50;
    constant reps : integer := 20;
begin
    
    CLOCK_DIV: process(clk)
        variable count : integer range 0 to delay;
    begin
        if rising_edge(clk) then
            if count < delay/2 then
                clk2 <= '0';
                count := count + 1;
            elsif count < delay then
                clk2 <= '1';
                count := count + 1;
            else
                count := 0;
            end if;
        end if;
    end process;
    
    STATE_REGISTER: process(clk2)
    begin
        if rising_edge(clk2) then
            state <= next_state;
            di <= next_di;
            duty <= next_duty;
            rep_count <= next_rep_count;
            rgb1 <= next_rgb1;
            rgb2 <= next_rgb2;
            phase <= next_phase;
        end if;
    end process;
    
    STATE_MACHINE: process(state, di, duty, rep_count, phase)
        variable r_count, g_count, b_count : integer range 0 to 255;
        variable v_rgb1, v_rgb2 : std_logic_vector(2 downto 0);
    begin
        next_state <= state;
        next_di <= di;
        next_duty <= duty;
        next_rep_count <= rep_count;
        next_phase <= phase;
        r_count := to_integer( unsigned( di(23 downto 16) )); --255
        g_count := to_integer( unsigned( di(15 downto  8) )); --0
        b_count := to_integer( unsigned( di( 7 downto  0) )); --0
        v_rgb1 := "000";
        v_rgb2 := "000";
        
        case state is
        when INIT =>
            next_state <= GET_DATA;
        when GET_DATA =>
            if(duty < r_count ) then
                v_rgb1(0) := '1';
                v_rgb2(0) := '1';
            end if;
            if(duty < g_count ) then
                v_rgb1(1) := '1';
                v_rgb2(1) := '1';
            end if;
            if(duty < b_count ) then
                v_rgb1(2) := '1';
                v_rgb2(2) := '1';
            end if;
            next_state <= INCR_DUTY;
            
        when INCR_DUTY =>
            if(duty < 255) then
                next_duty <= duty + 1;
                next_state <= GET_DATA;
            else
                next_duty <= 0;
                if(rep_count < reps) then	--display the color 'reps' times before displaying next color
                    next_rep_count <= rep_count + 1;
                    next_state <= GET_DATA;
                else
                    next_rep_count <= 0;
                    next_state <= SHIFT_COLOR;
                end if;
            end if;
            
        when SHIFT_COLOR =>
            case phase is
            when RED_MAGENTA =>
                if(b_count < 255) then b_count := b_count + 1;
                else next_phase <= MAGENTA_BLUE; end if;
            when MAGENTA_BLUE =>
                if(r_count >   0) then r_count := r_count - 1;
                else next_phase <= BLUE_CYAN; end if;
            when BLUE_CYAN =>
                if(g_count < 255) then g_count := g_count + 1;
                else next_phase <= CYAN_GREEN; end if;
            when CYAN_GREEN =>
                if(b_count >   0) then b_count := b_count - 1;
                else next_phase <= GREEN_YELLOW; end if;
            when GREEN_YELLOW =>
                if(r_count < 255) then r_count := r_count + 1;
                else next_phase <= YELLOW_RED; end if;                
            when YELLOW_RED =>
                if(g_count >   0) then g_count := g_count - 1;
                else next_phase <= RED_MAGENTA; end if;
            end case;
            next_state <= GET_DATA;

        end case state;
        next_di <= std_logic_vector(to_unsigned(r_count, 8)) &
            std_logic_vector(to_unsigned(g_count, 8)) &
            std_logic_vector(to_unsigned(b_count, 8));
        next_rgb1 <= v_rgb1;
        next_rgb2 <= v_rgb2;
    end process;

end Behavioral;
