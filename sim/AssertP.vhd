--  Copyright (c) 2014 - 2022 by Torsten Meissner
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.



library ieee;
  use ieee.std_logic_1164.all;

--+ including vhdl 2008 libraries
--+ These lines can be commented out when using
--+ a simulator with built-in VHDL 2008 support
--library ieee_proposed;
--  use ieee_proposed.standard_additions.all;
--  use ieee_proposed.std_logic_1164_additions.all;



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
        report to_string(a) & " should be equal to " & integer'image(b)
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
        report "FAILURE: 0x" & to_hstring(a) & " should be equal to 0x" & to_hstring(b)
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
        report to_string(a) & " should not be equal to " & integer'image(b)
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
        report "FAILURE: " & to_hstring(a) & " should not be equal to " & to_hstring(b)
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
