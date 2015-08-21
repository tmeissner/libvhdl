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
  use libvhdl.DictP.all;



entity DictT is
end entity DictT;



architecture sim of DictT is


  type t_scoreboard is array (natural range <>) of std_logic_vector(7 downto 0);

  shared variable sv_dict : t_dict;


begin


  DictInitP : process is
  begin
    sv_dict.init(false);
    wait;
  end process DictInitP;


  DictTestP : process is
    variable v_key    : string(1 to 4);
    variable v_random : RandomPType;
    variable v_input  : std_logic_vector(7 downto 0);
    variable v_output : std_logic_vector(7 downto 0);
    variable v_scoreboard : t_scoreboard(0 to 256);
  begin
    v_random.InitSeed(v_random'instance_name);

    -- check initial emptiness
    assert sv_dict.size = 0
      report "ERROR: Dict should be empty"
      severity failure;

    -- fill dictionary and check count
    report "INFO: Test : Fill dictionary";
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
    report "INFO: Test : Read dictionary";
    for i in 0 to 255 loop
      sv_dict.get(integer'image(i), v_output);
      assert v_output = v_scoreboard(i)
        report "ERROR: Got 0x" & to_hstring(v_output) & ", expected 0x" & to_hstring(v_scoreboard(i))
        severity failure;
    end loop;
    report "INFO: Test successful";

    report "INFO: t_dict test finished successfully";
    wait;
  end process DictTestP;


end architecture sim;
