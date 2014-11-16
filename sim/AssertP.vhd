library ieee;
  use ieee.std_logic_1164.all;

library libvhdl;
  use libvhdl.StringP.all;



package AssertP is


  procedure assert_true (    a : in boolean;
                           str : in string := "a should be evaluate to true";
                         level : in severity_level := failure);

  procedure assert_false (    a : in boolean;
                            str : in string := "a should be evaluate to false";
                          level : in severity_level := failure);

  procedure assert_equal (a, b  : in integer;
                          str   : in string := "";
                          level : in severity_level := failure);

  procedure assert_equal ( a, b : in std_logic_vector;
                            str : in string := "";
                          level : in severity_level := failure);


  procedure assert_equal ( a, b : in string;
                            str : in string := "";
                          level : in severity_level := failure);

  procedure assert_unequal (a, b  : in integer;
                            str   : in string := "";
                            level : in severity_level := failure);

  procedure assert_unequal ( a, b : in std_logic_vector;
                              str : in string := "";
                            level : in severity_level := failure);


  procedure assert_unequal ( a, b : in string;
                              str : in string := "";
                            level : in severity_level := failure);


end package AssertP;



package body AssertP is


  procedure assert_true (    a : in boolean;
                           str : in string := "a should be evaluate to true";
                         level : in severity_level := failure) is
  begin
    assert a
      report str
      severity level;
  end procedure assert_true;


  procedure assert_false (   a : in boolean;
                           str : in string := "a should be evaluate to false";
                         level : in severity_level := failure) is
  begin
    assert not(a)
      report str
      severity level;
  end procedure assert_false;


  procedure assert_equal ( a, b : in integer;
                            str : in string := "";
                          level : in severity_level := failure) is
  begin
    if (str'length = 0) then
      assert a = b
        report integer'image(a) & " should be equal to " & integer'image(b)
        severity level;
    else
      assert a = b
        report str
        severity level;
    end if;
  end procedure assert_equal;


  procedure assert_equal ( a, b : in std_logic_vector;
                            str : in string := "";
                          level : in severity_level := failure) is
  begin
    if (str'length = 0) then
      assert a = b
        report "FAILURE: " & to_string(a) & " should be equal to " & to_string(b)
        severity level;
    else
      assert a = b
        report str
        severity level;
    end if;
  end procedure assert_equal;


  procedure assert_equal (  a,b : in string;
                            str : in string := "";
                          level : in severity_level := failure) is
  begin
    if (str'length = 0) then
      assert a = b
        report "FAILURE: " & a & " should be equal to " & b
        severity level;
    else
      assert a = b
        report str
        severity level;
    end if;
  end procedure assert_equal;


  procedure assert_unequal ( a, b : in integer;
                              str : in string := "";
                            level : in severity_level := failure) is
  begin
    if (str'length = 0) then
      assert a /= b
        report integer'image(a) & " should not be equal to " & integer'image(b)
        severity level;
    else
      assert a /= b
        report str
        severity level;
    end if;
  end procedure assert_unequal;


  procedure assert_unequal ( a, b : in std_logic_vector;
                              str : in string := "";
                            level : in severity_level := failure) is
  begin
    if (str'length = 0) then
      assert a /= b
        report "FAILURE: " & to_string(a) & " should not be equal to " & to_string(b)
        severity level;
    else
      assert a /= b
        report str
        severity level;
    end if;
  end procedure assert_unequal;


  procedure assert_unequal (  a,b : in string;
                              str : in string := "";
                            level : in severity_level := failure) is
  begin
    if (str'length = 0) then
      assert a /= b
        report "FAILURE: " & a & " should not be equal to " & b
        severity level;
    else
      assert a /= b
        report str
        severity level;
    end if;
  end procedure assert_unequal;


end package body AssertP;
