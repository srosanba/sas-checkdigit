/*----------------------------------------------------------------------------*

*******************************************************
*** Copyright 2006, Rho, Inc.  All rights reserved. ***
*******************************************************

Macro: CheckDigit

Description: 1) Computes check digits for IDs of 1-14 digits, or
             2) validates check digits for IDs of 2-15 digits

Category:       Data management, study set up, QC

Input:          Macro is called from within a data step, with variables
                as specified in PARAMETERS block, below

Output:         Variables as specified in PARAMETERS are populated
                Issues with specific values stored in &returnCodeVar variable
                Overall diagnostic messages are written to the log

Requirements:   Call from within a data step

Parameters:

   &idVar = Name of variable containing digit string for which to
               calculate the check digit.  Should be a character
               variable (numeric will be converted).
               Value should be left-justified and contain no
               non-numeric characters other than trailing spaces.
               Leading zeroes are fine but will not change the
               check digit.
            To GENERATE check digit, may contain 1 to 14 digits
            To VALIDATE, ID may contain 2 to 15 digits with the check
               digit being the last digit

   &switch = Value in call must be either GENERATE or VALIDATE,
                and is not case sensitive

   &checkDigitVar = Name of variable in which to return check digit (the
                       value of the ID variable is NOT modified).  Variable
                       should be numeric; if already defined as character,
                       value will be converted with a log message and may
                       have leading spaces.

   &returnCodeVar = Name of character variable (length 20) created by macro to
                       return status of check digit computation for each row
                       of the dataset.
                    For both GENERATE and VALIDATE, will contain a
                       descriptive message if value in ID is not valid.
                    For GENERATE, will contain 'OK' if generation was successful
                    For VALIDATE, will contain 'OK' if check digit is valid or
                       'Digit Mismatch' if check digit is not valid

                    When creating a check digit, ONLY use the returned check
                       digit when the return code variable contains OK.

References:

Original algorithm documented as coming from:

Gumm, HP.  Data security through check digits.
   Statistical Software Newsletter, 11(1985), 124-127.

Available articles used to support code update:

Gumm, H. Peter. A new class of check-digit methods for arbitrary number systems,
   IEEE Transactions on Information Theory, 31(1985), 102-105.

Gallian, Joseph A. and Steven Winters. Modular Arithmetic in the Marketplace.
   The American Mathematical Monthly, Vol. 95, No. 6(June-July, 1988), 548-551.

********************************************************************************
Examples:

(1) Generate check digits for the following IDs (variable ID). Data set contains
    ID variables as follows:

    ID
  1214185
  5945753
  2622937
  9463928

    %CheckDigit(id, generate, check, flag);

  After the macro call, the dataset would look like the following:

    ID          FLAG         CHECK
  1214185        OK           1
  5945753        OK           5
  2622937        OK           7
  9463928        OK           2


(2) Validate check digits for the following IDs (variable ID). Data set contains
    ID variables as follows:

    ID
  12141851
  59457535
  26229374
  94639282

    %CheckDigit(id, validate, check, flag);

  After the macro call, the dataset would look like the following:

   ID          FLAG             CHECK
  12141851       OK              1
  59457535       OK              5
  26229374       Digit mismatch
  94639282       OK              2

********************************************************************************
Macro history:

Programmer(s)       Date(s)     Brief Description of Modifications

Pam Reading         03DEC1997   Created original macro, algorithm derived from
                                subroutine written by J. Hosking for a project-
                                specific program.
                                Algorithm was modified to match cited reference

Changes include adding _START_ variable to select row of Phi table to use:
   To validate transform using row 0 of Phi table
   To generate, start with rhow 1 of Phi table
Also, validation is performed by seeing if final sum=0 when check digit is
included in the transformation algorithm.

Pam Reading        28June2006   Add to header, clean up error checking, adjust
                                to handle numeric ID values properly, prepare
                                for validation and placement in AUTOCALL

Dave Scocca        26Sep2013    Allowed to handle ID values over 8 characters
                                Significant cleanup to code and header
                                Added additional references and comments
                                Un-commented DROP statement for temp variables
                                Renamed temp variables to avoid collisions
                                Added check for data step

Dave Scocca        21Jan2014    Updated to properly handle numeric IDVAR
********************************************************************************
*/

