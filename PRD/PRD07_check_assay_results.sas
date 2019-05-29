
/*********************************************************************************/
/*                                                                               */
/*  Macro: PRD07_check_assay_results.sas                                         */
/*                                                                               */
/*  Creation Date: 17ARP2019                                                     */
/*                                                                               */
/*  Primary client: LDO                                                          */
/*                                                                               */
/*  Purpose: Process SAS assay data based on the assay/version specifications,   */
/*           identifying problem data values                                     */
/*           Created for QCing PRD (Product Concentration) file format #03 data  */
/*                                                                               */
/*  Location:                                                                    */
/*  /common/code/sas/sasmacro/assay_processing/assay_code/PRD                    */
/*                                                                               */
/*  Author: Kalkidan Lebeta							 */
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
/*  Usage: %PRD07_check_assay_results(assay_data=, out_ds_err=, out_ds_all=)     */
/*                                                                               */
/*  Usage Example:                                                               */
/*     %PRD07_check_assay_results(assay_data=PRD07_new_results,                  */
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


%macro PRD07_check_assay_results(assay_data=, out_ds_err=, out_ds_all=);

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

      /* Set to 1 for non-experimental records (i.e. control, standard, etc.) */
      non_experimental=0;

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
            /* Check missing volume/volume unit information */
            /*----------------------------------------------*/
            if missing(volume) then do;
               problem_code=27;
               problem_text='Unable to lookup sample volume';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "volume") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
            volstr=strip(volstr);
            if missing(volstr) then do;
               problem_code=27;
               problem_text='Unable to lookup sample volume unit';
               if findw(scan(add_miss_value_lookup_error, 2, ":"), "volstr") then do;
                  problem_text=strip(problem_text) || ' - discrepant information in LDMS';
               end;
               output errors_record;
            end;
         end;
      end;
      if not missing(guspec) then do;
         if missing(spcdt) then do;
            problem_code=28;
            problem_text='Could not determine the time point value from the collection time point: "' || strip(guspec) || '"';
            output errors_record;
         end;
      end;
      if missing(ptid) then do;
         problem_code=27;
         problem_text='Unable to lookup Participant ID';
         if findw(scan(add_miss_value_lookup_error, 2, ":"), "ptid") then do;
         	problem_text=strip(problem_text) || ' - discrepant information in LDMS';
         end;
         output errors_record;
      end;
      if missing(primstr) then do;
         compare_exp=0;
         problem_code=27;
         problem_text='Missing primary specimen type';
         output errors_record;
      end;
      if missing(addstr) then do;
         compare_exp=0;
         problem_code=27;
         problem_text='Missing specimen additive type';
         output errors_record;
      end;
      if missing(dervst2) then do;
         compare_exp=0;
         problem_code=27;
         problem_text='Missing specimen derivative type';
         output errors_record;
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
      if missing(assaydtc) then do;
         problem_code=27;
         problem_text='Missing assay date';
         output errors_record;
      end;
      else if missing(assaydt) then do;
         compare_exp=0;
         problem_code=28;
         problem_text='Invalid assay date: "' || strip(assaydtc) || '"';
         output errors_record;
      end;
      else do;
         if not missing(spcdt) and assaydt<spcdt then do;
            problem_code=28;
            problem_text='Assay Date "' || strip(vvalue(assaydt)) || '" is Before Collection Date "' ||  strip(vvalue(spcdt)) || '"';
            output errors_record;
         end;
         if assaydt>today() then do;
            problem_code=28;
            problem_text='Assay Date "' || strip(vvalue(assaydt)) || '" is After Todays Date';
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
      /* If the record should be ignored but there was a concentration (ignoring BLQ results) */
      if ignore_record = 1 then do;
         if conc ne .L and not missing(input(strip(concc), ??comma10.)) then do;
            problem_code=28;
            problem_text='Concentration not expected for ignored results (censor code "' || strip(censor) || '")';
            output errors_record;
         end;
      end;
      /* If there is not a numeric concentration or a missing value code */
      else if conc=. then do;
         %let valid_list = 'B' 'A' 'O' 'S' 'Z';
         if not missing(compress(censor, "LPRU")) then do;
            if compress(censor, "FHIMQ") ne censor then do;
               problem_code=28;
               problem_text='Censor code "' || strip(censor) || '" is in file format but has not been coded for yet.';
               output errors_record;
            end;
            if not missing(compress(censor, "LPRUFHIMQ")) then do;
               problem_code=28;
               problem_text='Invalid censor code: "' || strip(censor) || '". Valid codes are: ' || "&valid_list.";
               output errors_record;
            end;
         end;
         /* Allow missing concentrations for records flagged with censor code P */
         else if censor = compress(censor, "P") then do;
            if missing(concc) then do;
               problem_code=27;
               problem_text='Missing concentration or censor code';
               output errors_record;
            end;
            else do;
               problem_code=28;
               problem_text='Non-numeric concentration "' || strip(concc) || '"';
               output errors_record;
            end;
         end;
      end;
      else do;
         /* If there was a missing value code */
         if missing(conc) then do;
            if not (conc in (.L .G)) then do;
               if not missing(input(strip(concc), ??comma10.)) then do;
                  problem_code=28;
                  problem_text='Concentration not expected for results with censor code "' || strip(censor) || '"';
                  output errors_record;
               end;
            end;
            else do;
               if conc = .L then do;
                  if not missing(input(strip(concc), ??comma10.)) and input(strip(concc), ??comma10.) ne 0 then do;
                     problem_code=28;
                     problem_text='Concentration not expected for results with censor code "' || strip(censor) || '"';
                     output errors_record;
                  end;
               end;
               if missing(concunit) then do;
                  problem_code=27;
                  problem_text='Missing concentration unit';
                  output errors_record;
               end;
            end;
         end;
         /* If there was a numeric concentration */
         else do;
            if missing(concunit) then do;
               problem_code=27;
               problem_text='Missing concentration unit';
               output errors_record;
            end;
            if conc<0 then do;
               problem_code=28;
               problem_text='Concentration "' || strip(concc) || '" is less than zero';
               output errors_record;
            end;
         end;
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

%mend PRD07_check_assay_results;

***** End of Program *****;
