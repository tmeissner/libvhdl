library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library libvhdl;
  use libvhdl.StringP.all;
  use libvhdl.AssertP.all;



entity StringT is
end entity StringT;



architecture sim of StringT is


begin


  StringTestP : process is
    variable v_data         : std_logic_vector(31 downto 0) := x"DEADBEEF";
    variable v_data_reverse : std_logic_vector(0 to 31) := x"DEADBEEF";
  begin
    assert_equal(to_string(v_data(0)), "1");
    assert_equal(to_string(v_data), "11011110101011011011111011101111");
    assert_equal(to_string(v_data_reverse), "11011110101011011011111011101111");
    report "INFO: StringP tests finished successfully";
    wait;
  end process StringTestP;


end architecture sim;
