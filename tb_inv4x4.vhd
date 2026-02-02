library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.matrix_pkg.all;

entity tb_inv4x4 is
end entity;

architecture sim of tb_inv4x4 is
  signal clk, rst, start, done : std_logic := '0';
  signal A   : mat4_t;
  signal INV : mat4_t;

  component inv4x4_block is
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      start : in  std_logic;
      a_in  : in  mat4_t;
      done  : out std_logic;
      inv_o : out mat4_t
    );
  end component;

  
  function mat4_mul(a, b : mat4_t) return mat4_t is
    variable r    : mat4_t;
    variable acc  : signed(2*WORD_BITS+4 downto 0);
    variable p32  : signed(2*WORD_BITS-1 downto 0);
    variable accS : signed(2*WORD_BITS+4 downto 0);
  begin
    for i in 0 to 3 loop
      for j in 0 to 3 loop
        acc := (others => '0');
        for k in 0 to 3 loop
          p32 := a(i,k) * b(k,j);                   
          acc := acc + resize(p32, acc'length);
        end loop;
        accS := shift_right(acc, FRAC_BITS);         
        r(i,j) := resize(accS, WORD_BITS);
      end loop;
    end loop;
    return r;
  end function;

  function q_abs(x : q_t) return q_t is
  begin
    if x(WORD_BITS-1) = '1' then
      return -x;
    else
      return x;
    end if;
  end function;

  function q_one return q_t is
  begin
    return to_signed(1 * (2 ** FRAC_BITS), WORD_BITS);
  end function;

  function q_zero return q_t is
  begin
    return (others => '0');
  end function;

  
  function q_to_int(x : q_t) return integer is
  begin
    return to_integer(x);
  end function;

begin
  DUT: inv4x4_block
    port map(
      clk   => clk,
      rst   => rst,
      start => start,
      a_in  => A,
      done  => done,
      inv_o => INV
    );

  clk <= not clk after 5 ns;

  process
    variable P   : mat4_t;
    variable tol : q_t;
  begin

    -- RESET

    rst <= '1'; wait for 20 ns; rst <= '0';
    wait for 10 ns;

    ------------------------------------------------------------------
    -- TEST 1
    ------------------------------------------------------------------
    
    for i in 0 to 3 loop
      for j in 0 to 3 loop
        if i = j then
          A(i,j) <= to_q(1);
        else
          A(i,j) <= to_q(0);
        end if;
      end loop;
    end loop;

    wait for 20 ns;
    start <= '1'; wait for 10 ns; start <= '0';
    wait until done='1';
    wait for 20 ns;

    P := mat4_mul(A, INV);

    
    tol := to_signed(1, WORD_BITS);

    for i in 0 to 3 loop
      for j in 0 to 3 loop
        if i=j then
          assert q_abs(P(i,j) - q_one) <= tol
            report "TEST1 FAIL diag (" & integer'image(i) & "," & integer'image(j) & ")"
            severity error;
        else
          assert q_abs(P(i,j) - q_zero) <= tol
            report "TEST1 FAIL offdiag (" & integer'image(i) & "," & integer'image(j) & ")"
            severity error;
        end if;
      end loop;
    end loop;

    report "TEST1 PASS: Identity inversion OK" severity note;

    ------------------------------------------------------------------
    -- TEST 2
    ------------------------------------------------------------------

    A(0,0) <= to_q(4); A(0,1) <= to_q(1); A(0,2) <= to_q(0); A(0,3) <= to_q(0);
    A(1,0) <= to_q(2); A(1,1) <= to_q(3); A(1,2) <= to_q(1); A(1,3) <= to_q(0);
    A(2,0) <= to_q(0); A(2,1) <= to_q(1); A(2,2) <= to_q(3); A(2,3) <= to_q(1);
    A(3,0) <= to_q(0); A(3,1) <= to_q(0); A(3,2) <= to_q(2); A(3,3) <= to_q(4);

    wait for 20 ns;
    start <= '1'; wait for 10 ns; start <= '0';
    wait until done='1';
    wait for 20 ns;

    P := mat4_mul(A, INV);


    report "TEST2 diag P(0,0) scaled=" & integer'image(q_to_int(P(0,0))) severity note;
    report "TEST2 diag P(1,1) scaled=" & integer'image(q_to_int(P(1,1))) severity note;
    report "TEST2 diag P(2,2) scaled=" & integer'image(q_to_int(P(2,2))) severity note;
    report "TEST2 diag P(3,3) report scaled=" & integer'image(q_to_int(P(3,3))) severity note;

    report "DONE" severity failure;
  end process;

end architecture;