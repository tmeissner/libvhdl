library ieee;
  use ieee.std_logic_1164.all;

--+ including vhdl 2008 libraries
--+ These lines can be commented out when using
--+ a simulator with built-in VHDL 2008 support
--library ieee_proposed;
--  use ieee_proposed.standard_additions.all;
--  use ieee_proposed.std_logic_1164_additions.all;


package StackP is


  -- linked list stack interface
  type t_stack is protected

    procedure push (data : in  std_logic_vector);
    procedure pop  (data : inout std_logic_vector);
    procedure init (logging : in boolean := false);
    impure function is_empty return boolean;
    impure function fillstate return natural;

  end protected t_stack;


end package StackP;



package body StackP is


  -- linked list stack implementation
  type t_stack is protected body

    type t_entry;
    type t_entry_ptr is access t_entry;

    type t_data_ptr is access std_logic_vector;

    type t_entry is record
      data       : t_data_ptr;
      last_entry : t_entry_ptr;
      next_entry : t_entry_ptr;
    end record t_entry;

    variable v_head    : t_entry_ptr := null;
    variable v_tail    : t_entry_ptr := null;
    variable v_count   : natural := 0;
    variable v_logging : boolean := false;

    -- write one entry into queue by
    -- creating new entry at head of list
    procedure push (data : in  std_logic_vector) is
      variable v_entry : t_entry_ptr;
    begin
      if (v_count /= 0) then
        v_entry            := new t_entry;
        v_entry.data       := new std_logic_vector'(data);
        v_entry.last_entry := v_head;
        v_entry.next_entry := null;
        v_head             := v_entry;
        v_head.last_entry.next_entry := v_head;
      else
        v_head            := new t_entry;
        v_head.data       := new std_logic_vector'(data);
        v_head.last_entry := null;
        v_head.next_entry := null;
        v_tail            := v_head;
      end if;
      v_count := v_count + 1;
      if v_logging then
        report t_stack'instance_name & " pushed 0x" & to_hstring(data) & " on stack";
      end if;
    end procedure push;

    -- read one entry from queue at tail of list and
    -- delete that entry from list after read
    procedure pop  (data : inout std_logic_vector) is
      variable v_entry : t_entry_ptr := v_head;
    begin
      assert not(is_empty)
        report "pop from empty queue -> discarded"
        severity failure;
      data   := v_head.data.all;
      v_head := v_head.last_entry;
      deallocate(v_entry.data);
      deallocate(v_entry);
      v_count := v_count - 1;
      if v_logging then
        report t_stack'instance_name & " popped 0x" & to_hstring(data) & " from stack";
      end if;
    end procedure pop;

    procedure init (logging : in boolean := false) is
    begin
      v_logging := logging;
    end procedure init;

    -- returns true if queue is empty, false otherwise
    impure function is_empty return boolean is
    begin
      return v_head = null;
    end function is_empty;

    -- returns number of filled slots in queue
    impure function fillstate return natural is
    begin
      return v_count;
    end function fillstate;

  end protected body t_stack;


end package body StackP;
