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



package DictP is


  generic (
    type     KEY_TYPE;
    type     VALUE_TYPE;
    function key_to_string(d : in KEY_TYPE) return string;
    function value_to_string(d : in VALUE_TYPE) return string
  );



  type t_dict_key_ptr  is access KEY_TYPE;
  type t_dict_data_ptr is access VALUE_TYPE;

  type t_dict_dir   is (UP, DOWN);
  type t_dict_iter  is (TAIL, HEAD);

  type t_dict is protected

    procedure set (constant key : in KEY_TYPE; constant data : in VALUE_TYPE);
    procedure get (constant key : in KEY_TYPE; data : out VALUE_TYPE);
    procedure del (constant key : in KEY_TYPE);
    procedure init (constant logging : in boolean := false);
    procedure clear;
    impure function hasKey (constant key : KEY_TYPE) return boolean;
    impure function size return natural;
    procedure setIter(constant start : in t_dict_iter := TAIL);
    impure function iter (constant dir : t_dict_dir := UP) return KEY_TYPE;
    impure function get (constant key : KEY_TYPE) return VALUE_TYPE;

  end protected t_dict;

  procedure merge(d0 : inout t_dict; d1 : inout t_dict; d : inout t_dict);


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

    impure function find (constant key : KEY_TYPE) return t_entry_ptr;

    procedure set (constant key : in KEY_TYPE; constant data : in VALUE_TYPE) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      if (v_entry = null) then
        if (v_head /= null) then
          v_entry                      := new t_entry;
          v_entry.key                  := new KEY_TYPE'(key);
          v_entry.data                 := new VALUE_TYPE'(data);
          v_entry.last_entry           := v_head;
          v_entry.next_entry           := null;
          v_head                       := v_entry;
          v_head.last_entry.next_entry := v_head;
        else
          v_head            := new t_entry;
          v_head.key        := new KEY_TYPE'(key);
          v_head.data       := new VALUE_TYPE'(data);
          v_head.last_entry := null;
          v_head.next_entry := null;
          v_tail           := v_head;
        end if;
        if (v_logging) then
          report t_dict'instance_name & ": Add key " & key_to_string(key) & " with value " & value_to_string(data) & " to dictionary";
        end if;
        v_size := v_size + 1;
      else
        v_entry.data.all := data;
        if (v_logging) then
          report t_dict'instance_name & ": Set value of key " & key_to_string(key) & " to 0x" & value_to_string(data);
        end if;
      end if;
    end procedure set;

    procedure get (constant key : in KEY_TYPE; data : out VALUE_TYPE) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      assert v_entry /= null
        report t_dict'instance_name & ": key " & key_to_string(key) & " not found"
        severity failure;
      if(v_entry /= null) then
        data := v_entry.data.all;
        if v_logging then
          report t_dict'instance_name & ": Got key " & key_to_string(key) & " with value " & value_to_string(v_entry.data.all);
        end if;
      end if;
    end procedure get;

    procedure del (constant key : in KEY_TYPE) is
      variable v_entry : t_entry_ptr := find(key);
    begin
      assert v_entry /= null
        report t_dict'instance_name & ": key " & key_to_string(key) & " not found"
        severity failure;
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
      end if;
    end procedure del;

    impure function find (constant key : KEY_TYPE) return t_entry_ptr is
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

    procedure clear is
      variable v_entry   : t_entry_ptr := v_head;
      variable v_entry_d : t_entry_ptr;
    begin
      while (v_entry /= null) loop
        v_entry_d := v_entry;
        del(v_entry_d.key.all);
        v_entry := v_entry.last_entry;
      end loop;
    end procedure clear;

    impure function hasKey (constant key : KEY_TYPE) return boolean is
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

    impure function iter (constant dir : t_dict_dir := UP) return KEY_TYPE is
      variable v_key : t_dict_key_ptr := null;
    begin
      v_key := new KEY_TYPE'(v_iterator.key.all);
      if (dir = UP) then
        if (v_iterator.next_entry /= null) then
          v_iterator := v_iterator.next_entry;
        end if;
      else
        if (v_iterator.last_entry /= null) then
          v_iterator := v_iterator.last_entry;
        end if;
      end if;
      return v_key.all;
    end function iter;

    impure function get(constant key : KEY_TYPE) return VALUE_TYPE is
      variable v_entry : t_entry_ptr := find(key);
    begin
      assert v_entry /= null
        report t_dict'instance_name & ": key " & key_to_string(key) & " not found"
        severity failure;
      return v_entry.data.all;
    end function get;


  end protected body t_dict;


  procedure merge(d0 : inout t_dict; d1 : inout t_dict; d : inout t_dict) is
    variable v_key   : t_dict_key_ptr;
    variable v_data  : t_dict_data_ptr;
  begin
    if (d0.size > 0) then
      d0.setIter(TAIL);
      for i in 0 to d0.size-1 loop
        v_key  := new KEY_TYPE'(d0.iter(UP));
        v_data := new VALUE_TYPE'(d0.get(v_key.all));
        d.set(v_key.all, v_data.all);
      end loop;
    end if;
    if (d1.size > 0) then
      d1.setIter(TAIL);
      for i in 0 to d1.size-1 loop
        v_key  := new KEY_TYPE'(d1.iter(UP));
        v_data := new VALUE_TYPE'(d1.get(v_key.all));
        d.set(v_key.all, v_data.all);
      end loop;
    end if;
  end procedure merge;


end package body DictP;
