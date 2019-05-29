
/*********************************************************************************/
/*                                                                               */
/*  Macro: attrib_std_vars_assay.sas                                             */
/*                                                                               */
/*  Creation Date: 22AUG2014                                                     */
/*                                                                               */
/*  Primary Client: LDO                                                          */
/*                                                                               */
/*  Purpose: Set variable attributes that are common across assays               */
/*                                                                               */
/*  Location: /common/code/sas/sasmacro/assay_processing                         */
/*                                                                               */
/*  Author: Katie Snapinn                                                        */
/*                                                                               */
/*  Project: HPTN/MTN Assay Processing                                           */
/*           SCHARP                                                              */
/*           Fred Hutchinson Cancer Research Center                              */
/*                                                                               */
/*  Parameters: None                                                             */
/*                                                                               */
/*  Required Code: None                                                          */
/*                                                                               */
/*  Usage: %attrib_std_vars_assay                                                */
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


%macro attrib_std_vars_assay;

   attrib
      /* General variables */
      recnum       length=8    label = "Record number in assay file"
      network      length=$6   label = "Network"
      protocol     length=$6   label = "Protocol number"
      labid        length=$2   label = "Assay Lab Identifier" format=$assay_labid_name.
      network_fn   length=$6   label = "Network from file name"
      protocol_fn  length=$6   label = "Protocol from file name"
      labid_fn     length=$2   label = "Assay Lab Identifier from file name" format=$assay_labid_name.
      prot         length=$10  label = "Protocol information"
      prot2        length=$10  label = "Protocol information"
      guspec       length=$25  label = "Global specimen id"
      guspec1      length=$29  label = "Global specimen id"
      specid       length=$15  label = "LDMS specimen ID"
      ptidc        length=$15  label = "Participant ID"
      ptid         length=8    label = "Participant ID"
      visit        length=8    label = "Visit Code, Assay File (DataFax format)"
      visitnoc     length=$20  label = "Visit Code, Assay File (original value)"
      visitno      length=8    label = "Visit Code, Assay File (LDMS format)"
      spcdtc       length=$20  label = "Specimen collection date"
      spcdt        length=8    label = "Specimen collection date" format=date9.
      spctmc       length=$20  label = "Specimen collection time"
      spctm        length=8    label = "Specimen collection time" format=time.
      pktime       length=$20  label = "Specimen Time Point Text"
      pk_tp        length=8    label = "Specimen Time Point"
      pkucode      length=8    label = "Specimen Time Point Unit" format=pkunits.
      pk_tp_orig   length=8    label = "Specimen Time Point (original value)"
      pkucode_orig length=8    label = "Specimen Time Point Unit (original value)" format=pkunits.
      assayspec    length=$25  label = "All Specimen Type Information in Assay File"
      primstr      length=$5   label = "Primary Specimen Type"
      addstr       length=$5   label = "Additive type"
      dervst2      length=$5   label = "Derivative specimen type"
      sec_id       length=$16  label = "Other specimen ID"
      sec_typ      length=$5   label = "Sub-Additive/Derivative"
      spectype     length=$30  label = "Specimen Type"
      spcode       length=8    label = "Specimen code" format=spectyp.
      spprim       length=8    label = "Specimen Primary Code" format=primnamecrf.
      spalq        length=8    label = "Specimen Aliquot Code" format=spnamecrf.
      sppurp       length=8    label = "Specimen Aliquot Purpose Code" format=specpurp.
      labfile      length=$100 label = "Assay result file (original name)"
      labfilecln   length=$100 label = "Assay result file (std. format, uppercase, no extension)"
      labfilesub   length=8    label = "Assay result file submission number"
      assay        length=$6   label = "Assay" format=$assay_name.
      file_format_version  length=$2   label = "File format version"
      filedate     length=8    label = "Date record added to database" format=date9.
      filetime     length=8    label = "Time record added to database" format=time.
      comments1    length=$500 label = "Laboratory comment"
      comments     length=$200 label = "Laboratory comment"
      blank_col    length=$100 label = "Column should be empty"
      infile_value length=$1000 label = "Infile value"

      /* Error messages */
      problem_code   length=8    label = "Error code" format=ldoqc.
      problem_text   length=$500 label = "Description of error"
      problem_date   length=8    label = "Date the error was identified" format=date9.
      problem_time   length=8    label = "Time the error was identified" format=time.

      /* Flags */
      non_experimental length=8    label = "Non-experimental sample (e.g. control, standard, etc.)? 0=No 1=Yes" format=noyesna.
      compare_exp      length=8    label = "Can the record be compared against CRF data? 0=No 1=Yes" format=noyesna.
      ignore_record    length=8    label = "Should this record be excluded from SRA data (based on data values)? 1=Yes" format=noyesna.
      exclude_record   length=8    label = "Should this record be excluded from SRA data (based on exclusion file)? 0=No 1=Yes" format=noyesna.
      non_enrollee     length=8    label = "Is the result from a non-enrollee? 0=No 1=Yes" format=noyesna.
      inap_enrolled    length=8    label = "Is the result from a participant who was inappropriately enrolled? 0=No 1=Yes" format=noyesna.
   ;

%mend attrib_std_vars_assay;


/***** End of Program *****/
