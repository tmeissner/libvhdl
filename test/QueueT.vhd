library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity QueueT is
end entity QueueT;



architecture sim of QueueT is


  shared variable sv_queue : work.QueueP.t_simple_queue;


begin


  QueueTestP : process is
    variable v_data  : std_logic_vector(63 downto 0);
    variable v_count : natural := 0;
  begin
    -- check initial emptiness
    assert sv_queue.is_empty
      report "ERROR: queue should be empty!"
      severity failure;
    for i in 0 to 63 loop
      sv_queue.push(std_logic_vector(to_unsigned(v_count, 64)));
      v_count := v_count + 1;
    end loop;
    -- check that it's full
    assert sv_queue.is_full
      report "ERROR: queue should be full!"
      severity failure;
    -- empty the queue
    v_count := 0;
    for i in 0 to 63 loop
      sv_queue.pop(v_data);
      assert v_data = std_logic_vector(to_unsigned(v_count, 64))
        report "ERROR: read data should be " & integer'image(v_count) &
               " instead of " & integer'image(to_integer(unsigned(v_data)))
        severity failure;
      v_count := v_count + 1;
    end loop;
    -- check emptiness
    assert sv_queue.is_empty
      report "ERROR: queue should be empty!"
      severity failure;
    report "INFO: Test finished successfully";
    wait;
  end process QueueTestP;


end architecture sim;