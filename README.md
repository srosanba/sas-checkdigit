The Gumm/Verhoeff check digit algorithm adds one extra digit to a number so that:
* If you mistype one digit, it's detected
* If you swap two neighboring digits (like 23 -> 32), it's detected

This repository contains a SAS macro (checkdigit.sas) that implements the Gumm/Verhoeff algorith. It also contains an example calling program (run_checkdigit.sas). The macro has 2 modes: check digit generation (ie, adding a check digit to an ID) and check digit validation (ie, checking that the last digit of an ID is correct given the digits that preceed it).
