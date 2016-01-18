library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



package UtilsP is


  function and_reduce (data : in std_logic_vector) return std_logic;
  function and_reduce (data : in boolean_vector) return boolean;

  function or_reduce (data : in std_logic_vector) return std_logic;
  function or_reduce (data : in boolean_vector) return boolean;

  function xor_reduce (data : in std_logic_vector) return std_logic;

  function even_parity (data : in std_logic_vector) return std_logic;
  function odd_parity (data : in std_logic_vector) return std_logic;

  function count_ones (data : in std_logic_vector) return natural;

  function one_hot (data : in std_logic_vector) return boolean;

  function is_unknown (data : in std_logic_vector) return boolean;

  function uint_to_slv (data: in natural; len : in positive) return std_logic_vector;
  function slv_to_uint (data: in std_logic_vector) return natural;

  function uint_bitsize(data : in natural) return natural;


end package UtilsP;



package body UtilsP is


  function and_reduce (data : in std_logic_vector) return std_logic is
    variable v_return : std_logic := '1';
  begin
    for i in data'range loop
      v_return := v_return and data(i);
    end loop;
    return v_return;
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
     variable v_return : std_logic := '0';
  begin
    for i in data'range loop
      v_return := v_return or data(i);
    end loop;
    return v_return;
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


  function xor_reduce (data : in std_logic_vector) return std_logic is
    variable v_return : std_logic := '0';
  begin
     for i in data'range loop
      v_return := v_return xor data(i);
    end loop;
    return v_return;
  end function xor_reduce;


  function even_parity (data : in std_logic_vector) return std_logic is
  begin
    return xor_reduce(data);
  end function even_parity;

  function odd_parity (data : in std_logic_vector) return std_logic is
  begin
    return not(xor_reduce(data));
  end function odd_parity;


  function count_ones (data : in std_logic_vector) return natural is
    variable v_return : natural := 0;
  begin
    for i in data'range loop
      if (to_ux01(data(i)) = '1') then
        v_return := v_return + 1;
      end if;
    end loop;
    return v_return;
  end function count_ones;


  function one_hot (data : in std_logic_vector) return boolean is
  begin
    return count_ones(data) = 1;
  end function one_hot;


  function is_unknown (data : in std_logic_vector) return boolean is
  begin
    for i in data'range loop
      if (to_ux01(data(i)) = 'U') then
        return true;
      end if;
    end loop;
  end function is_unknown;


  function uint_to_slv (data: in natural; len : in positive) return std_logic_vector is
  begin
    assert len >= uint_bitsize(data)
      report "Warning: std_logic_vector result truncated"
      severity warning;
    return std_logic_vector(to_unsigned(data, len));
  end function uint_to_slv;

  function slv_to_uint (data: in std_logic_vector) return natural is
  begin
    if data'ascending then
      assert data'length <= 31 or or_reduce(data(data'left to data'right-31)) = '0'
        report "WARNING: integer result overflow"
        severity warning;
    else
      assert data'length <= 31 or or_reduce(data(data'left downto data'right+31)) = '0'
        report "WARNING: integer result overflow"
        severity warning;
    end if;
    return to_integer(unsigned(data));
  end function slv_to_uint;


  function uint_bitsize(data : in natural) return natural is
    variable v_nlz  : natural               := 0;
    variable v_data : unsigned(30 downto 0) := to_unsigned(data, 31);
  begin
    if (data = 0) then
      return 1;
    end if;
    for i in 30 downto 0 loop
      if(v_data(i) /= '0') then
        exit;
      else
        v_nlz := v_nlz + 1;
      end if;
    end loop;
    return 31 - v_nlz;
  end function uint_bitsize;


end package body UtilsP;
