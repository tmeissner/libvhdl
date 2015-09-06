library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--+ including vhdl 2008 libraries
--+ These lines can be commented out when using
--+ a simulator with built-in VHDL 2008 support
--library ieee_proposed;
--  use ieee_proposed.standard_additions.all;
--  use ieee_proposed.std_logic_1164_additions.all;
--  use ieee_proposed.numeric_std_additions.all;

library osvvm;
  use osvvm.RandomPkg.all;

library libvhdl;
  use libvhdl.AssertP.all;
  use libvhdl.StackP.all;



entity StackT is
end entity StackT;



architecture sim of StackT is


  constant C_STACK_DEPTH : natural := 64;

  type t_scoreboard is array (natural range <>) of std_logic_vector(7 downto 0);

  shared variable sv_stack : t_stack;


begin


  StackInitP : process is
  begin
    sv_stack.init(false);
    wait;
  end process StackInitP;


  StackTestP : process is
    variable v_data : std_logic_vector(7 downto 0);
  begin
    -- check initial emptiness
    assert_true(sv_stack.is_empty, "Stack should be empty!");
    for i in 0 to C_STACK_DEPTH-1 loop
      sv_stack.push(std_logic_vector(to_unsigned(i, 8)));
    end loop;
    -- check that it's full
    assert_equal(sv_stack.fillstate, C_STACK_DEPTH, "Stack should have" & integer'image(C_STACK_DEPTH) & "entries");
    -- empty the queue
    for i in C_STACK_DEPTH-1 downto 0 loop
      sv_stack.pop(v_data);
      assert_equal(v_data, std_logic_vector(to_unsigned(i, 8)));
    end loop;
    -- check emptiness
    assert_true(sv_stack.is_empty, "Stack should be empty!");
    report "INFO: t_stack test finished successfully";
    wait;
  end process StackTestP;


end architecture sim;