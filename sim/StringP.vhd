library ieee;
  use ieee.std_logic_1164.all;


package StringP is


  function to_char    (data : in std_logic) return character;
  function to_char    (data : in std_logic_vector(3 downto 0)) return character;
  function to_string  (data : in std_logic) return string;
  function to_string  (data : in std_logic_vector) return string;


end package StringP;


package body StringP is


  function to_char (data : in std_logic) return character is
  begin
    case data is
      when 'U' => return 'U';
      when 'X' => return 'X';
      when '0' => return '0';
      when '1' => return '1';
      when 'Z' => return 'Z';
      when 'W' => return 'W';
      when 'L' => return 'L';
      when 'H' => return 'H';
      when '-' => return '-';
    end case;
  end to_char;

  function to_char (data : in std_logic_vector(3 downto 0)) return character is
  begin
    case data is
      when x"0" => return '0';
      when x"1" => return '1';
      when x"2" => return '2';
      when x"3" => return '3';
      when x"4" => return '4';
      when x"5" => return '5';
      when x"6" => return '6';
      when x"7" => return '7';
      when x"8" => return '8';
      when x"9" => return '9';
      when x"A" => return 'A';
      when x"B" => return 'B';
      when x"C" => return 'C';
      when x"D" => return 'D';
      when x"E" => return 'E';
      when x"F" => return 'F';
      when others => return 'X';
    end case;
  end to_char;

  function to_string (data : in std_logic) return string is
    variable str : string(1 to 1);
  begin
    str(1) := to_char(data);
    return str;
  end function to_string;

  function to_string (data : in std_logic_vector) return string is
    variable v_str       : string (1 to data'length);
    variable v_str_index : positive := 1;
  begin
    for i in data'range loop
      v_str(v_str_index) := to_char(data(i));
      v_str_index := v_str_index + 1;
    end loop;
    return v_str;
  end function to_string;


end package body StringP;
