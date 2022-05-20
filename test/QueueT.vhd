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

library libvhdl;
  use libvhdl.AssertP.all;

library osvvm;
  use osvvm.RandomPkg.all;



entity QueueT is
end entity QueueT;



architecture sim of QueueT is


  constant C_QUEUE_DEPTH : natural := 64;

  package SlvQueue is new libvhdl.QueueP
    generic map (
      QUEUE_TYPE => std_logic_vector(63 downto 0),
      MAX_LEN    => C_QUEUE_DEPTH,
      to_string  => to_hstring
    );

  shared variable sv_simple_queue : SlvQueue.t_simple_queue;
  shared variable sv_list_queue   : SlvQueue.t_list_queue;


begin


  QueueInitP : process is
  begin
    sv_simple_queue.init(false);
    sv_list_queue.init(false);
    wait;
  end process QueueInitP;



  SimpleQueueTestP : process is
    variable v_data   : std_logic_vector(63 downto 0);
    variable v_random : RandomPType;
  begin
    -- check initial emptiness
    assert_true(sv_simple_queue.is_empty, "Queue should be empty!");
    -- Fill queue
    v_random.InitSeed(v_random'instance_name);
    for i in 0 to C_QUEUE_DEPTH-1 loop
      v_data := v_random.RandSlv(64);
      sv_simple_queue.push(v_data);
    end loop;
    -- check that it's full
    assert_true(sv_simple_queue.is_full, "Queue should be full!");
    -- Check number of entries
    assert_equal(sv_simple_queue.fillstate, C_QUEUE_DEPTH, "Queue should have" & integer'image(C_QUEUE_DEPTH) & "entries");
    -- empty the queue
    v_random.InitSeed(v_random'instance_name);
    for i in 0 to C_QUEUE_DEPTH-1 loop
      sv_simple_queue.pop(v_data);
      assert_equal(v_data, v_random.RandSlv(64));
    end loop;
    -- check emptiness
    assert_true(sv_simple_queue.is_empty, "Queue should be empty!");
    report "INFO: t_simple_queue test finished successfully";
    wait;
  end process SimpleQueueTestP;


  ListQueueTestP : process is
    variable v_data   : std_logic_vector(63 downto 0);
    variable v_random : RandomPType;
  begin
    -- check initial emptiness
    assert_true(sv_list_queue.is_empty, "Queue should be empty!");
    -- Fill queue
    v_random.InitSeed(v_random'instance_name);
    for i in 0 to C_QUEUE_DEPTH-1 loop
      v_data := v_random.RandSlv(64);
      sv_list_queue.push(v_data);
    end loop;
    -- check that it's full
    assert_true(sv_list_queue.is_full, "Queue should be full!");
    -- Check number of entries
    assert_equal(sv_list_queue.fillstate, C_QUEUE_DEPTH, "Queue should have" & integer'image(C_QUEUE_DEPTH) & "entries");
    -- empty the queue
    v_random.InitSeed(v_random'instance_name);
    for i in 0 to C_QUEUE_DEPTH-1 loop
      sv_list_queue.pop(v_data);
      assert_equal(v_data, v_random.RandSlv(64));
    end loop;
    -- check emptiness
    assert_true(sv_list_queue.is_empty, "Queue should be empty!");
    report "INFO: t_list_queue test finished successfully";
    wait;
  end process ListQueueTestP;


end architecture sim;
