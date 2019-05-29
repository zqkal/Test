/*****************************************************************************/
/*                                                                           */
/* Macro : dos_2_unix.sas                                                    */
/*                                                                           */
/* Creation Date: 26May2010                                                  */
/*                                                                           */
/* Primary client: Various text file processing programs                     */
/*                                                                           */
/* Purpose: Converts text files with cr-lf (DOS/Windows) to lf only (Unix).  */
/*                                                                           */
/* Location: /common/code/sas/sasmacro                                       */
/*                                                                           */
/* Author: Cindy Molitor                                                     */
/*                                                                           */
/* Project : Across protocols                                                */
/*           Fred Hutchinson Cancer Research Center                          */
/*                                                                           */
/* Inputs:                                                                   */
/*     - raw files:                                                          */
/*     - SAS datasets:                                                       */
/*                                                                           */
/* Outputs:                                                                  */
/*     - raw files:                                                          */
/*     - SAS datasets:                                                       */
/*     - formats:                                                            */
/*                                                                           */
/* Usage: %dos_2_unix(convfile=<file to process>);                           */
/*                                                                           */
/* SPECIAL NOTES:                                                            */
/*    This assumes that the dir_base_code macro variable exists and          */
/*    specifies the top level folder for the project. The mydos2unix program */
/*    must reside in the common/code/unix-perl sub-folder of the project.    */
/*                                                                           */
/* Revisions:                                                                */
/*     02JAN14 - KWS added quotes around convfile to have the call work with */
/*               files that either have spaces in their names or their       */
/*               directory path                                              */
/*                                                                           */
/*****************************************************************************/

%macro dos_2_unix(convfile=);

   /* Temporarily turn off quote length warning */
   /* In case the system call is long and throws a warning */
   %local quoteoptionorigvalue;
   %let quoteoptionorigvalue = %sysfunc(getoption(quotelenmax));
   options noquotelenmax;

    data _null_;
        call system("&dir_base_code./common/code/unix-perl/mydos2unix '&convfile'");
    run;

   /* Return the quote length warning option back to its original value */
   options &quoteoptionorigvalue.;

%mend dos_2_unix;

/***** End of Macro *****/
