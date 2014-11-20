library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.QueueP.all;



entity QueueT is
end entity QueueT;



architecture sim of QueueT is


  shared variable sv_simple_queue : t_simple_queue;
  shared variable sv_list_queue   : t_list_queue;


begin


  SimpleQueueTestP : process is
    variable v_data  : std_logic_vector(63 downto 0);
  begin
    -- check initial emptiness
    assert_true(sv_simple_queue.is_empty, "Queue should be empty!");
    for i in 0 to 63 loop
      sv_simple_queue.push(std_logic_vector(to_unsigned(i, 64)));
    end loop;
    -- check that it's full
    assert_true(sv_simple_queue.is_full, "Queue should be full!");
    -- empty the queue
    for i in 0 to 63 loop
      sv_simple_queue.pop(v_data);
      assert_equal(v_data, std_logic_vector(to_unsigned(i, 64)));
    end loop;
    -- check emptiness
    assert_true(sv_simple_queue.is_empty, "Queue should be empty!");
    report "INFO: t_simple_queue test finished successfully";
    wait;
  end process SimpleQueueTestP;


  ListQueueTestP : process is
    variable v_data  : std_logic_vector(7 downto 0);
  begin
    -- check initial emptiness
    assert_true(sv_list_queue.is_empty, "Queue should be empty!");
    for i in 0 to 63 loop
      sv_list_queue.push(std_logic_vector(to_unsigned(i, 8)));
    end loop;
    -- check that it's full
    assert_true(sv_list_queue.is_full, "Queue should be full!");
    -- empty the queue
    for i in 0 to 63 loop
      sv_list_queue.pop(v_data);
      assert_equal(v_data, std_logic_vector(to_unsigned(i, 8)));
    end loop;
    -- check emptiness
    assert_true(sv_list_queue.is_empty, "Queue should be empty!");
    report "INFO: t_list_queue test finished successfully";
    wait;
  end process ListQueueTestP;


end architecture sim;
