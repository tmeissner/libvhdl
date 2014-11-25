library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;



entity SpiSlaveE is
  generic (
    G_DATA_WIDTH : positive := 8;              --* data bus width
    G_DATA_DIR   : natural range 0 to 1 := 0;  --* start from lsb/msb 0/1
    G_SPI_CPOL   : natural range 0 to 1 := 0;  --* SPI clock polarity
    G_SPI_CPHA   : natural range 0 to 1 := 0   --* SPI clock phase
  );
  port (
    --+ system if
    Reset_n_i    : in  std_logic;
    Clk_i        : in  std_logic;
    --+ SPI slave if
    SpiSclk_i    : in  std_logic;
    SpiSte_i     : in  std_logic;
    SpiMosi_i    : in  std_logic;
    SpiMiso_o    : out std_logic;
    --+ local VAI if
    Data_i       : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
    DataValid_i  : in  std_logic;
    DataAccept_o : out std_logic;
    Data_o       : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
    DataValid_o  : out std_logic;
    DataAccept_i : in  std_logic
  );
end entity SpiSlaveE;



architecture rtl of SpiSlaveE is


  type t_spi_state is (IDLE, TRANSFER, STORE);
  signal s_spi_state : t_spi_state;

  signal s_send_register : std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal s_recv_register : std_logic_vector(G_DATA_WIDTH-1 downto 0);

  signal s_sclk_d : std_logic_vector(2 downto 0);
  signal s_ste_d  : std_logic_vector(2 downto 0);
  signal s_mosi_d : std_logic_vector(2 downto 0);

  signal s_miso : std_logic;

  signal s_data_valid : std_logic;
  signal s_transfer_valid : boolean;

  signal s_sclk_rising  : boolean;
  signal s_sclk_falling : boolean;
  signal s_read_edge    : boolean;
  signal s_write_edge   : boolean;

  alias a_ste  : std_logic is s_ste_d(s_ste_d'left);
  alias a_mosi : std_logic is s_mosi_d(s_mosi_d'left);

  constant C_BIT_COUNTER_START : natural := (G_DATA_WIDTH-1) * G_DATA_DIR;
  constant C_BIT_COUNTER_END   : natural := (G_DATA_WIDTH-1) * to_integer(not(to_unsigned(G_DATA_DIR, 1)));


begin


  --* help signals for edge detection on sclk
  s_sclk_rising  <= true when s_sclk_d(2 downto 1) = "01" else false;
  s_sclk_falling <= true when s_sclk_d(2 downto 1) = "10" else false;

  s_read_edge  <= s_sclk_rising  when G_SPI_CPOL = G_SPI_CPHA else s_sclk_falling;
  s_write_edge <= s_sclk_falling when G_SPI_CPOL = G_SPI_CPHA else s_sclk_rising;


  --* Sync asynchronous SPI inputs with 3 stage FF line
  --* We use 3 FF because of edge detection on sclk line
  --* Mosi & ste are also registered with 3 FF to stay in
  --* sync with registered sclk
  SpiSyncP : process (Reset_n_i, Clk_i) is
  begin
    if (Reset_n_i = '0') then
      if (G_SPI_CPOL = 0) then
        s_sclk_d <= (others => '0');
      else
        s_sclk_d <= (others => '1');
      end if;
      s_ste_d  <= (others => '1');
      s_mosi_d <= (others => '0');
    elsif rising_edge(Clk_i) then
      s_sclk_d <= s_sclk_d(1 downto 0) & SpiSclk_i;
      s_ste_d  <= s_ste_d(1 downto 0)  & SpiSte_i;
      s_mosi_d <= s_mosi_d(1 downto 0) & SpiMosi_i;
    end if;
  end process SpiSyncP;


  --* Save local data input when new data is provided and
  --* we're not inside a running SPI transmission
  SendRegisterP : process (Reset_n_i, Clk_i) is
  begin
    if (Reset_n_i = '0') then
      s_send_register <= (others => '0');
      DataAccept_o    <= '0';
    elsif rising_edge(Clk_i) then
      DataAccept_o <= '0';
      if (DataValid_i = '1' and s_spi_state = IDLE) then
        s_send_register <= Data_i;
        DataAccept_o    <= '1';
      end if;
    end if;
  end process SendRegisterP;


  --* Spi slave control FSM
  SpiControlP : process (Reset_n_i, Clk_i) is
    variable v_bit_counter : natural range 0 to G_DATA_WIDTH-1;
  begin
    if (Reset_n_i = '0') then
      s_miso           <= '0';
      s_recv_register  <= (others => '0');
      v_bit_counter    := C_BIT_COUNTER_START;
      s_transfer_valid <= false;
      s_spi_state      <= IDLE;
    elsif rising_edge(Clk_i) then
      case s_spi_state is

        when IDLE =>
          s_miso           <= '0';
          s_recv_register  <= (others => '0');
          v_bit_counter    := C_BIT_COUNTER_START;
          s_transfer_valid <= false;
          if (a_ste = '0') then
            if (G_SPI_CPHA = 0) then
              s_miso <= s_send_register(v_bit_counter);
            end if;
            s_spi_state <= TRANSFER;
          end if;

        when TRANSFER =>
          if s_read_edge then
            s_recv_register(v_bit_counter) <= a_mosi;
            if (v_bit_counter = C_BIT_COUNTER_END) then
              s_spi_state <= STORE;
            else
              if (G_DATA_DIR = 0) then
                v_bit_counter := v_bit_counter + 1;
              else
                v_bit_counter := v_bit_counter - 1;
              end if;
            end if;
          elsif s_write_edge then
            s_miso <= s_send_register(v_bit_counter);
          else
            if (a_ste = '1') then
              s_spi_state <= IDLE;
            end if;
          end if;

        when STORE =>
          if (a_ste = '1') then
            s_transfer_valid <= true;
            s_spi_state      <= IDLE;
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


  --+ Output port connections
  DataValid_o <= s_data_valid;
  SpiMiso_o   <= 'Z' when SpiSte_i = '1' else s_miso;


  -- psl default clock is rising_edge(Clk_i);
  --
  -- psl assert always (s_spi_state = IDLE or s_spi_state = TRANSFER or s_spi_state = STORE);
  -- psl assert always (s_data_valid and DataAccept_i) -> next not(s_data_valid);


end architecture rtl;
