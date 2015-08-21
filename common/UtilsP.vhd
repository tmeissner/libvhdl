library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



package UtilsP is


  function and_reduce (data : in std_logic_vector) return std_logic;
  function and_reduce (data : in boolean_vector) return boolean;

  function or_reduce (data : in std_logic_vector) return std_logic;
  function or_reduce (data : in boolean_vector) return boolean;

  function even_parity (data : in std_logic_vector) return std_logic;
  function odd_parity (data : in std_logic_vector) return std_logic;


end package UtilsP;



package body UtilsP is


  function and_reduce (data : in std_logic_vector) return std_logic is
  begin
    for i in data'range loop
      if data(i) = '0' then
        return '0';
      end if;
    end loop;
    return '1';
  end function and_reduce;

  function and_reduce (data : in boolean_vector) return boolean is
  begin
    for i in data'range loop
      if (not(data(i))) then
        return false;
      end if;
    end loop;
    return true;
  end function and_reduce;


  function or_reduce (data : in std_logic_vector) return std_logic is
  begin
    for i in data'range loop
      if data(i) = '1' then
        return '1';
      end if;
    end loop;
    return '0';
  end function or_reduce;

  function or_reduce (data : in boolean_vector) return boolean is
  begin
    for i in data'range loop
      if data(i) then
        return true;
      end if;
    end loop;
    return false;
  end function or_reduce;


  function even_parity (data : in std_logic_vector) return std_logic is
    variable v_return : std_logic := '0';
  begin
    for i in data'range loop
      v_return := v_return xor data(i);
    end loop;
    return v_return;
  end function even_parity;

  function odd_parity (data : in std_logic_vector) return std_logic is
    variable v_return : std_logic := '1';
  begin
    for i in data'range loop
      v_return := v_return xor data(i);
    end loop;
    return v_return;
  end function odd_parity;


end package body UtilsP;
