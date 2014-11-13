library ieee;
  use ieee.std_logic_1164.all;



package QueueP is


  -- simple queue protected type
  -- inspired by noasic article http://noasic.com/blog/a-simple-fifo-using-vhdl-protected-types/
  type t_simple_queue is protected

    procedure push (data : in  std_logic_vector);
    procedure pop  (data : out std_logic_vector);
    impure function is_empty  return boolean;
    impure function is_full   return boolean;
    impure function fillstate return natural;
    impure function freeslots return natural;

  end protected t_simple_queue;


  -- linked list queue
  type t_list_queue is protected

    procedure push (data : in  std_logic_vector);
    procedure pop  (data : out std_logic_vector);
    impure function is_empty return boolean;
    impure function is_full  return boolean;
    impure function fillstate return natural;
    impure function freeslots return natural;

  end protected t_list_queue;


end package QueueP;



package body QueueP is


  type t_simple_queue is protected body

    constant C_QUEUE_DEPTH : natural := 64;
    constant C_QUEUE_WIDTH : natural := 64;

    type t_queue_array is array (0 to C_QUEUE_DEPTH-1) of std_logic_vector(C_QUEUE_WIDTH-1 downto 0);

    variable v_queue : t_queue_array := (others => (others => '0'));
    variable v_count : natural range 0 to t_queue_array'length := 0;
    variable v_head  : natural range 0 to t_queue_array'high   := 0;
    variable v_tail  : natural range 0 to t_queue_array'high   := 0;

    -- write one entry into queue
    procedure push (data : in  std_logic_vector) is
    begin
      assert not(is_full)
        report "push into full queue -> discarded"
        severity failure;
      v_queue(v_head) := data;
      v_head  := (v_head + 1) mod t_queue_array'length;
      v_count := v_count + 1;
    end procedure push;

    -- read one entry from queue
    procedure pop (data : out std_logic_vector) is
    begin
      assert not(is_empty)
        report "pop from empty queue -> discarded"
        severity failure;
      data := v_queue(v_tail);
      v_tail  := (v_tail + 1) mod t_queue_array'length;
      v_count := v_count - 1;
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

  end protected body t_simple_queue;


  type t_list_queue is protected body

    constant C_QUEUE_DEPTH : natural := 64;
    constant C_QUEUE_WIDTH : natural := 64;

    type t_entry;
    type t_entry_ptr is access t_entry;

    type t_entry is record
      data       : std_logic_vector(C_QUEUE_WIDTH-1 downto 0);
      last_entry : t_entry_ptr;
      next_entry : t_entry_ptr;
    end record t_entry;

    variable v_head : t_entry_ptr;
    variable v_tail : t_entry_ptr;
    variable v_count : natural range 0 to C_QUEUE_DEPTH := 0;

    -- write one entry into queue
    procedure push (data : in  std_logic_vector) is
    begin
      assert not(is_full)
        report "push into full queue -> discarded"
        severity failure;
      if(v_head /= null) then
        v_head := new t_entry'(data, v_head, null);
        v_head.last_entry.next_entry := v_head;
      else
        v_head := new t_entry'(data, null, null);
        v_tail := v_head;
      end if;
      v_count := v_count + 1;
    end procedure push;

    -- read one entry from queue
    procedure pop  (data : out std_logic_vector) is
      variable v_entry : t_entry_ptr;
    begin
      assert not(is_empty)
        report "pop from empty queue -> discarded"
        severity failure;
      data := v_tail.data;
      v_entry := v_tail;
      v_tail := v_tail.next_entry;
      deallocate(v_entry);
      v_count := v_count - 1;
    end procedure pop;

    -- returns true if queue is empty, false otherwise
    impure function is_empty return boolean is
    begin
      return v_tail = null;
    end function is_empty;

    -- returns true if queue is full, false otherwise
    impure function is_full return boolean is
    begin
      return v_count = C_QUEUE_DEPTH;
    end function is_full;

    -- returns number of filled slots in queue
    impure function fillstate return natural is
    begin
      return v_count;
    end function fillstate;

    -- returns number of free slots in queue
    impure function freeslots return natural is
    begin
      return C_QUEUE_DEPTH - v_count;
    end function freeslots;

  end protected body t_list_queue;


end package body QueueP;
