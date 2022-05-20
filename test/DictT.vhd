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
  use ieee.numeric_std.all;



library osvvm;
  use osvvm.RandomPkg.all;

library libvhdl;



entity DictT is
end entity DictT;



architecture sim of DictT is


  type t_scoreboard is array (natural range <>) of std_logic_vector(7 downto 0);

  function to_string(d : string) return string is
  begin
    return d;
  end function to_string;


  package StringSlvDict is new libvhdl.DictP
    generic map (KEY_TYPE         => string,
                 VALUE_TYPE       => std_logic_vector,
                 key_to_string    => to_string,
                 value_to_string  => to_hstring);

  use StringSlvDict.all;

  shared variable sv_dict : t_dict;
  shared variable sv_dact : t_dict;
  shared variable sv_duct : t_dict;


begin



  DictInitP : process is
  begin
    sv_dict.init(false);
    sv_dact.init(false);
    sv_duct.init(false);
    wait;
  end process DictInitP;


  DictTestP : process is
    variable v_key        : t_dict_key_ptr;
    variable v_last_key   : t_dict_key_ptr;
    variable v_random     : RandomPType;
    variable v_input      : std_logic_vector(7 downto 0);
    variable v_output     : std_logic_vector(7 downto 0);
    variable v_scoreboard : t_scoreboard(0 to 511);
  begin
    v_random.InitSeed(v_random'instance_name);

    -- check initial emptiness
    assert sv_dict.size = 0
      report "ERROR: Dict should be empty"
      severity failure;

    -- fill dictionary and check count
    report "INFO: Test 1: Fill dictionary";
    for i in 0 to 255 loop
      v_input := v_random.RandSlv(8);
      sv_dict.set(integer'image(i), v_input);
      v_scoreboard(i) := v_input;
      assert sv_dict.size = i+1
        report "ERROR: Dict should have " & to_string(i+1) & " entries"
        severity failure;
    end loop;
    report "INFO: Test successful";

    -- read all entries and check for correct data
    report "INFO: Test 2: Read dictionary";
    for i in 0 to 255 loop
      sv_dict.get(integer'image(i), v_output);
      assert v_output = v_scoreboard(i)
        report "ERROR: Got 0x" & to_hstring(v_output) & ", expected 0x" & to_hstring(v_scoreboard(i))
        severity failure;
    end loop;
    report "INFO: Test successful";

    -- overwrite a key/value pair
    report "INFO: Test 3: Overwrite a entry";
    v_input := v_random.RandSlv(8);
    sv_dict.set("128", v_input);
    v_scoreboard(128) := v_input;
    sv_dict.get("128", v_output);
    assert v_output = v_scoreboard(128)
      report "ERROR: Got 0x" & to_hstring(v_output) & ", expected 0x" & to_hstring(v_scoreboard(128))
      severity failure;
    report "INFO: Test successful";

    -- check for existing keys
    report "INFO: Test 4: Check hasKey() method";
    for i in 0 to 255 loop
      assert sv_dict.hasKey(integer'image(i))
        report "ERROR: Key" & integer'image(i) & " should exist in dictionary"
        severity failure;
    end loop;
    assert not(sv_dict.hasKey("AFFE"))
      report "ERROR: Key AFFE shouldn't exist in dictionary"
      severity failure;
    report "INFO: Test successful";

    -- iterate up over all entries
    report "INFO: Test 5: Iterate up over all entries";
    sv_dict.setIter;
    for i in 0 to 255 loop
      v_key := new string'(sv_dict.iter(UP));
      assert v_key.all = integer'image(i)
        report "ERROR: Got key " & v_key.all & ", expected " & integer'image(i)
        severity failure;
      sv_dict.get(v_key.all, v_output);
      assert v_key.all = integer'image(i) and v_output = v_scoreboard(i)
        report "ERROR: Got 0x" & to_hstring(v_output) & ", expected 0x" & to_hstring(v_scoreboard(i))
        severity failure;
    end loop;
    v_last_key := v_key;
    v_key := new string'(sv_dict.iter(UP));
    assert v_key.all = v_last_key.all
      report "ERROR: Got key " & v_key.all & ", expected key" & v_last_key.all
      severity failure;
    report "INFO: Test successful";

    -- iterate down over all entries
    report "INFO: Test 6: Iterate down over all entries";
    sv_dict.setIter(HEAD);
    for i in 255 downto 0 loop
      v_key := new string'(sv_dict.iter(DOWN));
      assert v_key.all = integer'image(i)
        report "ERROR: Got key " & v_key.all & ", expected " & integer'image(i)
        severity failure;
      sv_dict.get(v_key.all, v_output);
      assert v_key.all = integer'image(i) and v_output = v_scoreboard(i)
        report "ERROR: Got 0x" & to_hstring(v_output) & ", expected 0x" & to_hstring(v_scoreboard(i))
        severity failure;
    end loop;
    v_last_key := v_key;
    v_key := new string'(sv_dict.iter(DOWN));
    assert v_key.all = v_last_key.all
      report "ERROR: Got key " & v_key.all & ", expected key" & v_last_key.all
      severity failure;
    deallocate(v_key);
    report "INFO: Test successful";

    -- merge 2 dictionaries
    -- fill dictionary and check count
    report "INFO: Test 7: Merge dictionaries";
    for i in 256 to 511 loop
      v_input := v_random.RandSlv(8);
      sv_dact.set(integer'image(i), v_input);
      v_scoreboard(i) := v_input;
      assert sv_dact.size = i-255
        report "ERROR: Dict should have " & to_string(i-255) & " entries"
        severity failure;
    end loop;
    -- merge dictionaries
    merge(sv_dict, sv_dact, sv_duct);
    -- read all entries and check for correct data
    for i in 0 to 511 loop
      sv_duct.get(integer'image(i), v_output);
      assert v_output = v_scoreboard(i)
        report "ERROR: Got 0x" & to_hstring(v_output) & ", expected 0x" & to_hstring(v_scoreboard(i))
        severity failure;
    end loop;
    report "INFO: Test successful";

    -- Remove key/value pair from head of dictionary
    report "INFO: Test 8: Removing entry from head of dictionary";
    sv_dict.del("255");
    assert not(sv_dict.hasKey("255"))
      report "ERROR: Key 255 shouldn't exist in dictionary"
      severity failure;
    report "INFO: Test successful";

    -- Remove key/value pair from head of dictionary
    report "INFO: Test 9: Removing entry from middle of dictionary";
    sv_dict.del("127");
    assert not(sv_dict.hasKey("127"))
      report "ERROR: Key 127 shouldn't exist in dictionary"
      severity failure;
    report "INFO: Test successful";

    -- Remove key/value pair from head of dictionary
    report "INFO: Test 10: Removing entry from beginning of dictionary";
    sv_dict.del("0");
    assert not(sv_dict.hasKey("0"))
      report "ERROR: Key 0 shouldn't exist in dictionary"
      severity failure;
    report "INFO: Test successful";

    -- Remove key/value pair from head of dictionary
    report "INFO: Test 11: Clear all entries from dictionary";
    sv_dict.clear;
    assert sv_dict.size = 0
      report "ERROR: Dict should be empty"
      severity failure;
    report "INFO: Test successful";

    report "INFO: t_dict test finished successfully";
    wait;
  end process DictTestP;


end architecture sim;
