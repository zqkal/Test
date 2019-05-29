
/*********************************************************************************/
/*                                                                               */
/*  Macro: check_header.sas                                                      */
/*                                                                               */
/*  Creation Date: 26FEB2014                                                     */
/*                                                                               */
/*  Primary client: LDO                                                          */
/*                                                                               */
/*  Purpose: Compare the values in the header of a file with the expected header */
/*           values to see if they match                                         */
/*                                                                               */
/*  Location: /common/code/sas/sasmacro                                          */
/*                                                                               */
/*  Author: Katie Snapinn                                                        */
/*                                                                               */
/*  Project: Across protocols and networks                                       */
/*           SCHARP                                                              */
/*           Fred Hutchinson Cancer Research Center                              */
/*                                                                               */
/*  Parameters:                                                                  */
/*     header_row (optional): An integer indicating the row the header           */
/*        information is contained in. If not provided, it is defaulted to 1.    */
/*     header: The expected header column text with the spaces, percent signs    */
/*     and ampersands (&) removed                                                */
/*        (e.g. collection date = COLLECTIONDATE). Column header values should   */
/*        be separated by spaces.                                                */
/*     file: The flat file whose header values need to be checked                */
/*     out_ds: The dataset to which header errors are written                    */
/*             (default = header_errors)                                         */
/*     checkremainder: When 1, an error will be noted if any headers are found   */
/*             beyond the supplied list of headers (default). When 0, extra      */
/*             headers are ignored.                                              */
/*  Inputs:                                                                      */
/*     Files:                                                                    */
/*        &file.: The file whose header values need to be checked                */
/*                                                                               */
/*  Outputs:                                                                     */
/*     Global Macro Variables:                                                   */
/*        header_error: 0=No Header Errors, 1=Header Errors                      */
/*                                                                               */
/*  Required Code: i.e. code to include before calling this macro                */
/*     /common/code/sas/sasmacro/check_macro_parameters.sas                      */
/*     /common/code/sas/sasmacro/get_delimiter.sas                               */
/*     /common/code/sas/sasmacro/dos_2_unix.sas                                  */
/*                                                                               */
/*  Usage: %check_header(header_row=, header=, file=, out_ds=, checkremainder=)  */
/*  Usage Example:                                                               */
/*     %check_header(header_row=2,                                               */
/*                   header=ABC DEF GH IJK L,                                    */
/*                   file=trials/testdir/test.txt)                               */
/*                                                                               */
/*  Special Notes:                                                               */
/*     This macro may not work as expected if the header within the file spans   */
/*      multiple rows                                                            */
/*                                                                               */
/*********************************************************************************/
/*                                                                               */
/*  Revision History (date: initials - description)                              */
/*                                                                               */
/*                                                                               */
/*********************************************************************************/

%macro check_header(header_row=1, header=, file=, out_ds=header_errors, checkremainder=1);

   /*-----------------------------------------------------------*/
   /* Ensure the required arguments were provided and are valid */
   /*-----------------------------------------------------------*/

   /* cant require file to have a single value since file names can technically include spaces */
   %check_macro_parameters(required_parameters = header file,
                           single_value_parameters = header_row,
                           invalid_flag = invalid_parameter)

   /* Check that the header_row parameter is an integer greater than 0 */
   %if %length(&header_row.) ne 0 %then %do;
      %if %sysfunc(compress("&header_row.", 0123456789)) ne "" %then %do;
         %put ERROR: The header_row parameter must be a positive integer. Value provided: "&header_row.";
         %let invalid_parameter = 1;
      %end;
      %else %if &header_row. < 1 %then %do;
         %put ERROR: The header_row parameter can not be zero.;
         %let invalid_parameter = 1;
      %end;
   %end;

   %if &invalid_parameter. = 1 %then %do;
      %put There was an issue with one or more arguments. The macro was not run.;
   %end;
   %else %do;

      /*--------------------------*/
      /* Upcase the header values */
      /*--------------------------*/

      %let header = %upcase(&header.);

      /*-----------------------------------------*/
      /* Check the header column values in &file */
      /*-----------------------------------------*/

      %if %sysfunc(fileexist("&file.")) %then %do;
         %local delim;
         %let delim = %get_delimiter(&file.);

         %if &delim ne %then %do;

	         %dos_2_unix(convfile = &file.)

            %global header_error;
            %if &checkremainder. = 1 %then %do;
               %let header = &header. REMAINDERSHOULDBEBLANK;
            %end;

            /* Turns off length of quote error for this data step         */
            /* In case the header value is very long and throws a warning */
            %local quoteoptionorigvalue;
            %let quoteoptionorigvalue = %sysfunc(getoption(quotelenmax));
            options noquotelenmax;
            
            data &out_ds.(drop=any_error);
               infile "&file." lrecl=1000 dsd dlm=&delim. truncover firstobs=&header_row. obs=&header_row.;
               attrib file length=$100
                      row length=8
                      column length=8
                      required_header length=$60
                      actual_header length=$60
                      actual_header_clean length=$60
               ;
               file = "&file.";
               row = &header_row.;
               column = 1;
               any_error = 0;
               do while (column le countw("&header.", " "));
                  required_header=scan("&header.", column, " ");
                  required_header=compress(required_header, "'%&().?/");
                  input actual_header @;
                  actual_header = trim(actual_header);
                  actual_header_clean = upcase(compress(actual_header));
                  actual_header_clean = compress(actual_header_clean, "'%&().?/"); /* Omits ', %, and & signs from the header */
                  if actual_header_clean ne required_header then do;
                     if not (actual_header_clean in ("COMMENT", "COMMENTS") and required_header in ("COMMENT", "COMMENTS")) 
                     and not (missing(actual_header) and required_header="REMAINDERSHOULDBEBLANK") then do;
                        output;
                        any_error = 1;
                     end;
                  end;
                  column + 1;
               end;
               if any_error = 1 then do;
                  call symputx("header_error", 1);
                  put "NOTE: The columns are in an inproper order or improperly named in the file: '&file.'. See the &out_ds. dataset for the problem fields.";
               end;
               else do;
                  call symputx("header_error", 0);
               end;
            run;

            /* Turns back on quote length errors */
            options &quoteoptionorigvalue.;
         %end;
         %else %do;
            %put ERROR: The SAS delimiter type for the file "&file." could not be assigned. Therefore the header could not be checked.;
         %end;
      %end;
      %else %do;
         %put ERROR: The file "&file." does not exist. Therefore the header could not be checked.;
      %end;

   %end;

%mend check_header;


/***** End of Program *****/
