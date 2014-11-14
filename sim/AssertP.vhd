library ieee;
  use ieee.std_logic_1164.all;

use work.StringP.all;



package AssertP is


  procedure assert_equal   (a : in integer; b : in integer);
  procedure assert_equal   (a : in std_logic_vector; b : in std_logic_vector);
  procedure assert_equal   (a : in string; b : in string);

  procedure assert_unequal (a : in integer; b : in integer);
  procedure assert_unequal (a : in std_logic_vector; b : in std_logic_vector);


end package AssertP;



package body AssertP is


  procedure assert_equal (a : in integer; b : in integer) is
  begin
    assert a = b
      report "FAILURE: " & integer'image(a) & " should be equal to " & integer'image(b)
      severity failure;
  end procedure assert_equal;

  procedure assert_equal (a : in std_logic_vector; b : in std_logic_vector) is
  begin
    assert a = b
      report "FAILURE: " & to_string(a) & " should be equal to " & to_string(b)
      severity failure;
  end procedure assert_equal;

   procedure assert_equal (a : in string; b : in string) is
   begin
    assert a = b
      report "FAILURE: " & a & " should be equal to " & b
      severity failure;
  end procedure assert_equal;

  procedure assert_unequal (a : in integer; b : in integer) is
  begin
    assert a /= b
      report "FAILURE: " & integer'image(a) & " should be unequal to " & integer'image(b)
      severity failure;
  end procedure assert_unequal;

  procedure assert_unequal (a : in std_logic_vector; b : in std_logic_vector) is
  begin
    assert a /= b
      report "FAILURE: " & to_string(a) & " should be unequal to " & to_string(b)
      severity failure;
  end procedure assert_unequal;


end package body AssertP;