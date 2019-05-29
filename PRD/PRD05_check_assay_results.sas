
/*********************************************************************************/
/*                                                                               */
/*  Macro: PRD05_check_assay_results.sas                                         */
/*                                                                               */
/*  Creation Date: 21OCT2016                                                     */
/*                                                                               */
/*  Primary client: LDO                                                          */
/*                                                                               */
/*  Purpose: Process SAS assay data based on the assay/version specifications,   */
/*           identifying problem data values                                     */
/*           Created for QCing PRD (Product Concentration) file format #05 data  */
/*                                                                               */
/*  Location:                                                                    */
/*  /common/code/sas/sasmacro/assay_processing/assay_code/PRD                    */
/*                                                                               */
/*  Author: Katie Snapinn                                                        */
/*                                                                               */
/*  Project: HPTN/MTN Assay Processing                                           */
/*           SCHARP - Fred Hutchinson Cancer Research Center                     */
/*                                                                               */
/*  Parameters:                                                                  */
/*     assay_data: The SAS dataset of in-putted assay data to QC                 */
/*     out_ds_err: A dataset to save with all data value errors                  */
/*     out_ds_all: A dataset to save the assay data                              */
/*                                                                               */
/*  Inputs:                                                                      */
/*     Datasets:                                                                 */
/*        &assay_data.: The SAS dataset of in-putted assay data to QC            */
/*                                                                               */
/*  Outputs:                                                                     */
/*     Datasets:                                                                 */
/*        &out_ds_err.: A dataset to save with all data value errors             */
/*        &out_ds_all.: A dataset to save the assay data                         */
/*                                                                               */
/*  Required Code:                                                               */
/*     None                                                                      */
/*                                                                               */
/*  Required Formats:                                                            */
/*     None                                                                      */
/*                                                                               */
/*  Usage: %PRD05_check_assay_results(assay_data=, out_ds_err=, out_ds_all=)     */
/*                                                                               */
/*  Usage Example:                                                               */
/*     %PRD05_check_assay_results(assay_data=PRD05_new_results,                  */
/*        out_ds_err=temp_raw_err, out_ds_all=temp_raw_all)                      */
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


