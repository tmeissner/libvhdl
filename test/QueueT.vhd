library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity QueueT is
end entity QueueT;



architecture sim of QueueT is


  shared variable sv_simple_queue : work.QueueP.t_simple_queue;
  shared variable sv_list_queue   : work.QueueP.t_list_queue;


begin


  SimpleQueueTestP : process is
    variable v_data  : std_logic_vector(63 downto 0);
  begin
    -- check initial emptiness
    assert sv_simple_queue.is_empty
      report "ERROR: queue should be empty!"
      severity failure;
    for i in 0 to 63 loop
      sv_simple_queue.push(std_logic_vector(to_unsigned(i, 64)));
    end loop;
    -- check that it's full
    assert sv_simple_queue.is_full
      report "ERROR: queue should be full!"
      severity failure;
    -- empty the queue
    for i in 0 to 63 loop
      sv_simple_queue.pop(v_data);
      assert v_data = std_logic_vector(to_unsigned(i, 64))
        report "ERROR: read data should be " & integer'image(i) &
               " instead of " & integer'image(to_integer(unsigned(v_data)))
        severity failure;
    end loop;
    -- check emptiness
    assert sv_simple_queue.is_empty
      report "ERROR: queue should be empty!"
      severity failure;
    report "INFO: t_simple_queue test finished successfully";
    wait;
  end process SimpleQueueTestP;


  ListQueueTestP : process is
    variable v_data  : std_logic_vector(63 downto 0);
  begin
    -- check initial emptiness
    assert sv_list_queue.is_empty
      report "ERROR: queue should be empty!"
      severity failure;
    for i in 0 to 63 loop
      sv_list_queue.push(std_logic_vector(to_unsigned(i, 64)));
    end loop;
    -- check that it's full
    assert sv_list_queue.is_full
      report "ERROR: queue should be full!"
      severity failure;
    -- empty the queue
    for i in 0 to 63 loop
      sv_list_queue.pop(v_data);
      assert v_data = std_logic_vector(to_unsigned(i, 64))
        report "ERROR: read data should be " & integer'image(i) &
               " instead of " & integer'image(to_integer(unsigned(v_data)))
        severity failure;
    end loop;
    -- check emptiness
    assert sv_list_queue.is_empty
      report "ERROR: queue should be empty!"
      severity failure;
    report "INFO: t_list_queue test finished successfully";
    wait;
  end process ListQueueTestP;


end architecture sim;