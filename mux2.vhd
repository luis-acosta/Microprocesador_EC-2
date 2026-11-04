-- ==========================================================
-- Multiplexor 2:1 Genérico de N bits
-- Estilo: Dataflow (combinatorio — asignación condicional)
-- S='0' → Y=D0,  S='1' → Y=D1
-- Instancias en EC-2:
--   U1: JMPmux   (size=5) — PC+1 o dirección de salto
--   U3: Meminst  (size=5) — dirección PC o del operando
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY mux2 IS
  GENERIC(size : INTEGER := 8);    -- Tamaño por defecto: 8 bits
  PORT(
    S      : IN  STD_LOGIC;                              -- Línea de selección
    D1, D0 : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);   -- Entradas de datos
    Y      : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)    -- Salida seleccionada
  );
END mux2;

ARCHITECTURE Dataflow OF mux2 IS
BEGIN
  -- Asignación condicional concurrente (WHEN-ELSE)
  -- Implementa la tabla de verdad del multiplexor 2:1:
  --   S=0 → Y recibe D0 (primera entrada)
  --   S=1 → Y recibe D1 (segunda entrada)
  Y <= D1 WHEN S = '1' ELSE
       D0;
END Dataflow;