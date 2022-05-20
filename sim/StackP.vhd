--  Copyright (c) 2014 - 2022 by Torsten Meissner
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.



library ieee;
  use ieee.std_logic_1164.all;



package StackP is


  generic (
    type     STACK_TYPE;
    MAX_LEN : natural := 64;
    function to_string(d : in STACK_TYPE) return string
  );

  -- linked list stack interface
  type t_stack is protected

    procedure push (data : in  STACK_TYPE);
    procedure pop  (data : inout STACK_TYPE);
    procedure init (logging : in boolean := false);
    impure function is_empty return boolean;
    impure function is_full return boolean;
    impure function fillstate return natural;

  end protected t_stack;


end package StackP;



package body StackP is


  -- linked list stack implementation
  type t_stack is protected body

    type t_entry;
    type t_entry_ptr is access t_entry;

    type t_data_ptr is access STACK_TYPE;

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
    procedure push (data : in  STACK_TYPE) is
      variable v_entry : t_entry_ptr;
    begin
      if (not(is_full)) then
        if (v_count /= 0) then
          v_entry            := new t_entry;
          v_entry.data       := new STACK_TYPE'(data);
          v_entry.last_entry := v_head;
          v_entry.next_entry := null;
          v_head             := v_entry;
          v_head.last_entry.next_entry := v_head;
        else
          v_head            := new t_entry;
          v_head.data       := new STACK_TYPE'(data);
          v_head.last_entry := null;
          v_head.next_entry := null;
          v_tail            := v_head;
        end if;
        v_count := v_count + 1;
        if v_logging then
          report t_stack'instance_name & " pushed 0x" & to_string(data) & " on stack";
        end if;
      else
        assert false
        report t_stack'instance_name & " push to full stack -> discared"
        severity warning;
      end if;
    end procedure push;

    -- read one entry from queue at tail of list and
    -- delete that entry from list after read
    procedure pop  (data : inout STACK_TYPE) is
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
        report t_stack'instance_name & " popped 0x" & to_string(data) & " from stack";
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

    -- returns true if queue is full, false otherwise
    impure function is_full return boolean is
    begin
      return v_count = MAX_LEN;
    end function is_full;

    -- returns number of filled slots in queue
    impure function fillstate return natural is
    begin
      return v_count;
    end function fillstate;

  end protected body t_stack;


end package body StackP;