%macro PRD05_check_assay_results(assay_data=, out_ds_err=, out_ds_all=);

   %local valid_list;

   /*-------------------*/
   /* QC the assay data */
   /*-------------------*/

   proc sort data=&assay_data.;
      by network_fn protocol_fn assay file_format_version labid_fn labfile labfilecln labfilesub;
   run;
   data &out_ds_all. (drop=problem_code problem_text problem_date problem_time
                           assayspec blank_col prob_netw prob_prot)
        errors_meta (drop=prob_netw prob_prot)
        errors_prot
        errors_prot_all
        errors_record (drop=prob_netw prob_prot);

      retain num_tot num_missprot num_missnetwork num_missprotocol any_blank 0;
      drop num_tot num_missprot num_missnetwork num_missprotocol any_blank add_miss_value_lookup_error;
      set &assay_data.;
      by network_fn protocol_fn assay file_format_version labid_fn labfile labfilecln labfilesub;

      /* Set the counts of the missing network/protocol information per file */
      if first.labfilesub then do;
         num_tot=0;
         num_missprot=0;
         num_missnetwork=0;
         num_missprotocol=0;
         any_blank=0;
      end;

      /* Count the number of records in the file */
      num_tot=num_tot+1;

      /* Set the problem date and time values just incase a problem is identified */
      problem_date = today();
      problem_time = time();

      /* Flag to note if the record can be compared with specimen collection dataset  */
      /* Initialize to 1 and set to 0 for any records with missing information in the */
      /* participant identifier, visit code, specimen collection date, specimen code  */
      /* (and fields used to generate the specimen code), lab acronym, or if          */
      /* applicable, the pk_tp and pkucode fields                                     */
      compare_exp=1;

      /* Check for missing/incorrect network/protocol information */
      /*----------------------------------------------------------*/
      if missing(prot) then do;
         num_missprot=num_missprot+1;
         prob_netw=1;
         prob_prot=1;
         network = network_fn;
         protocol = protocol_fn;
         problem_code=27;
         problem_text='Missing network/protocol. Network defaulted to "' || strip(network_fn) || '" and protocol defaulted to "' || strip(protocol_fn) ||'" based on the file name.';
         output errors_prot;
         /* Output a record if the network/protocol was missing for every record in the file */
         if (last.labfilesub) and (num_missprot = num_tot) then do;
            problem_code=27;
            problem_text='Network/protocol were not provided for any records in the file. All network values defaulted to "' || strip(network_fn) || '" and protocol values defaulted to "' || strip(protocol_fn) ||'" based on the file name.';
            output errors_prot_all;
         end;
      end;
      else do;
         if missing(network) then do;
            prob_netw=1;
            prob_prot=0;
            num_missnetwork=num_missnetwork+1;
            network = network_fn;
            problem_code=27;
            problem_text='Missing network. Network defaulted to "' || strip(network_fn) || '" based on the file name.';
            output errors_prot;
            /* Output a record if the network was missing for every record in the file */
            if (last.labfilesub) and (num_missnetwork = num_tot) then do;
               problem_code=27;
               problem_text='Network was not provided for any records in the file. All network values were defaulted to "' || strip(network_fn) || '" based on the file name.';
               output errors_prot_all;
            end;
         end;
         else if network ne network_fn then do;
            compare_exp=0;
            problem_code=28;
            problem_text='Invalid network: "' || strip(network) || '" provided but "' || strip(network_fn) || '" expected.';
            output errors_record;
         end;

         if missing(protocol) then do;
            prob_netw=0;
            prob_prot=1;
            num_missprotocol=num_missprotocol+1;
            protocol = protocol_fn;
            problem_code=27;
            problem_text='Missing protocol. Protocol defaulted to "' || strip(protocol_fn) || '" based on the file name.';
            output errors_prot;
            /* Output a record if the protocol was missing for every record in the file */
            if (last.labfilesub) and (num_missprotocol = num_tot) then do;
               problem_code=27;
               problem_text='Protocol was not provided for any records in the file. All protocol values were defaulted to "' || strip(protocol_fn) || '" based on the file name.';
               output errors_prot_all;
            end;
         end;
         else if protocol ne protocol_fn then do;
            compare_exp=0;
            problem_code=28;
            problem_text='Invalid protocol: "' || strip(protocol) || '" provided but "' || strip(protocol_fn) || '" expected.';
            output errors_record;
         end;
      end;

      /* Check for missing values in pertinent fields */
      /*----------------------------------------------*/
      if missing(guspec) then do;
         problem_code=27;
         problem_text='Missing Global Specimen ID';
         output errors_record;
      end;
      else do;
         if add_miss_value_lookup_error = "No source information" then do;
            problem_code=28;
            problem_text='Invalid Global Specimen ID: "' || strip(guspec) || '"';
            output errors_record;
         end;
         else do;
            /* Check missing participant information */
            /*---------------------------------------*/
            if missing(ptid) then do;
               problem_code=27;
               problem_text='Unable to lookup Participant ID';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "ptid") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            if missing(visitno) then do;
               problem_code=27;
               problem_text='Unable to lookup visit';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "visitno") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            if missing(spcdt) then do;
               problem_code=27;
               problem_text='Unable to lookup collection date';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "spcdt") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            if findw(scan(add_miss_value_lookup_error, 2, ":"), "spctm") then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup specimen collection time - discrepant information in LDMS';
               output errors_record;
            end;
            if findw(scan(add_miss_value_lookup_error, 2, ":"), "addtim") then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup specimen collection time-point - discrepant information in LDMS';
               output errors_record;
            end;
            else do;
               if addtim >=0 and pk_tp_orig ne addtim then do;
                  compare_exp=0;
                  problem_code=28;
                  problem_text='Invalid specimen collection time-point: "' || strip(put(addtim, best.)) || '"';
                  output errors_record;
               end;
            end;
            if findw(scan(add_miss_value_lookup_error, 2, ":"), "addunt") then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup specimen collection time-point unit - discrepant information in LDMS';
               output errors_record;
            end;
            else do;
               if addunt ne "-2" and not missing(addunt) and missing(pkucode_orig) then do;
                  compare_exp=0;
                  problem_code=28;
                  problem_text='Invalid specimen collection time-point unit: "' || strip(addunt) || '"';
                  output errors_record;
               end;
            end;

            /* Check missing sample information */
            /*----------------------------------*/
            if missing(primstr) then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup primary specimen type';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "primstr") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            if missing(addstr) then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup specimen additive';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "addstr") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            if missing(dervst2) then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup specimen derivative';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "dervst2") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            if missing(sec_typ) then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup specimen sub-additive/derivative';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "sec_typ") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            if findw(scan(add_miss_value_lookup_error, 2, ":"), "sec_id") then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup Other Specimen ID - discrepant information in LDMS';
               output errors_record;
            end;

            /* Check missing volume/volume unit information */
            /*----------------------------------------------*/
            if findw(scan(add_miss_value_lookup_error, 2, ":"), "volume") then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup sample measurement - discrepant information in LDMS';
               output errors_record;
            end;
            if findw(scan(add_miss_value_lookup_error, 2, ":"), "volstr") then do;
               compare_exp=0;
               problem_code=27;
               problem_text='Unable to lookup sample measurement unit - discrepant information in LDMS';
               output errors_record;
            end;
         end;
      end;
      if not (missing(primstr) or missing(addstr) or missing(dervst2) or missing(sec_typ)) then do;
         if missing(spcode) then do;
            compare_exp=0;
            problem_code=28;
            problem_text='Invalid specimen type: "' || strip(spectype) || '"';
            output errors_record;
         end;
      end;
      if missing(labid) then do;
         compare_exp=0;
         problem_code=27;
         problem_text='Missing labid';
         output errors_record;
      end;
      else if labid ne labid_fn then do;
         compare_exp=0;
         problem_code=28;
         problem_text='Invalid labid: "' || strip(labid) || '"';
         output errors_record;
      end;

      /* Check the assay date value */
      /*----------------------------*/
      if missing(assaydt) then do;
         if not missing(assaydtc) then do;
            problem_code=28;
            problem_text='Invalid assay date: "' || strip(assaydtc) || '"';
            output errors_record;
         end;
         else if ignore_record ne 1 then do;
            problem_code=27;
            problem_text='Missing assay date';
            output errors_record;
         end;
      end;
      else do;
         if not missing(spcdt) and assaydt<spcdt then do;
            problem_code=28;
            problem_text='Assay date "' || strip(vvalue(assaydt)) || '" is before collection date "' ||  strip(vvalue(spcdt)) || '"';
            output errors_record;
         end;
         if assaydt>today() then do;
            problem_code=28;
            problem_text='Assay date "' || strip(vvalue(assaydt)) || '" is after todays date';
            output errors_record;
         end;
      end;

      /* Check the reporting date value */
      /*--------------------------------*/
      if missing(reportdt) then do;
         if not missing(reportdtc) then do;
            problem_code=28;
            problem_text='Invalid reporting date: "' || strip(reportdtc) || '"';
            output errors_record;
         end;
         else do;
            problem_code=27;
            problem_text='Missing reporting date';
            output errors_record;
         end;
      end;
      else do;
         if not missing(spcdt) and reportdt<spcdt then do;
            problem_code=28;
            problem_text='Reporting date "' || strip(vvalue(reportdt)) || '" is before collection date "' ||  strip(vvalue(spcdt)) || '"';
            output errors_record;
         end;
         if not missing(assaydt) and reportdt<assaydt then do;
            problem_code=28;
            problem_text='Reporting date "' || strip(vvalue(reportdt)) || '" is before assay date "' ||  strip(vvalue(assaydt)) || '"';
            output errors_record;
         end;
         if reportdt>today() then do;
            problem_code=28;
            problem_text='Reporting date "' || strip(vvalue(reportdt)) || '" is after todays date';
            output errors_record;
         end;
      end;

      /* Check the result values */
      /*-------------------------*/
      if missing(drug) then do;
         problem_code=27;
         problem_text='Missing drug';
         output errors_record;
      end;
      if missing(conc) then do;
         if not missing(concc) then do;
            problem_code=28;
            problem_text='Non-numeric concentration "' || strip(concc) || '"';
            output errors_record;
         end;
         /* Allow missing concentrations for censor code Z (no result) and */
         /* censor code X (testing repeated/sample under investigation) */
         else if ignore_record ne 1 and censor not in ('X') then do;
            problem_code=27;
            problem_text='Missing concentration';
            output errors_record;
         end;
      end;
      else do;
         if conc<0 then do;
            problem_code=28;
            problem_text='Concentration "' || strip(concc) || '" is less than zero';
            output errors_record;
         end;
      end;
      if missing(concunit) then do;
         /* Concunit may be missing for ignored records (from censor code Z, no result) */
         /* and for samples with censor code X (testing repeated/sample under investigation) */
         /* where a concentration has not yet been reported */
         if ignore_record ne 1 and not (censor in ('X') and missing(concc)) then do;
            problem_code=27;
            problem_text='Missing concentration unit';
            output errors_record;
         end;
      end;
      if missing(runid) then do;
         if ignore_record ne 1 then do;
            problem_code=27;
            problem_text='Missing Run ID';
            output errors_record;
         end;
      end;
      %let valid_list = 'X' 'Z';
      if not missing(compress(censor, compress("&valid_list.", "' "))) then do;
         problem_code=28;
         problem_text='Invalid censor code: "' || strip(censor) || '". Valid codes are: ' || "&valid_list.";
         output errors_record;
      end;

      /* Make sure the comments are <= 200 characters */
      /*----------------------------------------------*/
      if strip(comments1) ne strip(comments) then do;
         problem_code=28;
         problem_text='Comment is greater than 200 characters. Some information was truncated';
         output errors_record;
      end;

      /* Make sure there was no data in the column past the last column */
      /* Could be because extra columns were added or that for some     */
      /* reason the delimiters were read in to SAS improperly           */
      /*----------------------------------------------------------------*/
      if not missing(blank_col) then any_blank=any_blank+1;
      if last.labfilesub and any_blank>0 then do;
         problem_code=28;
         problem_text='File contains extra column(s) of data.';
         output errors_meta;
      end;

      /* Save the current data */
      output &out_ds_all.;
   run;

   /* Separate network/protocol errors that occurred in all records from those in just some */
   /*---------------------------------------------------------------------------------------*/
   proc sort data=errors_prot;
      by network_fn protocol_fn assay file_format_version labid_fn
         labfile labfilecln labfilesub prob_netw prob_prot;
   run;
   proc sort data=errors_prot_all;
      by network_fn protocol_fn assay file_format_version labid_fn
         labfile labfilecln labfilesub prob_netw prob_prot;
   run;
   data errors_prot
        errors_prot_all(drop=problem_code problem_text problem_date problem_time
                        rename=(problem_code_all=problem_code problem_text_all=problem_text
                                problem_date_all=problem_date problem_time_all=problem_time));
      drop prob_netw prob_prot;
      merge errors_prot(in=a)
            errors_prot_all(in=b rename=(problem_code=problem_code_all problem_text=problem_text_all
                                         problem_date=problem_date_all problem_time=problem_time_all));
      by network_fn protocol_fn assay file_format_version labid_fn
         labfile labfilecln labfilesub prob_netw prob_prot;
      if b then output errors_prot_all;
      else output errors_prot;
   run;
   proc sort data=errors_prot_all nodupkey;
      by network_fn protocol_fn assay file_format_version labid_fn
         labfile labfilecln labfilesub problem_code problem_text;
   run;

   /* Compile the current errors */
   /*----------------------------*/
   data &out_ds_err.;
      set errors_record
          errors_prot
          errors_meta (keep=problem_code problem_text problem_date problem_time
                            network_fn protocol_fn assay file_format_version labid_fn
                            labfile labfilecln labfilesub)
          errors_prot_all (keep=problem_code problem_text problem_date problem_time
                                network_fn protocol_fn assay file_format_version labid_fn
                                labfile labfilecln labfilesub);
   run;

%mend PRD05_check_assay_results;


***** End of Program *****;
