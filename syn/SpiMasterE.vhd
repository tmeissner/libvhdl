library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity SpiMasterE is
  generic (
    G_DATA_WIDTH   : positive := 8;                           --* data bus width
    G_DATA_DIR     : natural range 0 to 1 := 0;               --* start from lsb/msb 0/1
    G_SPI_CPOL     : natural range 0 to 1 := 0;               --* SPI clock polarity
    G_SPI_CPHA     : natural range 0 to 1 := 0;               --* SPI clock phase
    G_SCLK_DIVIDER : positive range 6 to positive'high := 10  --* SCLK divider related to system clock
  );
  port (
    --+ system if
    Reset_n_i    : in  std_logic;
    Clk_i        : in  std_logic;
    --+ SPI slave if
    SpiSclk_o    : out std_logic;
    SpiSte_o     : out std_logic;
    SpiMosi_o    : out std_logic;
    SpiMiso_i    : in  std_logic;
    --+ local VAI if
    Data_i       : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
    DataValid_i  : in  std_logic;
    DataAccept_o : out std_logic;
    Data_o       : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
    DataValid_o  : out std_logic;
    DataAccept_i : in  std_logic
  );
end entity SpiMasterE;



architecture rtl of SpiMasterE is


  type t_spi_state is (IDLE, WRITE, READ, CYCLE, STORE, SET_STE);
  signal s_spi_state : t_spi_state;

  signal s_send_register : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal s_recv_register : std_logic_vector(G_DATA_WIDTH-1 downto 0);

  signal s_miso_d : std_logic_vector(1 downto 0);

  signal s_mosi : std_logic;
  signal s_sclk : std_logic;
  signal s_ste  : std_logic;

  signal s_data_valid  : std_logic;
  signal s_data_accept : std_logic;
  signal s_transfer_valid : boolean;

  signal s_sclk_rising  : boolean;
  signal s_sclk_falling : boolean;
  signal s_read_edge    : boolean;
  signal s_write_edge   : boolean;

  alias a_miso : std_logic is s_miso_d(s_miso_d'left);

  constant C_BIT_COUNTER_START : natural := (G_DATA_WIDTH-1) * G_DATA_DIR;
  constant C_BIT_COUNTER_END   : natural := (G_DATA_WIDTH-1) * to_integer(not(to_unsigned(G_DATA_DIR, 1)));


begin


  --* Sync asynchronous SPI inputs with 2 stage FF line
  SpiSyncP : process (Reset_n_i, Clk_i) is
  begin
    if (Reset_n_i = '0') then
      s_miso_d <= (others => '0');
    elsif rising_edge(Clk_i) then
      s_miso_d <= s_miso_d(0) & SpiMiso_i;
    end if;
  end process SpiSyncP;


  --* Save local data input when new data is provided and
  --* we're not inside a running SPI transmission
  SendRegisterP : process (Reset_n_i, Clk_i) is
  begin
    if (Reset_n_i = '0') then
      s_send_register <= (others => '0');
      s_data_accept   <= '0';
    elsif rising_edge(Clk_i) then
      s_data_accept <= '0';
      if (DataValid_i = '1' and s_spi_state = IDLE) then
        s_send_register <= Data_i;
        s_data_accept   <= '1';
      end if;
    end if;
  end process SendRegisterP;


  --* Spi master control FSM
  SpiControlP : process (Reset_n_i, Clk_i) is
    variable v_bit_counter  : natural range 0 to G_DATA_WIDTH-1;
    variable v_sclk_counter : natural range 0 to G_SCLK_DIVIDER-1;
  begin
    if (Reset_n_i = '0') then
      s_recv_register  <= (others => '0');
      v_bit_counter    := C_BIT_COUNTER_START;
      v_sclk_counter   := G_SCLK_DIVIDER-1;
      s_transfer_valid <= false;
      s_sclk           <= std_logic'val(G_SPI_CPOL+2);
      s_mosi           <= '1';
      s_spi_state      <= IDLE;
    elsif rising_edge(Clk_i) then
      case s_spi_state is

        when IDLE =>
          s_sclk           <= std_logic'val(G_SPI_CPOL+2);
          s_mosi           <= '1';
          s_recv_register  <= (others => '0');
          v_bit_counter    := C_BIT_COUNTER_START;
          v_sclk_counter   := G_SCLK_DIVIDER/2-1;
          s_transfer_valid <= false;
          if(DataValid_i = '1' and s_data_accept = '1') then
            s_spi_state <= WRITE;
          end if;

        when WRITE =>
          if (G_SPI_CPHA = 0 and v_bit_counter = C_BIT_COUNTER_START) then
            s_mosi      <= s_send_register(v_bit_counter);
            s_spi_state <= READ;
          else
            if (v_sclk_counter = 0) then
              v_sclk_counter := G_SCLK_DIVIDER/2-1;
              s_sclk         <= not(s_sclk);
              s_mosi         <= s_send_register(v_bit_counter);
              s_spi_state    <= READ;
            else
              v_sclk_counter := v_sclk_counter - 1;
            end if;
          end if;

        when READ =>
          if (v_sclk_counter = 0) then
            s_sclk                         <= not(s_sclk);
            s_recv_register(v_bit_counter) <= a_miso;
            v_sclk_counter                 := G_SCLK_DIVIDER/2-1;
            if (v_bit_counter = C_BIT_COUNTER_END) then
              if (G_SPI_CPHA = 0) then
                s_spi_state    <= CYCLE;
              else
                s_spi_state <= STORE;
              end if;
            else
              if (G_DATA_DIR = 0) then
                v_bit_counter  := v_bit_counter + 1;
              else
                v_bit_counter  := v_bit_counter - 1;
              end if;
              s_spi_state    <= WRITE;
            end if;
          else
            v_sclk_counter := v_sclk_counter - 1;
          end if;

        when CYCLE =>
          if (v_sclk_counter = 0) then
            s_sclk         <= not(s_sclk);
            v_sclk_counter := G_SCLK_DIVIDER/2-1;
            s_spi_state    <= STORE;
          else
            v_sclk_counter := v_sclk_counter - 1;
          end if;

        when STORE =>
          if (v_sclk_counter = 0) then
            s_transfer_valid <= true;
            v_sclk_counter   := G_SCLK_DIVIDER/2-1;
            s_spi_state      <= SET_STE;
          else
            v_sclk_counter := v_sclk_counter - 1;
          end if;

        when SET_STE =>
          s_transfer_valid <= false;
          if (v_sclk_counter = 0) then
            s_spi_state      <= IDLE;
          else
            v_sclk_counter := v_sclk_counter - 1;
          end if;

        when others =>
          s_spi_state <= IDLE;

      end case;
    end if;
  end process SpiControlP;



  --* Provide received SPI data to local interface
  --* Output data is overwritten if it isn't fetched
  --* until next finished SPI transmission
  RecvRegisterP : process (Reset_n_i, Clk_i) is
  begin
    if (Reset_n_i = '0') then
      Data_o       <= (others => '0');
      s_data_valid <= '0';
    elsif rising_edge(Clk_i) then
      if (s_transfer_valid) then
        Data_o       <= s_recv_register;
        s_data_valid <= '1';
      end if;
      if (DataAccept_i = '1' and s_data_valid = '1') then
        s_data_valid <= '0';
      end if;
    end if;
  end process RecvRegisterP;


  --+ internal signals
  s_ste <= '1' when s_spi_state = IDLE or s_spi_state = SET_STE else '0';

  --+ Output port connections
  DataValid_o  <= s_data_valid;
  DataAccept_o <= s_data_accept;
  SpiSte_o     <= s_ste;
  SpiSclk_o    <= s_sclk;
  SpiMosi_o    <= s_mosi when s_ste = '0' else '1';


  assert G_SCLK_DIVIDER rem 2 = 0
    report "WARNING: " & SpiMasterE'instance_name & LF & "G_SCLK_DIVIDER " & integer'image(G_SCLK_DIVIDER) &
           " rounded down to next even value " & integer'image(G_SCLK_DIVIDER-1)
    severity warning;


  -- psl default clock is rising_edge(Clk_i);
  --
  -- psl assert always (s_spi_state = IDLE or s_spi_state = WRITE or s_spi_state = READ or
  --                    s_spi_state = CYCLE or s_spi_state = SET_STE or s_spi_state = STORE);
  -- psl assert always (s_data_valid and DataAccept_i) -> next not(s_data_valid);


end architecture rtl;