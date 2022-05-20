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
  use libvhdl.AssertP.all;



entity StackT is
end entity StackT;



architecture sim of StackT is


  constant C_STACK_DEPTH : natural := 64;

  package SlvStack is new libvhdl.StackP
    generic map (
      STACK_TYPE => std_logic_vector(63 downto 0),
      MAX_LEN    => C_STACK_DEPTH,
      to_string  => to_hstring
    );

  shared variable sv_stack : SlvStack.t_stack;


begin


  StackInitP : process is
  begin
    sv_stack.init(false);
    wait;
  end process StackInitP;


  StackTestP : process is
    variable v_data : std_logic_vector(63 downto 0);
    variable v_random : RandomPType;
    type t_scoreboard is array (natural range <>) of std_logic_vector(63 downto 0);
    variable v_scoreboard : t_scoreboard(0 to C_STACK_DEPTH-1);
  begin
    -- Check initial emptiness
    assert_true(sv_stack.is_empty, "Stack should be empty!");
    -- Fill stack
    v_random.InitSeed(v_random'instance_name);
    for i in 0 to C_STACK_DEPTH-1 loop
      v_data := v_random.RandSlv(64);
      v_scoreboard(i) := v_data;
      sv_stack.push(v_data);
    end loop;
    -- Check that it's full
    assert_true(sv_stack.is_full, "Stack should be full!");
    -- Check number of entries
    assert_equal(sv_stack.fillstate, C_STACK_DEPTH, "Stack should have" & integer'image(C_STACK_DEPTH) & "entries");
    -- Empty the stack
    for i in C_STACK_DEPTH-1 downto 0 loop
      sv_stack.pop(v_data);
      assert_equal(v_data, v_scoreboard(i));
    end loop;
    -- Check emptiness
    assert_true(sv_stack.is_empty, "Stack should be empty!");
    report "INFO: t_stack test finished successfully";
    wait;
  end process StackTestP;


end architecture sim;