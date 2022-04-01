library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package data_types is
    type array_of_integers is array(natural range <>) of integer;
end package;