
/*********************************************************************************/

/*  Macro: PRD07_get_assay_results.sas                                           */
/*                                                                               */
/*  Creation Date: 04APR2019                                                     */
/*                                                                               */
/*  Primary client: LDO                                                          */
/*                                                                               */
/*  Purpose: Import flat-files into SAS based on the assay/version               */
/*           specifications and identify unexpected header values or problems    */
/*           reading data in to SAS                                              */
/*           Created for processing PRD (Product Concentration)                  */
/*           File Format #07 data                                                */
/*                                                                               */
/*  Location: /common/code/sas/sasmacro/assay_processing/assay_code/PRD          */
/*                                                                               */
/*  Author: Kalkidan Lebeta                                                      */
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
/*  Usage: %PRD07_get_assay_results(network=test, protocol=999,                  */
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

%include "/devel/klebeta/LDP-524/common/code/sas/sasmacro/check_header.sas";
%include "/devel/klebeta/LDP-524/common/code/sas/sasmacro/check_macro_parameters.sas";
%include "/devel/klebeta/LDP-524/common/code/sas/sasmacro/get_delimiter.sas";
%include "/devel/klebeta/LDP-524/common/code/sas/sasmacro/dos_2_unix.sas";
%include "/devel/klebeta/LDP-524/common/code/sas/sasmacro/attrib_std_vars_assay.sas";

%macro PRD07_get_assay_results(network=, protocol=, file_name_orig=, file_name_clean=,
                               file_subno=, file_dir=, labid=, ldms_ds=,
                               out_ds_err=, out_ds_all=);

   %local val_assay val_assay_fmt file delim;
   %let file=&file_dir./&file_name_orig.;

   /*-----------------------------------*/
   /* Set assay file format information */
   /*-----------------------------------*/

   %let val_assay = PRD;
   %let val_assay_fmt = 07;


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
      %check_header(header = Group/Prot GlobalSpecID AssayName AssayDate RunID Drug Conc Units LowerLimit UpperLimit Censors Reviewed,
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
            err_type  length=$10
            err_msg   length=$500
            assaytyp  length=$20  label = "Assay Type"
            assaydtc  length=$20  label = "Assay Date"
            assaydt   length=8    label = "Assay Date" format=date9.
            runid     length=$20  label = "Run ID"
            drug      length=$20  label = "Drug"
            concc     length=$20  label = "Drug concentration"
            conc      length=8    label = "Drug concentration" format=std_miss.
            lloqc     length=$10  label = "Lower Limit of Quantitation"
            lloq      length=8    label = "Lower Limit of Quantitation" format=std_miss.
            uloqc     length=$10  label = "Upper Limit of Quantitation"
            uloq      length=8    label = "Upper Limit of Quantitation" format=std_miss.
            concunit  length=$20  label = "Drug concentration units"
            censor    length=$20  label = "LDMS censor code"
            review    length=$10  label = "Reviewed"
            inputdata length=$100 label = "Original Input Value for Logic Branching"
         ;


         /* Specify the file to input */
         /*---------------------------*/
         infile "&file." lrecl=1000 dsd dlm=&delim. truncover firstobs=2;

         /* Read in the file */
         /*------------------*/
         input prot guspec1 assaytyp assaydtc runid drug concc concunit lloqc uloqc censor review blank_col;

         /* Delete records where all input values are missing */
         /* (ignoring data read in errors)                    */
         /*---------------------------------------------------*/
         if _ERROR_ ne 1 then do;
            array nn {*} _NUMERIC_;
            array cc {*} _CHARACTER_;
            if cmiss(of _all_) < dim(nn) + dim(cc);
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

         /* Input and clean standard variables */
         /*------------------------------------*/
         /* Input standard variables from character to numeric fields */
         %input_visit(char_var=visitnoc, num_var=visitno);
         %input_visit_df(ldms_var=visitno, df_var=visit);
         %input_date(var_list=spcdt);

         /* Input the PK Timepoint Information */
         pk_tp = input(strip(scan(pktime, 1, " ")), ??best.);
         pkucode = input(input(upcase(strip(scan(pktime, 2, " "))), $inpkunits.), ??best.);

         /* Clean standard variables */
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
         /* The file format specifies that not detected is a valid result value with the same meaning as censor code B */
         if missing(censor) and upcase(strip(concc))="NOT DETECTED" then censor="B";
         if censor = "B" or censor = "N" then conc = .L;
         else if censor = "A" then conc = .G;
         else if censor = "S" then conc = .S;
         else if censor in ("C" "E" "I" "K" "Q") then conc = .T;
         else if missing(censor) then conc = input(strip(concc), ??comma10.);

         /* Input lower and upper limit variables into numeric */
         lloq = input(strip(lloqc), ??comma10.);
         uloq = input(strip(uloqc), ??comma10.);

         /* Input the assay date */
         %input_date(var_list=assaydt)

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
                      miss_vars=ptid visitno spcdt spctm primstr addstr dervst2 sec_typ sec_id spctm volume volstr,
                      search_vars=guspec,
                      source_dataset=&ldms_ds.)


      /*----------------------------------------------------------*/
      /* Set the specimen code based on the information from LDMS */
      /*----------------------------------------------------------*/

      data &out_ds_all.;
         set &out_ds_all.;

         /* Set the CRF-style visit number */
        %input_visit_df(ldms_var=visitno, df_var=visit)

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

%mend PRD07_get_assay_results;
***** End of Program *****;
options mprint symbolgen;
%PRD07_get_assay_results(network=mtn, protocol=034, file_name_orig=MTN034_PRD07_B4_20190516E001_B.ttx, file_name_clean=MTN034_PRD07_B4_20190516E001,
                               file_subno=1, file_dir=/devel/klebeta/LDP-524/mtn/protocols/034/data/assay/incoming/test_data/, labid=B4, ldms_ds=csdb.mtn,
                               out_ds_err=temp_raw_file_err, out_ds_all=temp_raw_file);
