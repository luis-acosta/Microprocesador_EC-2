-- ==========================================================
-- EC-2 Datapath — Ruta de Datos Estructural
-- Usa librerías estándar IEEE.
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
-- NO se necesita LIBRARY lpm ni USE lpm.lpm_components.ALL

ENTITY dp IS
GENERIC(
  INIT_FILE : STRING := "gcd.mem"  -- No usado (programa hardcoded en ram.vhd)
);
PORT(
  Clock, reset           : IN  STD_LOGIC;             -- Reloj del sistema y reset asíncrono
  -- Entrada de datos del usuario (8 DIP switches)
  Input                  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
  -- Señales de control provenientes de la Unidad de Control (CU)
  IRload, JMPmux, PCload : IN  STD_LOGIC;             -- Carga IR, sel. MUX salto, carga PC
  Meminst, MemWr        : IN  STD_LOGIC;             -- Sel. dir. memoria, habilitación escritura
  Asel                   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);  -- Selección MUX 4:1 del acumulador
  Aload, Sub             : IN  STD_LOGIC;             -- Carga acumulador, selección resta
  -- Señales de estado hacia la Unidad de Control (CU)
  IR                     : OUT STD_LOGIC_VECTOR(7 DOWNTO 5);  -- Opcode (3 bits superiores de IR)
  Aeq0, Apos             : OUT STD_LOGIC;             -- Banderas: A=0 y A>0
  -- Salida de datos (hacia display 7-segmentos)
  Output                 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END dp;

ARCHITECTURE Structural OF dp IS

  -- ========================================
  -- Declaración de componentes reutilizables
  -- ========================================

  -- Registro genérico de N bits (IR, PC, Acumulador)
  COMPONENT reg
  GENERIC(size : INTEGER := 4);
  PORT(
    Clock, Clear, Load : IN  STD_LOGIC;
    D : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);
    Q : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)
  );
  END COMPONENT;

  -- Incrementador genérico de N bits (PC + 1)
  COMPONENT increment
  GENERIC(size : INTEGER := 8);
  PORT(
    A : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);
    F : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)
  );
  END COMPONENT;

  -- Multiplexor 2:1 genérico (JMPmux, Meminst MUX)
  COMPONENT mux2
  GENERIC(size : INTEGER := 8);
  PORT(
    S      : IN  STD_LOGIC;
    D1, D0 : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);
    Y      : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)
  );
  END COMPONENT;

  -- Multiplexor 4:1 genérico (selección entrada del acumulador)
  COMPONENT mux4
  GENERIC(size : INTEGER := 8);
  PORT(
    S              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    D3, D2, D1, D0 : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);
    Y              : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)
  );
  END COMPONENT;

  -- Sumador/Restador genérico de N bits
  COMPONENT addsub
  GENERIC(n : INTEGER := 4);
  PORT(
    S               : IN  std_logic;
    A, B           : IN  std_logic_vector(n-1 DOWNTO 0);
    F               : OUT std_logic_vector(n-1 DOWNTO 0);
    unsigned_overflow : OUT std_logic;
    signed_overflow   : OUT std_logic
  );
  END COMPONENT;

  -- ★ RAM genérica — reemplazo portable de lpm_ram_dq ★
  COMPONENT ram
  GENERIC(
    ADDR_WIDTH : INTEGER := 5;
    DATA_WIDTH : INTEGER := 8
  );
  PORT(
    clock   : IN  STD_LOGIC;
    we      : IN  STD_LOGIC;
    address : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    data    : IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    q       : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
  );
  END COMPONENT;

  -- ==========================================
  -- Señales internas de interconexión
  -- ==========================================
  SIGNAL dp_IR, dp_RAMQ       : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL dp_JMPmux, dp_PC    : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL dp_increment         : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL dp_meminst           : STD_LOGIC_VECTOR(4 DOWNTO 0);
  SIGNAL dp_Amux, dp_addsub  : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL dp_A                 : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
  -- ==========================================
  -- Instanciación estructural de componentes
  -- ==========================================

  -- U0: Registro de Instrucción (IR) — 8 bits
  U0: reg GENERIC MAP(8) PORT MAP(
    Clock, reset, IRLoad, dp_RAMQ, dp_IR);
  IR <= dp_IR(7 DOWNTO 5);  -- Enviar opcode a la CU

  -- U1: JMPmux — MUX 2:1 de 5 bits
  U1: mux2 GENERIC MAP(5) PORT MAP(
    JMPmux, dp_IR(4 DOWNTO 0), dp_increment, dp_JMPmux);

  -- U2: Contador de Programa (PC) — 5 bits
  U2: reg GENERIC MAP(5) PORT MAP(
    Clock, reset, PCLoad, dp_JMPmux, dp_PC);

  -- U3: Meminst MUX — MUX 2:1 de 5 bits
  U3: mux2 GENERIC MAP(5) PORT MAP(
    Meminst, dp_IR(4 DOWNTO 0), dp_PC, dp_meminst);

  -- U4: Incrementador — PC + 1
  U4: increment GENERIC MAP(5) PORT MAP(
    dp_PC, dp_increment);

  -- ★ U5: RAM 32×8 — Componente genérico (reemplaza lpm_ram_dq) ★
  -- El programa se define dentro de ram.vhd como constante INIT
  -- No requiere archivo .mif externo
  U5: ram
  GENERIC MAP(
    ADDR_WIDTH => 5,   -- 5 bits de dirección → 32 posiciones
    DATA_WIDTH => 8    -- 8 bits de ancho de palabra
  )
  PORT MAP(
    clock   => Clock,       -- Reloj para escritura síncrona
    we      => MemWr,       -- Write Enable
    address => dp_meminst,  -- Dirección (del MUX Meminst)
    data    => dp_A,        -- Datos de escritura (del acumulador)
    q       => dp_RAMQ      -- Datos leídos de memoria
  );

  -- U6: MUX 4:1 — Selección de entrada al acumulador
  -- Asel="00"→D0=RAMQ(LOAD), "01"→D1=AddSub(ADD/SUB), "10"→D2=Input(IN)
  U6: mux4 GENERIC MAP(8) PORT MAP(
    Asel, dp_RAMQ, Input, dp_addsub, dp_RAMQ, dp_Amux);

  -- U7: Acumulador A — Registro de 8 bits
  U7: reg GENERIC MAP(8) PORT MAP(
    Clock, reset, ALoad, dp_Amux, dp_A);

  -- U8: Sumador/Restador de 8 bits
  U8: addsub GENERIC MAP(8) PORT MAP(
    Sub, dp_A, dp_RAMQ, dp_addsub, open, open);

  -- ==========================================
  -- Señales de estado para la Unidad de Control
  -- ==========================================
  Aeq0   <= '1' WHEN dp_A = "00000000" ELSE '0';
  Apos   <= NOT dp_A(7);
  Output <= dp_A;
END Structural;
