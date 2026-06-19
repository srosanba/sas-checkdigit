/*--------------------------------------------------------------------------*
 * Gumm/Verhoeff check-digit GENERATION.
 *
 * The lookup tables and the generation loop below are taken directly from
 * CheckDigit.sas in this repository (the D5 dihedral multiplication table,
 * the digit-weighting permutation table, and the multiplicative inverse
 * table), with the algorithm called inline from a single DATA step rather
 * than through the %CheckDigit macro wrapper.
 *
 * Input IDs and their expected check digits are the worked example from
 * the repository README (Example 1):
 *     1214185 -> 1     5945753 -> 5     2622937 -> 7     9463928 -> 2
 *--------------------------------------------------------------------------*/

data subjid;
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
   * Inverse of each digit under the D5 multiplication table (from CheckDigit.sas) ;
   array __cd_D5Inverse {0:9} _temporary_
         ( 0 4 3 2 1 5 6 7 8 9 )
      ;

   length __cd_remainingDigits __cd_RunningTotal __cd_digitCount 8;
   __cd_digitCount      = length(compress(put(id, 32.)));
   __cd_remainingDigits = id;
   __cd_RunningTotal    = 0;

   * Generation begins at row 1 of the permutation table ;
   do __cd_digitIndex = 1 to __cd_digitCount;
      * Working right to left, extract the last digit ;
      __cd_currentDigit    = mod(__cd_remainingDigits, 10);
      * Drop the last digit for the next iteration ;
      __cd_remainingDigits = int(__cd_remainingDigits / 10);
      * Apply the next permutation to the digit ;
      __cd_PermutedDigit   =
         __cd_Permutation{mod(__cd_digitIndex, 10), __cd_currentDigit};
      * D5-multiply the permuted digit into the running total ;
      __cd_RunningTotal    =
         __cd_D5Multiply{__cd_PermutedDigit, __cd_RunningTotal};
   end;

   * The check digit is the inverse of the final product under D5 multiplication ;
   cd = __cd_D5Inverse{__cd_RunningTotal};

   length subjid $16;
   subjid = cats(put(id, 32.), put(cd, 1.));

   keep id cd subjid;
datalines;
1214185
5945753
2622937
9463928
;
run;

proc print data=subjid noobs;
   var id cd subjid;
run;
