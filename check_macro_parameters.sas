
/*********************************************************************************/
/*                                                                               */
/*  Macro: check_macro_parameters.sas                                            */
/*                                                                               */
/*  Creation Date: 26FEB2014                                                     */
/*                                                                               */
/*  Primary client: LDO                                                          */
/*                                                                               */
/*  Purpose: To be used by sas macros that have input parameters to ensure that  */
/*           required parameters were provided and/or any provided paramater     */
/*           that can only include one value only included one value             */
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
/*     required_parameters (optional): The parameters that can not be null       */
/*     single_value_parameters (optional): The parameters that can only contain  */
/*        one value (i.e. parameters that can not include spaces)                */
/*     invalid_flag (optional): The macro variable to store the results of the   */
/*        check in                                                               */
/*                                                                               */
/*  Inputs:                                                                      */
/*     None                                                                      */
/*                                                                               */
/*  Outputs:                                                                     */
/*     Global Macro Variables:                                                   */
/*        &invalid_flag: 0=No Invalid Parameters, 1=Invalid Parameters           */
/*                                                                               */
/*  Required Code: i.e. code to include before calling this macro                */
/*     None                                                                      */
/*                                                                               */
/*  Usage: %check_macro_parameters(required_parameters=,                         */
/*                                 single_value_parameters=,                     */
/*                                 invalid_flag=)                                */
/*  Usage Example:                                                               */
/*     %check_macro_parameters(required_parameters=search,                       */
/*                             single_value_parameters=out_ds,                   */
/*                             invalid_flag=invalid_parameter)                   */
/*                                                                               */
/*  Special Notes:                                                               */
/*     This macro will not work if the variable provided for invalid_flag has    */
/*     already been assigned as a global macro variable                          */
/*                                                                               */
/*********************************************************************************/
/*                                                                               */
/*  Revision History (date: initials - description)                              */
/*                                                                               */
/*                                                                               */
/*********************************************************************************/

%macro check_macro_parameters(required_parameters=, single_value_parameters=, invalid_flag=invalid_parameter);

   %local i current_parameter;
   %global &invalid_flag.;
   %let &invalid_flag.=0;

   /*-------------------------------------------------*/
   /* Check for missing values in required parameters */
   /*-------------------------------------------------*/
   %let current_parameter=;
   %do i=1 %to %sysfunc(countw("&required_parameters.", " "));
      %let current_parameter=%scan(&required_parameters., &i., " ");
      %if %length(&&&current_parameter.)=0 %then %do;
         %put ERROR: You must provide the "&current_parameter." parameter.;
         %let &invalid_flag.=1;
      %end;
   %end;

   /*--------------------------------------------------------------*/
   /* Check for more than one value in the single-value parameters */
   /*--------------------------------------------------------------*/
   %let current_parameter=;
   %do i=1 %to %sysfunc(countw("&single_value_parameters.", " "));
      %let current_parameter=%scan(&single_value_parameters., &i., " ");
      %if %sysfunc(countw("&&&current_parameter.", " "))>1 %then %do;
         %put ERROR: Please provide just one "&current_parameter." parameter. Values provided: "&&&current_parameter.";
         %let &invalid_flag.=1;
      %end;
   %end;

%mend check_macro_parameters;


/***** End of Program *****/
