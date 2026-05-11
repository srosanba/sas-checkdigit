The Gumm (1985) / Verhoeff check digit algorithm adds an extra digit to a number to help detect common data-entry errors:

- Single-digit errors (e.g., mistyping one digit)
- Adjacent transpositions (e.g., `23 → 32`)

This repository provides a SAS macro (`checkdigit.sas`) that implements the Gumm/Verhoeff algorithm, along with an example driver program (`run_checkdigit.sas`).

The macro supports two modes:
- **Check digit generation**: Appends a valid check digit to a numeric ID (depicted in the driver program)
- **Check digit validation**: Verifies that the final digit of an ID is consistent with the preceding digits (left as an exercise for the reader)