%macro CheckDigit(idVar, switch, checkDigitVar, returnCodeVar);

   %put  ;
   %put %nrstr(%CheckDigit) => CheckDigit macro executing ;


   %* Verify that macro is called from a data step ;
   %if (%upcase(&sysProcName.) ne DATASTEP) %then %do;
      %put %nrstr(%CheckDigit) => Must be called from a DATA step ;
      %goTo EndOfMacro ;
     %end;

   %* Check for valid generate / validate switch ;
   %let switch=%upcase(&switch.);

   %if (&switch. ne GENERATE) and (&switch. ne VALIDATE) %then %do;
      %put %nrstr(%CheckDigit) => Invalid SWITCH parameter: [&switch.] ;
      %goTo EndOfMacro ;
     %end;

   %* There is no theoretical maximum number of digits for this algorithm ;
   %* The practical maximum is the SAS maximum integer at full precision ;
   %* (above which we would need to use char values rather than num values ;
   %* to store the ID for processing) ;
   %* 15 is the max number of digits where all integers have full precision ;
   %* Limit creation to 14 and validation to 15 ;
   %local maxDigitsForCreation maxDigitsForValidation ;
   %let maxDigitsForCreation=14;
   %let maxDigitsForValidation=15;

   * Assign temporary arrays for transformations ;
   * This represents multiplication on D5, the dihedral group of order 10 ;
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
   * This represents the permutation (0)(14)(23)(58697) ;
   * This is used to weight the digits. ;
   * Was called phi in previous version, sigma in Gallian/Winters paper ;
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
   * Inverse of digit under multiplication table above ;
   array __cd_D5Inverse {0:9} _temporary_
         ( 0 4 3 2 1 5 6 7 8 9 )
      ;

   length &returnCodeVar $20;
   call missing(&returnCodeVar.) ;

   * Convert ID to a numeric value and check validity ;
   * Individual bad ID values will not cause remaining OK ones to fail ;
   length __cd_Input_String $32
          __cd_digitCount __cd_remainingDigits __cd_originalLastDigit 8;

   * Allow numeric ID values, using 32. to avoid scientific notation ;
   * (Implicit SAS conversion uses Best12. and fails above 12 digits) ;
   __cd_Input_String = left(put(&IDVar., 32.)) ;

   __cd_digitCount = length(compress(__cd_Input_String));
   __cd_originalValue = input(compress(__cd_Input_String), ??32.);
   __cd_remainingDigits = __cd_originalValue ;
   __cd_originalLastDigit = mod(__cd_remainingDigits, 10);

   if (__cd_digitCount eq 0) then  &returnCodeVar. = 'Empty ID' ;
   else if (__cd_digitCount gt &maxDigitsForValidation.) then
      &returnCodeVar. = 'ID Too long';
   else if (__cd_originalValue eq .) then
      &returnCodeVar. = 'ID Non-numeric';
   else if (__cd_originalValue ne int(__cd_originalValue)) then
      &returnCodeVar. = 'ID Non-integer';

   if (&returnCodeVar. ne '') then goTo QuitIt;

   %if (&switch. eq GENERATE) %then %do;
      if __cd_digitCount gt &maxDigitsForCreation. then
         &returnCodeVar. = 'ID Too long' ;
      * Set initial row of permutation table for generation ;
      __cd_startIndex=1;
     %end;

   %else %if (&switch. eq VALIDATE) %then %do;
      if __cd_digitCount eq 1 then
         &returnCodeVar. = 'ID Too short' ;
      * Set initial row of permutation table for validation ;
      __cd_startIndex=0;
     %end;

   if (&returnCodeVar. ne '') then goTo QuitIt;
   %* Only set return code here if we are generating ;
   %if &switch eq GENERATE %then %do;
      else &returnCodeVar. = 'OK' ;
     %end;

   __cd_RunningTotal=0;

   * Beginning of loop is dependent on VALIDATE (0) or GENERATE (1) ;
   do __cd_digitIndex = __cd_startIndex to __cd_digitCount ;

      * Working right to left, extract the last digit ;
      __cd_currentDigit = mod(__cd_remainingDigits, 10) ;

      * Drop the last digit for the next iteration ;
      __cd_remainingDigits = int(__cd_remainingDigits/10) ;

      * Apply the next permutation to the digit ;
      __cd_PermutedDigit =
          __cd_Permutation{mod(__cd_digitIndex, 10), __cd_currentDigit} ;

      * Perform D5 multiplication of permited digit with running total ;
      __cd_RunningTotal =
         __cd_D5Multiply{__cd_PermutedDigit, __cd_RunningTotal} ;
     end;

   * Take the inverse of the final product under D5 multiplication ;
   __cd_GeneratedCheckDigit = __cd_D5Inverse{__cd_RunningTotal} ;

   %* If validating, compare and set return code ;
   %if (&switch. eq VALIDATE) %then %do;
      if (__cd_RunningTotal eq 0) then do ;
         &returnCodeVar. = 'OK';
         &checkDigitVar. = __cd_originalLastDigit;
        end;
      else do ;
         &returnCodeVar. = 'Digit mismatch';
         call missing(&checkDigitVar.) ;
        end ;
     %end;
   %* If generating, store result in requested variable ;
   %else %if (&switch. eq GENERATE) %then %do;
      &checkDigitVar. = __cd_GeneratedCheckDigit;
     %end;

   drop
      __cd_Input_String
      __cd_originalValue
      __cd_originalLastDigit
      __cd_digitCount
      __cd_remainingDigits
      __cd_startIndex
      __cd_RunningTotal
      __cd_digitIndex
      __cd_currentDigit
      __cd_PermutedDigit
      __cd_GeneratedCheckDigit ;

   QuitIt:
   if (&returnCodeVar. ne 'OK')  then do;
      if (&returnCodeVar. eq 'Digit mismatch') then
         put 'NO' 'TE: Check Digit did not validate for ID value: '
            __cd_originalValue Best32. ;
      else
         put 'WAR' 'NING: CheckDigit macro detected problems for ID value: '
            __cd_originalValue Best32. / &returnCodeVar.;
     end;

   %EndOfMacro:
   %put  ;

  %mEnd CheckDigit;



