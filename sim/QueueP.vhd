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



package QueueP is


  generic (
    type     QUEUE_TYPE;
    MAX_LEN : natural := 64;
    function to_string(d : in QUEUE_TYPE) return string
  );


  -- simple queue interface
  type t_simple_queue is protected

    procedure push (data : in  QUEUE_TYPE);
    procedure pop  (data : out QUEUE_TYPE);
    procedure init (logging : in boolean := false);
    impure function is_empty  return boolean;
    impure function is_full   return boolean;
    impure function fillstate return natural;

  end protected t_simple_queue;


  -- linked list queue interface
  type t_list_queue is protected

    procedure push (data : in  QUEUE_TYPE);
    procedure pop  (data : out QUEUE_TYPE);
    procedure init (logging : in boolean := false);
    impure function is_empty return boolean;
    impure function is_full   return boolean;
    impure function fillstate return natural;

  end protected t_list_queue;


end package QueueP;



package body QueueP is


  -- simple queue implementation
  -- inspired by noasic article http://noasic.com/blog/a-simple-fifo-using-vhdl-protected-types/
  type t_simple_queue is protected body

    type t_queue_array is array (0 to MAX_LEN-1) of QUEUE_TYPE;

    variable v_queue : t_queue_array;
    variable v_count : natural range 0 to t_queue_array'length := 0;
    variable v_head  : natural range 0 to t_queue_array'high   := 0;
    variable v_tail  : natural range 0 to t_queue_array'high   := 0;
    variable v_logging : boolean := false;

    -- write one entry into queue
    procedure push (data : in QUEUE_TYPE) is
    begin
      assert not(is_full)
        report "push into full queue -> discarded"
        severity failure;
      v_queue(v_head) := data;
      v_head  := (v_head + 1) mod t_queue_array'length;
      v_count := v_count + 1;
      if v_logging then
        report t_simple_queue'instance_name & " pushed 0x" & to_string(data) & " into queue";
      end if;
    end procedure push;

    -- read one entry from queue
    procedure pop (data : out QUEUE_TYPE) is
      variable v_data : QUEUE_TYPE;
    begin
      assert not(is_empty)
        report "pop from empty queue -> discarded"
        severity failure;
      v_data := v_queue(v_tail);
      v_tail  := (v_tail + 1) mod t_queue_array'length;
      v_count := v_count - 1;
      if v_logging then
        report t_simple_queue'instance_name & " popped 0x" & to_string(v_data) & " from queue";
      end if;
      data := v_data;
    end procedure pop;

    -- returns true if queue is empty, false otherwise
    impure function is_empty return boolean is
    begin
      return v_count = 0;
    end function is_empty;

    -- returns true if queue is full, false otherwise
    impure function is_full return boolean is
    begin
      return v_count = t_queue_array'length;
    end function is_full;

    -- returns number of filled slots in queue
    impure function fillstate return natural is
    begin
      return v_count;
    end function fillstate;

    -- returns number of free slots in queue
    impure function freeslots return natural is
    begin
      return t_queue_array'length - v_count;
    end function freeslots;

    procedure init (logging : in boolean := false) is
    begin
      v_logging := logging;
    end procedure init;


  end protected body t_simple_queue;


  -- linked liste queue implementation
  type t_list_queue is protected body


    type t_entry;
    type t_entry_ptr is access t_entry;

    type t_data_ptr is access QUEUE_TYPE;

    type t_entry is record
      data       : t_data_ptr;
      last_entry : t_entry_ptr;
      next_entry : t_entry_ptr;
    end record t_entry;

    variable v_head    : t_entry_ptr;
    variable v_tail    : t_entry_ptr;
    variable v_count   : natural := 0;
    variable v_logging : boolean := false;

    -- write one entry into queue by
    -- creating new entry at head of list
    procedure push (data : in  QUEUE_TYPE) is
      variable v_entry : t_entry_ptr;
    begin
      if (not(is_full)) then 
        if (v_count /= 0) then
          v_entry            := new t_entry;
          v_entry.data       := new QUEUE_TYPE'(data);
          v_entry.last_entry := v_head;
          v_entry.next_entry := null;
          v_head             := v_entry;
          v_head.last_entry.next_entry := v_head;
        else
          v_head            := new t_entry;
          v_head.data       := new QUEUE_TYPE'(data);
          v_head.last_entry := null;
          v_head.next_entry := null;
          v_tail := v_head;
        end if;
        v_count := v_count + 1;
        if v_logging then
          report t_list_queue'instance_name & " pushed 0x" & to_string(data) & " into queue";
        end if;
      else
        assert false
        report "Push to full queue -> discared"
        severity warning;
      end if;
    end procedure push;

    -- read one entry from queue at tail of list and
    -- delete that entry from list after read
    procedure pop  (data : out QUEUE_TYPE) is
      variable v_entry : t_entry_ptr := v_tail;
      variable v_data  : QUEUE_TYPE;
    begin
      assert not(is_empty)
        report "pop from empty queue -> discarded"
        severity failure;
      v_data   := v_tail.data.all;
      v_tail := v_tail.next_entry;
      deallocate(v_entry.data);
      deallocate(v_entry);
      v_count := v_count - 1;
      if v_logging then
        report t_list_queue'instance_name & " popped 0x" & to_string(v_data) & " from queue";
      end if;
      data := v_data;
    end procedure pop;

    procedure init (logging : in boolean := false) is
    begin
      v_logging := logging;
    end procedure init;

    -- returns true if queue is full, false otherwise
    impure function is_full return boolean is
    begin
      return v_count = MAX_LEN;
    end function is_full;

    -- returns true if queue is empty, false otherwise
    impure function is_empty return boolean is
    begin
      return v_tail = null;
    end function is_empty;

    -- returns number of filled slots in queue
    impure function fillstate return natural is
    begin
      return v_count;
    end function fillstate;

  end protected body t_list_queue;


end package body QueueP;
