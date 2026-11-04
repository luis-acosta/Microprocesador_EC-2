LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY cu IS PORT(
  clock, reset, enter   : IN  STD_LOGIC;
  IR                      : IN  STD_LOGIC_VECTOR(7 DOWNTO 5);
  Aeq0, Apos              : IN  STD_LOGIC;
  IRload, JMPmux, PCload : OUT STD_LOGIC;
  Meminst, MemWr         : OUT STD_LOGIC;
  Asel                    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
  Aload, Sub              : OUT STD_LOGIC;
  Halt                    : OUT STD_LOGIC
);
END cu;

ARCHITECTURE FSM OF cu IS
  TYPE state_type IS (
    s_start, s_fetch, s_decode,
    s_load, s_store, s_add, s_sub,
    s_input, s_jz, s_jpos, s_halt
  );
  SIGNAL state, nextstate : state_type;
BEGIN
  -- Registro de estado
  PROCESS(clock, reset)
  BEGIN
    IF reset = '1' THEN
      state <= s_start;
    ELSIF clock'EVENT AND clock = '1' THEN
      state <= nextstate;
    END IF;
  END PROCESS;

  -- Lógica de próximo estado
  PROCESS(state, IR, enter)
  BEGIN
    CASE state IS
      WHEN s_start  => nextstate <= s_fetch;
      WHEN s_fetch  => nextstate <= s_decode;
      WHEN s_decode =>
        CASE IR IS
          WHEN "000" => nextstate <= s_load;
          WHEN "001" => nextstate <= s_store;
          WHEN "010" => nextstate <= s_add;
          WHEN "011" => nextstate <= s_sub;
          WHEN "100" => nextstate <= s_input;
          WHEN "101" => nextstate <= s_jz;
          WHEN "110" => nextstate <= s_jpos;
          WHEN OTHERS => nextstate <= s_halt;
        END CASE;
      WHEN s_load  => nextstate <= s_start;
      WHEN s_store => nextstate <= s_start;
      WHEN s_add   => nextstate <= s_start;
      WHEN s_sub   => nextstate <= s_start;
      WHEN s_input =>
        IF enter = '1' THEN
          nextstate <= s_start;
        ELSE
          nextstate <= s_input;     -- Esperar Enter
        END IF;
      WHEN s_jz   => nextstate <= s_start;
      WHEN s_jpos => nextstate <= s_start;
      WHEN s_halt => nextstate <= s_halt;
    END CASE;
  END PROCESS;

  -- Lógica de salida (asignaciones concurrentes condicionales)
  -- Cada señal se activa solo en los estados que la requieren
  IRload  <= '1' WHEN state = s_fetch  ELSE '0';
  JMPmux  <= '1' WHEN state = s_jz OR state = s_jpos ELSE '0';
  PCload  <= '1' WHEN state = s_fetch OR
              (state = s_jz AND Aeq0 = '1') OR
              (state = s_jpos AND Apos = '1') ELSE '0';
  Meminst <= '1' WHEN state = s_decode OR state = s_load
              OR state = s_store OR state = s_add
              OR state = s_sub ELSE '0';
  MemWr   <= '1' WHEN state = s_store ELSE '0';
  Asel    <= "00" WHEN state = s_load  ELSE
              "01" WHEN state = s_add OR state = s_sub ELSE
              "10" WHEN state = s_input ELSE "00";
  Aload   <= '1' WHEN state = s_load OR state = s_add
              OR state = s_sub OR state = s_input ELSE '0';
  Sub     <= '1' WHEN state = s_sub  ELSE '0';
  Halt    <= '1' WHEN state = s_halt ELSE '0';
END FSM;
