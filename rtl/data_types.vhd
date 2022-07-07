library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package data_types is
    type array_of_integers           is array(natural range <>) of integer;
    type array_of_signed             is array(natural range <>) of signed(24 downto 0);
    type array_of_std_logic_vector   is array(natural range <>) of std_logic_vector(23 downto 0);
end package;