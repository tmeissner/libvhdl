library ieee;
  use ieee.std_logic_1164.all;



package DictP is


  type t_dict_dir   is (UP, DOWN);
  type t_dict_error is (NO_ERROR, KEY_INVALID, KEY_NOT_FOUND);
  type t_dict_iter  is (TAIL, HEAD);

  type t_dict_key_ptr  is access string;
  type t_dict_data_ptr is access std_logic_vector;

  type t_dict is protected

    procedure set (constant key : in string; constant data : in std_logic_vector; err : out t_dict_error);
    procedure get (constant key : in string; data : out std_logic_vector; err : out t_dict_error);
    procedure del (constant key : in string; err : out t_dict_error);
    procedure init (constant logging : in boolean := false);
    procedure clear (err : out t_dict_error);
    impure function hasKey (constant key : string) return boolean;
    impure function size return natural;
    procedure setIter(constant start : in t_dict_iter := TAIL);
    impure function iter (constant dir : t_dict_dir := UP) return string;
    impure function get (constant key : string) return std_logic_vector;

  end protected t_dict;

  procedure merge(d0 : inout t_dict; d1 : inout t_dict; d : inout t_dict; err : out t_dict_error);


end package DictP;



package body DictP is


  type t_dict is protected body


    type t_entry;
    type t_entry_ptr is access t_entry;

    type t_entry is record
      key        : t_dict_key_ptr;
      data       : t_dict_data_ptr;
      last_entry : t_entry_ptr;
      next_entry : t_entry_ptr;
    end record t_entry;

    variable v_tail     : t_entry_ptr := null;
    variable v_head     : t_entry_ptr := null;
    variable v_iterator : t_entry_ptr := null;
    variable v_size     : natural := 0;
    variable v_logging  : boolean := false;

    impure function find (constant key : string) return t_entry_ptr;

    procedure set (constant key : in string; constant data : in std_logic_vector; err : out t_dict_error) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      if (key = "") then
        err := KEY_INVALID;
      else
        if (v_entry = null) then
          if (v_head /= null) then
            v_entry                      := new t_entry;
            v_entry.key                  := new string'(key);
            v_entry.data                 := new std_logic_vector'(data);
            v_entry.last_entry           := v_head;
            v_entry.next_entry           := null;
            v_head                       := v_entry;
            v_head.last_entry.next_entry := v_head;
          else
            v_head            := new t_entry;
            v_head.key        := new string'(key);
            v_head.data       := new std_logic_vector'(data);
            v_head.last_entry := null;
            v_head.next_entry := null;
            v_tail           := v_head;
          end if;
          if (v_logging) then
            report t_dict'instance_name & ": Add key " & key & " with data 0x" & to_hstring(data);
          end if;
          v_size := v_size + 1;
        else
          v_entry.data.all := data;
          if (v_logging) then
            report t_dict'instance_name & ": Set key " & key & " to 0x" & to_hstring(data);
          end if;
        end if;
        err := NO_ERROR;
      end if;
    end procedure set;

    procedure get (constant key : in string; data : out std_logic_vector; err : out t_dict_error) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      if(v_entry /= null) then
        data := v_entry.data.all;
        if v_logging then
          report t_dict'instance_name & ": Got key " & key & " with data 0x" & to_hstring(v_entry.data.all);
        end if;
        err := NO_ERROR;
      else
        err := KEY_NOT_FOUND;
      end if;
    end procedure get;

    procedure del (constant key : in string; err : out t_dict_error) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      if (v_entry /= null) then
        -- remove head entry
        if(v_entry.next_entry = null and v_entry.last_entry /= null) then
          v_entry.last_entry.next_entry := null;
          v_head                        := v_entry.last_entry;
        -- remove start entry
        elsif(v_entry.next_entry /= null and v_entry.last_entry = null) then
          v_entry.next_entry.last_entry := null;
          --v_entry.next_entry.last_entry := v_entry.last_entry;
          v_tail                       := v_entry.next_entry;
        -- remove from between
        elsif(v_entry.next_entry /= null and v_entry.last_entry /= null) then
          v_entry.last_entry.next_entry := v_entry.next_entry;
          v_entry.next_entry.last_entry := v_entry.last_entry;
        end if;
        deallocate(v_entry.key);
        deallocate(v_entry.data);
        deallocate(v_entry);
        v_size := v_size - 1;
        err := NO_ERROR;
      else
        err := KEY_NOT_FOUND;
      end if;
    end procedure del;

    impure function find (constant key : string) return t_entry_ptr is
      variable v_entry : t_entry_ptr := v_head;
    begin
      while (v_entry /= null) loop
        if(v_entry.key.all = key) then
          return v_entry;
        end if;
        v_entry := v_entry.last_entry;
      end loop;
      return null;
    end function find;

    procedure clear (err : out t_dict_error) is
      variable v_entry   : t_entry_ptr := v_head;
      variable v_entry_d : t_entry_ptr;
      variable v_err     : t_dict_error;
    begin
      while (v_entry /= null) loop
        v_entry_d := v_entry;
        del(v_entry_d.key.all, v_err);
        if (v_err /= NO_ERROR) then
          err := v_err;
          return;
        else
          v_entry := v_entry.last_entry;
        end if;
      end loop;
      err := NO_ERROR;
    end procedure clear;

    impure function hasKey (constant key : string) return boolean is
    begin
      return find(key) /= null;
    end function hasKey;

    impure function size return natural is
    begin
      return v_size;
    end function size;

    procedure init (constant logging : in boolean := false) is
    begin
      v_logging := logging;
    end procedure init;

    procedure setIter (constant start : in t_dict_iter := TAIL) is
    begin
      if (start = TAIL) then
        v_iterator := v_tail;
      else
        v_iterator := v_head;
      end if;
    end procedure setIter;

    impure function iter (constant dir : t_dict_dir := UP) return string is
      variable v_key : t_dict_key_ptr := null;
    begin
      if (v_iterator /= null) then
        v_key := new string'(v_iterator.key.all);
        if (dir = UP) then
          v_iterator := v_iterator.next_entry;
        else
          v_iterator := v_iterator.last_entry;
        end if;
        return v_key.all;
      else
        return "";
      end if;
    end function iter;

    impure function get(constant key : string) return std_logic_vector is
      variable v_entry : t_entry_ptr := find(key);
    begin
      assert v_entry /= null
        report t_dict'instance_name & ": ERROR: key " & key & " not found"
        severity failure;
      return v_entry.data.all;
    end function get;


  end protected body t_dict;


  procedure merge(d0 : inout t_dict; d1 : inout t_dict; d : inout t_dict; err : out t_dict_error) is
    variable v_key   : t_dict_key_ptr;
    variable v_data  : t_dict_data_ptr;
    variable v_error : t_dict_error;
  begin
    if (d0.size > 0) then
      d0.setIter(TAIL);
      for i in 0 to d0.size-1 loop
        v_key  := new string'(d0.iter(UP));
        v_data := new std_logic_vector'(d0.get(v_key.all));
        d.set(v_key.all, v_data.all, v_error);
        if (v_error /= NO_ERROR) then
          err := v_error;
          return;
        end if;
      end loop;
    end if;
    if (d1.size > 0) then
      d1.setIter(TAIL);
      for i in 0 to d1.size-1 loop
        v_key  := new string'(d1.iter(UP));
        v_data := new std_logic_vector'(d1.get(v_key.all));
        d.set(v_key.all, v_data.all, v_error);
        if (v_error /= NO_ERROR) then
          err := v_error;
          return;
        end if;
      end loop;
    end if;
  end procedure merge;


end package body DictP;
