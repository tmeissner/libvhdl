library ieee;
  use ieee.std_logic_1164.all;



package DictP is


  type t_dict is protected

    procedure set (key : in string; data : in std_logic_vector);
    procedure get (key : in string; data : out std_logic_vector; err : out boolean);
    procedure del (key : in string; err : out boolean);
    procedure init (logging : in boolean := false);
    procedure clear (err : out boolean);
    impure function hasKey (key : string) return boolean;
    impure function size return natural;

  end protected t_dict;


end package DictP;



package body DictP is


  type t_dict is protected body


    type t_entry;
    type t_entry_ptr is access t_entry;

    type t_key_ptr  is access string;
    type t_data_ptr is access std_logic_vector;

    type t_entry is record
      key        : t_key_ptr;
      data       : t_data_ptr;
      last_entry : t_entry_ptr;
      next_entry : t_entry_ptr;
    end record t_entry;

    variable v_head    : t_entry_ptr := null;
    variable v_size    : natural := 0;
    variable v_logging : boolean := false;

    impure function find (key : string) return t_entry_ptr;

    procedure set (key : in string; data : in std_logic_vector) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      if (v_entry = null) then
        if (v_head /= null) then
          v_entry                      := new t_entry;
          v_entry.key                  := new string'(key);
          v_entry.data                 := new std_logic_vector'(data);
          v_entry.last_entry           := v_head;
          v_entry.next_entry           := v_entry;
          v_head                       := v_entry;
          v_head.last_entry.next_entry := v_head;
        else
          v_head            := new t_entry;
          v_head.key        := new string'(key);
          v_head.data       := new std_logic_vector'(data);
          v_head.last_entry := null;
          v_head.next_entry := v_entry;
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
    end procedure set;

    procedure get (key : in string; data : out std_logic_vector; err : out boolean) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      if(v_entry /= null) then
        data := v_entry.data.all;
        if v_logging then
          report t_dict'instance_name & ": Got key " & key & " with data 0x" & to_hstring(v_entry.data.all);
        end if;
        err := false;
      else
        err := true;
      end if;
    end procedure get;

    procedure del (key : in string; err : out boolean) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      if (v_entry /= null) then
        -- remove head entry
        if(v_entry.next_entry = null) then
          v_entry.last_entry.next_entry := null;
          v_head := v_entry.last_entry;
        -- remove start entry
        elsif(v_entry.last_entry = null) then
          v_entry.next_entry.last_entry := null;
        -- remove entry between
        else
          v_entry.last_entry.next_entry := v_entry.next_entry;
          v_entry.next_entry.last_entry := v_entry.last_entry;
        end if;
        deallocate(v_entry.key);
        deallocate(v_entry.data);
        deallocate(v_entry);
        v_size := v_size - 1;
        err := false;
      else
        err := true;
      end if;
    end procedure del;

    impure function find (key : string) return t_entry_ptr is
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

    procedure clear (err : out boolean) is
      variable v_entry   : t_entry_ptr := v_head;
      variable v_entry_d : t_entry_ptr;
      variable v_err     : boolean;
    begin
      err := false;
      while (v_entry /= null) loop
        v_entry_d := v_entry;
        del(v_entry_d.key.all, v_err);
        if v_err then
          err := true;
          return;
        else
          v_entry := v_entry.last_entry;
        end if;
      end loop;
    end procedure clear;

    impure function hasKey (key : string) return boolean is
    begin
      return find(key) /= null;
    end function hasKey;

    impure function size return natural is
    begin
      return v_size;
    end function size;

    procedure init (logging : in boolean := false) is
    begin
      v_logging := logging;
    end procedure init;


  end protected body t_dict;


end package body DictP;
