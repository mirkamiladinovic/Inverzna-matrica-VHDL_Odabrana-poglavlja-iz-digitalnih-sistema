library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.matrix_pkg.all;

entity inv2x2 is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    start : in  std_logic;
    m_in  : in  mat2_t;
    done  : out std_logic;
    m_inv : out mat2_t
  );
end entity;

architecture rtl of inv2x2 is
  type state_t is (IDLE, CALC_DET, INIT_RECIP, NR1, NR2, OUTPUT);
  signal st : state_t := IDLE;

  signal a, b, c, d : q_t;
  signal det        : q_t;

  signal x0, x1, x2 : q_t;

  
  function q_mul(x, y : q_t) return q_t is
    variable prod  : signed(2*WORD_BITS-1 downto 0);  -- 32
    variable prodS : signed(2*WORD_BITS-1 downto 0);
  begin
    prod  := x * y;                                  -- 16x16 -> 32
    prodS := shift_right(prod, FRAC_BITS);          
    return resize(prodS, WORD_BITS);
  end function;

  function q_two return q_t is
  begin
    return to_signed(2 * (2 ** FRAC_BITS), WORD_BITS);
  end function;

  function q_one return q_t is
  begin
    return to_signed(1 * (2 ** FRAC_BITS), WORD_BITS);
  end function;

begin
  process(clk)
    variable t1, t2 : q_t;
    variable detx   : q_t;
    variable inner  : q_t;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        st   <= IDLE;
        done <= '0';
        m_inv(0,0) <= (others => '0');
        m_inv(0,1) <= (others => '0');
        m_inv(1,0) <= (others => '0');
        m_inv(1,1) <= (others => '0');
      else
        done <= '0';

        case st is
          when IDLE =>
            if start = '1' then
              a <= m_in(0,0);
              b <= m_in(0,1);
              c <= m_in(1,0);
              d <= m_in(1,1);
              st <= CALC_DET;
            end if;

          when CALC_DET =>
            t1  := q_mul(a, d);
            t2  := q_mul(b, c);
            det <= t1 - t2;
            st  <= INIT_RECIP;

          when INIT_RECIP =>
            x0 <= q_one; 
            st <= NR1;

          when NR1 =>
            detx  := q_mul(det, x0);
            inner := q_two - detx;
            x1    <= q_mul(x0, inner);
            st    <= NR2;

          when NR2 =>
            detx  := q_mul(det, x1);
            inner := q_two - detx;
            x2    <= q_mul(x1, inner);
            st    <= OUTPUT;

          when OUTPUT =>
            m_inv(0,0) <= q_mul(d,  x2);
            m_inv(0,1) <= q_mul(-b, x2);
            m_inv(1,0) <= q_mul(-c, x2);
            m_inv(1,1) <= q_mul(a,  x2);

            done <= '1';
            st   <= IDLE;
        end case;
      end if;
    end if;
  end process;
end architecture;