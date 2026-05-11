*--- path where YOUR copy of the macro has been saved ---;

%include "H:\GitHub\srosanba\sas-checkdigit\checkdigit.sas";

*--- list of numeric values (without check digits) ---;

data preid;
   do i = 1001 to 1200;
      preid = put(i,4.);
      output;
   end;
   keep preid;
run;

*--- create SUBJID by adding a check digit to PREID ---;

data subjid;
   set preid;
   %checkdigit(preid,generate,cd,rc);
   length subjid $5;
   subjid = cats(preid,cd);
run;

