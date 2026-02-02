library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package matrix_pkg is
  constant FRAC_BITS : integer := 12;
  constant WORD_BITS : integer := 16;

  subtype q_t is signed(WORD_BITS-1 downto 0);

  type mat2_t is array (0 to 1, 0 to 1) of q_t;
  type mat4_t is array (0 to 3, 0 to 3) of q_t;

  function to_q(x : integer) return q_t;

  function add2(a, b : mat2_t) return mat2_t;
  function sub2(a, b : mat2_t) return mat2_t;
  function neg2(a : mat2_t) return mat2_t;
  function mul2(a, b : mat2_t) return mat2_t;
end package;

package body matrix_pkg is

  function to_q(x : integer) return q_t is
  begin
    return to_signed(x * (2 ** FRAC_BITS), WORD_BITS);
  end;

  function add2(a, b : mat2_t) return mat2_t is
    variable r : mat2_t;
  begin
    for i in 0 to 1 loop
      for j in 0 to 1 loop
        r(i,j) := a(i,j) + b(i,j);
      end loop;
    end loop;
    return r;
  end;

  function sub2(a, b : mat2_t) return mat2_t is
    variable r : mat2_t;
  begin
    for i in 0 to 1 loop
      for j in 0 to 1 loop
        r(i,j) := a(i,j) - b(i,j);
      end loop;
    end loop;
    return r;
  end;

  function neg2(a : mat2_t) return mat2_t is
    variable r : mat2_t;
  begin
    for i in 0 to 1 loop
      for j in 0 to 1 loop
        r(i,j) := -a(i,j);
      end loop;
    end loop;
    return r;
  end;


  function mul2(a, b : mat2_t) return mat2_t is
    variable r    : mat2_t;
    variable p    : signed(2*WORD_BITS-1 downto 0);     
    variable acc  : signed(2*WORD_BITS+1 downto 0);     
    variable accS : signed(2*WORD_BITS+1 downto 0);
  begin
    for i in 0 to 1 loop
      for j in 0 to 1 loop
        acc := (others => '0');

        for k in 0 to 1 loop

          p := a(i,k) * b(k,j);
          acc := acc + resize(p, acc'length);
        end loop;


        accS := shift_right(acc, FRAC_BITS);
        r(i,j) := resize(accS, WORD_BITS);
      end loop;
    end loop;

    return r;
  end;

end package body;