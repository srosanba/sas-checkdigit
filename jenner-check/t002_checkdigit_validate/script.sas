/*--------------------------------------------------------------------------*
 * Gumm/Verhoeff check-digit VALIDATION.
 *
 * The lookup tables and the validation loop below are taken directly from
 * CheckDigit.sas in this repository. Validation differs from generation in
 * two ways documented in the macro header: the digit walk starts at row 0
 * of the permutation table (so the trailing check digit is included), and
 * the ID is valid when the final D5 product is 0.
 *
 * The README leaves VALIDATE "as an exercise for the reader"; this is that
 * exercise, driven by the worked example from the README (Example 2):
 *     12141851 -> OK     59457535 -> OK
 *     26229374 -> Digit mismatch     94639282 -> OK
 *--------------------------------------------------------------------------*/

data validated;
   input id;

   * D5 multiplication on the dihedral group of order 10 (from CheckDigit.sas) ;
   array __cd_D5Multiply {0:9, 0:9} _temporary_
         ( 0 1 2 3 4 5 6 7 8 9
           1 2 3 4 0 6 7 8 9 5
           2 3 4 0 1 7 8 9 5 6
           3 4 0 1 2 8 9 5 6 7
           4 0 1 2 3 9 5 6 7 8
           5 9 8 7 6 0 4 3 2 1
           6 5 9 8 7 1 0 4 3 2
           7 6 5 9 8 2 1 0 4 3
           8 7 6 5 9 3 2 1 0 4
           9 8 7 6 5 4 3 2 1 0 )
           ;
   * Permutation (0)(14)(23)(58697) used to weight the digits (from CheckDigit.sas) ;
   array __cd_Permutation {0:9, 0:9} _temporary_
         ( 0 1 2 3 4 5 6 7 8 9
           0 4 3 2 1 8 9 5 6 7
           0 1 2 3 4 6 7 8 9 5
           0 4 3 2 1 9 5 6 7 8
           0 1 2 3 4 7 8 9 5 6
           0 4 3 2 1 5 6 7 8 9
           0 1 2 3 4 8 9 5 6 7
           0 4 3 2 1 6 7 8 9 5
           0 1 2 3 4 9 5 6 7 8
           0 4 3 2 1 7 8 9 5 6 )
           ;

   length __cd_remainingDigits __cd_RunningTotal __cd_digitCount 8;
   __cd_digitCount      = length(compress(put(id, 32.)));
   __cd_remainingDigits = id;
   __cd_RunningTotal    = 0;

   * Validation begins at row 0 of the permutation table so the check digit
   * is folded into the transformation ;
   do __cd_digitIndex = 0 to __cd_digitCount;
      __cd_currentDigit    = mod(__cd_remainingDigits, 10);
      __cd_remainingDigits = int(__cd_remainingDigits / 10);
      __cd_PermutedDigit   =
         __cd_Permutation{mod(__cd_digitIndex, 10), __cd_currentDigit};
      __cd_RunningTotal    =
         __cd_D5Multiply{__cd_PermutedDigit, __cd_RunningTotal};
   end;

   * A valid ID drives the final running total to 0 ;
   length rc $14;
   if __cd_RunningTotal eq 0 then rc = 'OK';
   else rc = 'Digit mismatch';

   keep id rc;
datalines;
12141851
59457535
26229374
94639282
;
run;

proc print data=validated noobs;
   var id rc;
run;
