
/*********************************************************************************/
/*                                                                               */
/*  Macro: get_delimiter.sas                                                     */
/*                                                                               */
/*  Creation Date: 26FEB2014                                                     */
/*                                                                               */
/*  Primary client: LDO                                                          */
/*                                                                               */
/*  Purpose: Determine the appropriate SAS delimiter type for a specified file   */
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
/*     file: The file (including extension) whose sas delimiter type needs to be */
/*           determined                                                          */
/*                                                                               */
/*  Inputs:                                                                      */
/*     None                                                                      */
/*                                                                               */
/*  Outputs:                                                                     */
/*     Global Macro Variables:                                                   */
/*        delim: The sas delimiter type of the file                              */
/*                                                                               */
/*  Required Code: i.e. code to include before calling this macro                */
/*     /common/code/sas/sasmacro/check_macro_parameters.sas                      */
/*                                                                               */
/*  Usage: %get_delimiter()                                                      */
/*  Usage Example:                                                               */
/*     %get_delimiter(trials/testdir/test.txt)                                   */
/*                                                                               */
/*  Special Notes:                                                               */
/*                                                                               */
/*********************************************************************************/
/*                                                                               */
/*  Revision History (date: initials - description)                              */
/*                                                                               */
/*                                                                               */
/*********************************************************************************/

%macro get_delimiter(file);

   /*-----------------------------------------------------------*/
   /* ENSURE THE REQUIRED ARGUMENTS WERE PROVIDED AND ARE VALID */
   /*-----------------------------------------------------------*/

   /* File names can technically include spaces, so dont require single-value  */
   %check_macro_parameters(required_parameters=file,
                           invalid_flag=invalid_parameter)

   %if &invalid_parameter.=1 %then %do;
      %put There was an issue with one or more arguments. The macro was not run.;
   %end;
   %else %do;

      /*-----------------------------------------*/
      /* GET THE SAS DELIMITER TYPE FOR THE FILE */
      /*-----------------------------------------*/

      %local extension;
      %let extension=%upcase(%sysfunc(scan(&file.,-1,.)));
   
      %if &extension.=TXT or &extension.=TTX %then %do;
         '09'x
      %end;
      %else %if &extension.=CSV %then %do;
         ','
      %end;
      %else %do;
         %put NOTE: The SAS delimiter type of file "&file." could not be assigned.;
         %str()
      %end;

   %end;

%mend get_delimiter;


/***** End of Program *****/
