
       // Relic is an open-source package manager created by Liam Allan.
       // It may also go by these names:
       //   - Relic Package Manager
       //   - DWNPKG

       Ctl-Opt DftActGrp(*No) ActGrp(*NEW);

       dcl-pr Cmd int(10) extproc('system');
         cmdstring pointer value options(*string);
       end-pr;
       Dcl-s errmsgid char(7)        import('_EXCP_MSGID');

       Dcl-Pr printf Int(10) ExtProc('printf');
         format Pointer Value Options(*String);
       END-PR;

       Dcl-Pr RelicBuild ExtPgm('BUILD');
         Library Char(10) Const;
       END-PR;

       //*********************************************

       Dcl-C gRepoZip 'REPO.ZIP';
       Dcl-C gWebList 'http://spaces.litmis.com:62178/pkg/';

       Dcl-s INTOLIB   Char(10);

       //*********************************************

       Dcl-Pi RELIC;
         pZIPLocI     Char(128) Const;
         pNewDirI     Char(128) Const;
         pLib         Char(10)  Const;
       END-PI;

       Dcl-Ds gParameters;
         pZIPLoc      Char(128) Pos(1);
         pNewDir      Char(128) Pos(129);
       END-DS;

       *InLR = *On;

       If (%Parms < 3);
         Print('Three parameters required.');
         Return;
       Else;
         pZIPLoc = %Trim(pZIPLocI);
         pNewDir = %Trim(pNewDirI);
       ENDIF;

       If (pLib = *Blank);
         Print('Library cannot be blank.');
         Return;
       ENDIF;

       //*********************************************

       INTOLIB  = pLib;

       Print('Starting package download..');

       BUILD_FromWeb();
       BUILD_Prepare();

       Return;

       //*********************************************

       Dcl-Proc Print;
         Dcl-Pi Print;
           pValue Char(132) Value;
         END-PI;

         pValue = %TrimR(pValue) + x'25';
         printf(%Trim(pValue));
       End-Proc;

       //*********************************************

       //FILE_Download will now just
       //download the repo ZIP to the IFS.
       Dcl-Proc FILE_Download;
         Dcl-Pi *N Ind;
           pLocation Varchar(128) Const; //File
         END-PI;

         Dcl-S lFile SQLTYPE(BLOB_FILE);

         //Will download to Current Directory
         lFile_Name = gRepoZip;
         lFile_NL   = %Len(%TrimR(lFile_Name));
         lFile_FO   = SQFOVR;

         Exec SQL
           SELECT SYSTOOLS.HTTPGETBLOB(:pLocation, '') lFile_DATA
           INTO :lFile
           FROM SYSIBM.SYSDUMMY1;

         Return (SQLSTATE = '00000');

       END-PROC;

       //*********************************************

       Dcl-Proc BUILD_FromWeb;
         Dcl-S lWebResponse SQLTYPE(CLOB:256);
         Dcl-S lURL         Char(128);

         If (%Subst(pZIPLoc:1:4) <> 'http');
           lURL = gWebList + pZIPLoc;

           Exec SQL SET :lWebResponse = SYSTOOLS.HTTPGETCLOB
              (:lURL,'');

           If (lWebResponse_Data <> 'NOEXIST');
             gParameters = lWebResponse_Data;
           Else;
             Print('Failed to find ' + %Trim(pZIPLoc) + ' package.');
           Endif;
         ENDIF;

       END-PROC;

       //*********************************************

       Dcl-Proc BUILD_Prepare;
         Dcl-Pi *N End-Pi;

         If (FILE_Download(pZIPLoc));

           Cmd('QSH CMD(''jar xf ' + gRepoZip + ''')');
           Cmd('RMVLNK OBJLNK(''' + gRepoZip + ''')');

           //Use the new folder incase it extracts into a folder
           If (pNewDir <> *Blank);
             Cmd('CHGCURDIR DIR(''' + %Trim(pNewDir) + ''')');
           ENDIF;

           RelicBuild(pLib);

         Else;
           Print('ZIP download failed.');
         Endif;
       End-Proc;

       //*********************************************