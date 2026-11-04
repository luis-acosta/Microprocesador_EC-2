-- ==========================================================
-- RAM Genérica 32×8 — Reemplazo portable de lpm_ram_dq
-- Sintetizable en cualquier FPGA (Xilinx, Lattice, Intel, etc.)
-- Lectura combinacional, escritura síncrona.
-- El programa se inicializa mediante una constante INIT.
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ram IS
  GENERIC(
    ADDR_WIDTH : INTEGER := 5;   -- 5 bits → 32 posiciones
    DATA_WIDTH : INTEGER := 8    -- 8 bits de ancho de palabra
  );
  PORT(
    clock   : IN  STD_LOGIC;                                     -- Reloj (escritura síncrona)
    we      : IN  STD_LOGIC;                                     -- Write Enable
    address : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);     -- Dirección
    data    : IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);     -- Datos de escritura
    q       : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)      -- Datos leídos
  );
END ram;

ARCHITECTURE Behavioral OF ram IS

  -- Tipo para el arreglo de memoria
  TYPE memory_array IS ARRAY(0 TO 2**ADDR_WIDTH-1) OF
    STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

  -- =====================================================
  -- PROGRAMA: Máximo Común Divisor (GCD)
  -- Modifica este arreglo para cargar tu propio programa.
  -- Direcciones 0-N: instrucciones del programa
  -- Direcciones restantes: datos (inicializados a "00000000")
  -- =====================================================
  CONSTANT INIT : memory_array := (
    -- Dir  Binario       Instrucción       Descripción
    -- ===================== Programa GCD por restas sucesivas =====================
    0  => "10000000",   -- IN                ; A ← entrada (primer número)
    1  => "00111100",   -- STORE 28          ; M[28] ← a
    2  => "10000000",   -- IN                ; A ← entrada (segundo número)
    3  => "00111101",   -- STORE 29          ; M[29] ← b
    4  => "00011100",   -- LOAD 28           ; A ← a              [LOOP]
    5  => "01111101",   -- SUB 29            ; A ← a - b
    6  => "10101110",   -- JZ 14             ; si a==b → DONE
    7  => "11001100",   -- JPOS 12           ; si a>b  → A_GT_B
    8  => "00011101",   -- LOAD 29           ; A ← b              [B_GT_A]
    9  => "01111100",   -- SUB 28            ; A ← b - a
    10 => "00111101",   -- STORE 29          ; M[29] ← nuevo b
    11 => "11000100",   -- JPOS 4            ; → LOOP
    12 => "00111100",   -- STORE 28          ; M[28] ← a-b        [A_GT_B]
    13 => "11000100",   -- JPOS 4            ; → LOOP
    14 => "00011100",   -- LOAD 28           ; A ← GCD            [DONE]
    15 => "11100000",   -- HALT              ; Fin del programa
    OTHERS => "00000000"    -- Resto: datos (M[28]=a, M[29]=b)
  );

  -- Señal interna de la memoria (inicializada con INIT)
  SIGNAL memory : memory_array := INIT;

BEGIN
  -- Proceso de escritura síncrona
  -- Solo escribe en el flanco ascendente del reloj cuando we='1'
  PROCESS(clock)
  BEGIN
    IF clock'EVENT AND clock = '1' THEN
      IF we = '1' THEN
        memory(to_integer(unsigned(address))) <= data;
      END IF;
    END IF;
  END PROCESS;

  -- Lectura combinacional (asíncrona)
  -- Equivalente a lpm_outdata => "UNREGISTERED"
  q <= memory(to_integer(unsigned(address)));

END Behavioral;
