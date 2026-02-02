library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.matrix_pkg.all;

entity inv4x4_block is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    start : in  std_logic;
    a_in  : in  mat4_t;
    done  : out std_logic;
    inv_o : out mat4_t
  );
end entity;

architecture rtl of inv4x4_block is
  type state_t is (
    IDLE,
    LOAD_BLOCKS,
    START_INV_A11,
    WAIT_INV_A11,
    COMPUTE_S,
    START_INV_S,
    WAIT_INV_S,
    ASSEMBLE,
    DONE_ST
  );
  signal st : state_t := IDLE;

  signal A11, A12, A21, A22 : mat2_t;
  signal X, Y               : mat2_t;
  signal T, U               : mat2_t;
  signal S                  : mat2_t;

  signal inv2_start : std_logic := '0';
  signal inv2_done  : std_logic;
  signal inv2_in    : mat2_t;
  signal inv2_out   : mat2_t;

  component inv2x2 is
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      start : in  std_logic;
      m_in  : in  mat2_t;
      done  : out std_logic;
      m_inv : out mat2_t
    );
  end component;

begin

  U_INV2: inv2x2
    port map (
      clk   => clk,
      rst   => rst,
      start => inv2_start,
      m_in  => inv2_in,
      done  => inv2_done,
      m_inv => inv2_out
    );

  process(clk)
    variable tmp2 : mat2_t;
    variable B11, B12, B21, B22 : mat2_t;
  begin
    if rising_edge(clk) then
      if rst='1' then
        st         <= IDLE;
        done       <= '0';
        inv2_start <= '0';

        for i in 0 to 3 loop
          for j in 0 to 3 loop
            inv_o(i,j) <= (others => '0');
          end loop;
        end loop;

      else
        done       <= '0';
        inv2_start <= '0'; 

        case st is

          when IDLE =>
            if start='1' then
              st <= LOAD_BLOCKS;
            end if;

          when LOAD_BLOCKS =>

            A11(0,0) <= a_in(0,0); A11(0,1) <= a_in(0,1);
            A11(1,0) <= a_in(1,0); A11(1,1) <= a_in(1,1);

            A12(0,0) <= a_in(0,2); A12(0,1) <= a_in(0,3);
            A12(1,0) <= a_in(1,2); A12(1,1) <= a_in(1,3);

            A21(0,0) <= a_in(2,0); A21(0,1) <= a_in(2,1);
            A21(1,0) <= a_in(3,0); A21(1,1) <= a_in(3,1);

            A22(0,0) <= a_in(2,2); A22(0,1) <= a_in(2,3);
            A22(1,0) <= a_in(3,2); A22(1,1) <= a_in(3,3);

            st <= START_INV_A11;

          when START_INV_A11 =>
            inv2_in    <= A11;
            inv2_start <= '1';
            st <= WAIT_INV_A11;

          when WAIT_INV_A11 =>
            if inv2_done='1' then
              X <= inv2_out;
              st <= COMPUTE_S;
            end if;

          when COMPUTE_S =>

            T <= mul2(A21, X);
            U <= mul2(X, A12);


            tmp2 := mul2(mul2(A21, X), A12);

            S <= sub2(A22, tmp2);

            st <= START_INV_S;

          when START_INV_S =>
            inv2_in    <= S;
            inv2_start <= '1';
            st <= WAIT_INV_S;

          when WAIT_INV_S =>
            if inv2_done='1' then
              Y <= inv2_out;
              st <= ASSEMBLE;
            end if;

          when ASSEMBLE =>
           
            B11 := add2(X, mul2(mul2(U, Y), T));
            
            B12 := neg2(mul2(U, Y));
            
            B21 := neg2(mul2(Y, T));
            
            B22 := Y;

            
            inv_o(0,0) <= B11(0,0); inv_o(0,1) <= B11(0,1);
            inv_o(1,0) <= B11(1,0); inv_o(1,1) <= B11(1,1);

            inv_o(0,2) <= B12(0,0); inv_o(0,3) <= B12(0,1);
            inv_o(1,2) <= B12(1,0); inv_o(1,3) <= B12(1,1);

            inv_o(2,0) <= B21(0,0); inv_o(2,1) <= B21(0,1);
            inv_o(3,0) <= B21(1,0); inv_o(3,1) <= B21(1,1);

            inv_o(2,2) <= B22(0,0); inv_o(2,3) <= B22(0,1);
            inv_o(3,2) <= B22(1,0); inv_o(3,3) <= B22(1,1);

            st <= DONE_ST;

          when DONE_ST =>
            done <= '1';
            st <= IDLE;

        end case;
      end if;
    end if;
  end process;

end architecture;