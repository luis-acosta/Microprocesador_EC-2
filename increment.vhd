-- ==========================================================
-- Incrementador Genérico de N bits (F = A + 1)
-- Estilo: Dataflow (combinatorio — asignación concurrente)
-- Instancia en EC-2:
--   U4: increment (size=5) — calcula PC + 1
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY increment IS
  GENERIC(size : INTEGER := 8);    -- Tamaño por defecto: 8 bits
  PORT(
    A : IN  STD_LOGIC_VECTOR(size-1 DOWNTO 0);  -- Valor a incrementar
    F : OUT STD_LOGIC_VECTOR(size-1 DOWNTO 0)   -- Resultado: A + 1
  );
END increment;

ARCHITECTURE Dataflow OF increment IS
BEGIN
  -- Asignación concurrente: suma aritmética A + 1
  -- unsigned() convierte STD_LOGIC_VECTOR para operar con +
  -- std_logic_vector() convierte el resultado de vuelta
  F <= std_logic_vector(unsigned(A) + 1);
END Dataflow;