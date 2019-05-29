
/*********************************************************************************/
/*                                                                               */
/*  Macro: PRD05_get_assay_results.sas                                           */
/*                                                                               */
/*  Creation Date: 21OCT2016                                                     */
/*                                                                               */
/*  Primary client: LDO                                                          */
/*                                                                               */
/*  Purpose: Import flat-files into SAS based on the assay/version               */
/*           specifications and identify unexpected header values or problems    */
/*           reading data in to SAS                                              */
/*           Created for processing PRD (Product Concentration)                  */
/*           File Format #05 data                                                */
/*                                                                               */
/*  Location: /common/code/sas/sasmacro/assay_processing/assay_code/PRD          */
/*                                                                               */
/*  Author: Katie Snapinn                                                        */
/*                                                                               */
/*  Project: HPTN/MTN Assay Processing                                           */
/*           SCHARP - Fred Hutchinson Cancer Research Center                     */
/*                                                                               */
/*  Parameters:                                                                  */
/*     network: The network for the assay data                                   */
/*     protocol: The protocol for the assay data                                 */
/*     file_name_orig: The full name of the file as read from the file system    */
/*     file_name_clean: The cleaned up version of file_name_orig (extra spaces   */
/*                      and file extension removed, etc)                         */
/*     file_subno: The number of times this file_name_clean has been submitted   */
/*     file_dir: The directory location of the file                              */
/*     labid: The ID of the lab submitting the file                              */
/*     ldms_ds: The dataset of LDMS data for the network/protocol                */
/*     out_ds_err: A dataset to save with all header and data input errors       */
/*     out_ds_all: A dataset to save with all of the data from the file          */
/*                                                                               */
/*  Inputs:                                                                      */
/*     Files:                                                                    */
/*        &file_dir./&file_name_orig.: The name and location of the file to read */
/*                                                                               */
/*  Outputs:                                                                     */
/*     Datasets:                                                                 */
/*        &out_ds_err.: A dataset to save with all header and data input errors  */
/*        &out_ds_all.: A dataset to save with all of the data from the file     */
/*                                                                               */
/*  Required Code:                                                               */
/*     /common/code/sas/sasmacro/check_header.sas                                */
/*     /common/code/sas/sasmacro/check_macro_parameters.sas                      */
/*     /common/code/sas/sasmacro/get_delimiter.sas                               */
/*     /common/code/sas/sasmacro/dos_2_unix.sas                                  */
/*     /common/code/sas/sasmacro/assay_processing/attrib_std_vars_assay.sas      */
/*                                                                               */
/*  Usage: %PRD05_get_assay_results(network=test, protocol=999,                  */
/*         file_name_orig=test_data_a.txt, file_name_clean=test_data,            */
/*         file_subno=1, file_dir=/testdir/incoming, labid=XX, out_ds_err=err,   */
/*         out_ds_all=raw)                                                       */
/*                                                                               */
/*  Special Notes:                                                               */
/*                                                                               */
/*                                                                               */
/*********************************************************************************/
/*                                                                               */
/*  Revision History (date: initials - description)                              */
/*                                                                               */
/*                                                                               */
/*********************************************************************************/


