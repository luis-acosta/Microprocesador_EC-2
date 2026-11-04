-- ==========================================================
-- Multiplexor 4:1 Genérico de N bits
-- Estilo: Dataflow (combinatorio — WITH-SELECT)
-- S="00"→D0, S="01"→D1, S="10"→D2, S="11"→D3
-- Instancia en EC-2:
--   U6: Asel MUX (size=8)
--     "00" → RAM[dir]   (instrucción LOAD)
--     "01" → AddSub     (instrucción ADD/SUB)
--     "10" → Input      (instrucción IN)
--     "11" → no usado
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY mux4 IS
  GENERIC(size : INTEGER := 8);    -- Tamaño por defecto: 8 bits
  PORT(
    S              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);           -- Selección (2 bits)
    D3, D2, D1, D0 : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);   -- Entradas de datos
    Y              : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)    -- Salida seleccionada
  );
END mux4;

ARCHITECTURE Dataflow OF mux4 IS
BEGIN
  -- Asignación selectiva concurrente (WITH-SELECT)
  -- Implementa la tabla de verdad del multiplexor 4:1
  WITH S SELECT
    Y <= D0 WHEN "00",   -- S=00: primera entrada
         D1 WHEN "01",   -- S=01: segunda entrada
         D2 WHEN "10",   -- S=10: tercera entrada
         D3 WHEN OTHERS; -- S=11: cuarta entrada (o cualquier otro valor)
END Dataflow;