%macro PRD05_get_assay_results(network=, protocol=, file_name_orig=, file_name_clean=,
                               file_subno=, file_dir=, labid=, ldms_ds=,
                               out_ds_err=, out_ds_all=);

   %local val_assay val_assay_fmt file delim;
   %let file=&file_dir./&file_name_orig.;

   /*-----------------------------------*/
   /* Set assay file format information */
   /*-----------------------------------*/

   %let val_assay = PRD;
   %let val_assay_fmt = 05;


   /*-----------------------------*/
   /* Get the file delimiter type */
   /*-----------------------------*/

   %let delim=%get_delimiter(&file.);
   %if &delim= %then %do;
      %put ERROR: The SAS delimiter type for the file "&file." could not be assigned.;
      %put ERROR- The file was not run through the get assay results macro.;
   %end;
   %else %do;

      /*-----------------------*/
      /* Check the file header */
      /*-----------------------*/

      /* Delete the header_errors dataset if it already exists */
      proc datasets ddname=work;
         delete header_errors;
      run;

      /* Check the file header */
      /* Remove spaces from expected column header text */
      /* Separate each expected column header value with a space */
      %check_header(header = STUDY_ID GUSPEC RESIDUAL_DRUG UNITS BATCH_ID REPORTING_PERIOD TEST_DATE CENSORS COMMENTS,
                    file = &file.,
                    header_row = 1,
                    checkremainder = 1,
                    out_ds = header_errors)


      /*---------------------------------------------------------------------*/
      /* Remove MAC/DOS end-of-line characters from the file for use in Unix */
      /*---------------------------------------------------------------------*/

      %dos_2_unix(convfile = &file.)


      /*----------------------------*/
      /* Read in the raw assay data */
      /*----------------------------*/

      data &out_ds_all. (drop=infile_value)
           input_errors (keep=infile_value recnum);

         /*** Create standard variables that must be in all datasets (can be null) ***/
         /*--------------------------------------------------------------------------*/
         %attrib_std_vars_assay
         /* Initialize all values to missing */
         if _N_ = 1 then call missing(of _all_);

         /* Cant initialize to a value because of the call missing above */
         retain recnum;

         /* Set assay-specific variables and attributes */
         /*---------------------------------------------*/
         attrib
            concc            length=$20  label = "Drug concentration"
            conc             length=8    label = "Drug concentration" format=std_miss.
            concunit         length=$20  label = "Drug concentration units"
            runid            length=$20  label = "Run ID"
            reportdtc        length=$20  label = "Reporting Date"
            reportdt         length=8    label = "Reporting Date" format=date9.
            assaydtc         length=$20  label = "Assay Date"
            assaydt          length=8    label = "Assay Date" format=date9.
            censor           length=$20  label = "Censor code"
            drug             length=$20  label = "Drug"
            volume           length=8    label = "Sample Volume from LDMS"
            volstr           length=$5   label = "Sample Volume Unit from LDMS"
            control_required length=8    label = "Is a matching control result required? 1=Yes, Otherwise No"
         ;

         /* Specify the file to input */
         /*---------------------------*/
         infile "&file." lrecl=1000 dsd dlm=&delim. truncover firstobs=2;

         /* Read in the file */
         /*------------------*/
         input prot guspec1 concc concunit runid reportdtc assaydtc censor comments1 blank_col;

         /* Delete records where all input values are missing  */
         /* Except for recnum, which we expect to have a value */
         /* (ignoring data read in errors)                     */
         /*----------------------------------------------------*/
         if _ERROR_ ne 1 then do;
            array nn {*} _NUMERIC_;
            array cc {*} _CHARACTER_;
            drop tmp_count_tot tmp_count_miss;
            tmp_count_tot = dim(nn) + dim(cc) + 2;
            tmp_count_miss = 0;
            tmp_count_miss = cmiss(of _all_);
            /* Ignore that there are values in recnum, tmp_count_tot, and tmp_count_miss */
            if (tmp_count_miss + 3) < tmp_count_tot;
         end;

         /* Set the row the data is from */
         /* Start as 1st row of data     */
         /*------------------------------*/
         if _n_ = 1 then recnum = 2;
         else recnum + 1;

         /* Set meta information about the file */
         /*-------------------------------------*/
         network_fn = "&network.";
         protocol_fn = "&protocol.";
         labid_fn = "&labid.";
         labfile = "&file_name_orig.";
         labfilecln = "&file_name_clean.";
         labfilesub = &file_subno.;
         labid = labid_fn;
         assay = "&val_assay.";
         file_format_version = "&val_assay_fmt.";
         filedate = today();
         filetime = time();

         /* Set the network and protocol */
         /*------------------------------*/
         %input_prot(combo_var=prot, network_var=network, protocol_var=protocol)

         /* Clean standard variables */
         /*--------------------------*/
         %clean_network(network_var=network)
         %clean_protocol(protocol_var=protocol)
         %clean_guspec(orig_var=guspec1, clean_var=guspec)
         %clean_comments(orig_var=comments1, short_var=comments)

         /* Input and clean assay-specific variables */
         /*------------------------------------------*/

         /* Put the concentration in a numeric variable */
         /* Ignoring errors if it could not be added    */
         /* Set the missing value code */
         /* if the censor gave additional information about why a value was missing */
         censor = upcase(censor);
         conc = input(strip(concc), ??comma10.);
         if find(censor, "Z") then ignore_record = 1;

         /* Input the assay date */
         %input_date(var_list=reportdt assaydt)

         /* Note that matching control results are required for these results */
         control_required = 1;

         /* Flag these records as experimental */
         non_experimental = 0;

         /* Output any data input errors encountered */
         /*------------------------------------------*/
         infile_value = _INFILE_;
         if _ERROR_ ne 0 then output input_errors;

         /* Output the data */
         /*-----------------*/
         output &out_ds_all.;
      run;


      /*----------------------------------------------------------------*/
      /* Look up participant information from LDMS for each specimen ID */
      /*----------------------------------------------------------------*/

      %add_miss_value(miss_dataset=&out_ds_all.,
                      miss_vars=ptid visitno spcdt spctm addtim addunt primstr addstr dervst2 sec_typ sec_id volume volstr,
                      search_vars=guspec,
                      source_dataset=&ldms_ds.)


      /*----------------------------------------------------------*/
      /* Set the specimen code based on the information from LDMS */
      /*----------------------------------------------------------*/

      data &out_ds_all.;
         set &out_ds_all.;

         /* Set the CRF-style visit number */
         %input_visit_df(ldms_var=visitno, df_var=visit)

         /* Set the pk timepoint and timepoint unit */
         if addtim >=0 then pk_tp = addtim;
         if addunt ne "-2" then pkucode = input(input(strip(upcase(addunt)), ??$inpkunits.), ??best.);

         /* Clean up the specimen codes */
         primstr=upcase(primstr);
         addstr=upcase(addstr);
         dervst2=upcase(dervst2);
         sec_typ=upcase(sec_typ);
         sec_id=upcase(sec_id);
         /* Set the specimen type (for error displays) */
         spectype = strip(primstr) || "/" || strip(addstr) || "/" || strip(dervst2) || "/" || strip(sec_typ);
         /* Make the primary, aliqut, purpose, and spcode specimen codes */
         %set_spcodes_from_ldmscodes
      run;


      /*------------------------------------------*/
      /* Compile the header and data input errors */
      /*------------------------------------------*/

      data &out_ds_err. (keep=err_type err_msg recnum);

         attrib err_type length=$10
                err_msg length=$500
                recnum length=8;

         set header_errors (in=a)
             input_errors (in=b);

         if a then do;
            /* List the header errors */
            err_type = "HEADER";
            err_msg = "Column: " || strip(put(column, best.)) || " Required: '" || strip(required_header) || "' Actual: '" || strip(actual_header) || "'";
            recnum = row;
         end;
         else if b then do;
            /* List data input errors */
            err_type = "INPUT";
            err_msg = infile_value;
         end;
      run;
   %end;

%mend PRD05_get_assay_results;


***** End of Program *****;
