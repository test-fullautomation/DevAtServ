# **************************************************************************************************************
#
#  Copyright 2020-2024 Robert Bosch GmbH
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# **************************************************************************************************************
#
# CDocBuilder.py
#
# XC-HWP/ESW3-Queckenstedt
#
# 22.11.2023
#
# --------------------------------------------------------------------------------------------------------------

"""
Python module containing all methods to generate the main documentation.
"""

# --------------------------------------------------------------------------------------------------------------

import os, sys, time, json, shlex, subprocess, platform, shutil, re
import colorama as col
import pypandoc

from PythonExtensionsCollection.String.CString import CString
from PythonExtensionsCollection.File.CFile import CFile
from PythonExtensionsCollection.Folder.CFolder import CFolder
from PythonExtensionsCollection.Utils.CUtils import *

col.init(autoreset=True)
COLBR = col.Style.BRIGHT + col.Fore.RED
COLBG = col.Style.BRIGHT + col.Fore.GREEN
COLBY = col.Style.BRIGHT + col.Fore.YELLOW
COLBW = col.Style.BRIGHT + col.Fore.WHITE

SUCCESS = 0
ERROR   = 1

# --------------------------------------------------------------------------------------------------------------
#TM***

class CDocBuilder():
   """
Main class ,,,

Method to execute: ``Build()``
   """

   def __init__(self, oMainDocConfig=None):
      """
Constructor of class ``CDocBuilder``.

* ``oMainDocConfig``

  / *Condition*: required / *Type*: CMainDocConfig() /

  Main documentation configuration containing static and dynamic configuration values.
      """

      sMethod = "CDocBuilder.__init__"

      self.__bPDFIsComplete = True

      if oMainDocConfig is None:
         bSuccess = None
         sResult  = "oMainDocConfig is None"
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      self.__dictMainDocConfig = oMainDocConfig.GetConfig()

   # eof def __init__(self, oMainDocConfig=None):

   def __del__(self):
      pass

   # --------------------------------------------------------------------------------------------------------------
   #TM***

   def __GetRepositoryList(self):
      """Returns a list of repositories whose documentation shall be added to the main documentation.
      """

      sMethod = "CDocBuilder.__GetRepositoryList"

      bSuccess = None
      sResult  = "UNKNOWN"

      listRepositories = []
      nNrOfRepositories = 0

      listRepositories = self.__dictMainDocConfig['IMPORTS']
      nNrOfRepositories = len(listRepositories)

      bSuccess = True
      sResult  = f"Number of repositories: {nNrOfRepositories}"

      return listRepositories, bSuccess, sResult

   # eof def __GetRepositoryList(self):

   # --------------------------------------------------------------------------------------------------------------
   #TM***

   def __GetConfig(self, listConfigFiles=[]):
      """Returns a dictionary with some assorted configuration values taken out of the collected repository configurations
      """

      sMethod = "CDocBuilder.__GetConfig"

      bSuccess = None
      sResult  = "UNKNOWN"

      listofdictConfig = []

      if len(listConfigFiles) == 0:
         bSuccess = True # empty list is not an error
         sResult  = "No config files available"
         return listofdictConfig, bSuccess, sResult

      listSupportedKeys = []
      listSupportedKeys.append('REPOSITORYNAME')
      listSupportedKeys.append('PACKAGENAME')
      listSupportedKeys.append('AUTHOR')
      listSupportedKeys.append('AUTHOREMAIL')
      listSupportedKeys.append('DESCRIPTION')
      listSupportedKeys.append('URL')
      listSupportedKeys.append('PACKAGEVERSION')
      listSupportedKeys.append('PACKAGEDATE')

      for sConfigFile in listConfigFiles:

         dictConfig = {}
         hConfigFile = open(sConfigFile)
         dictRepositoryConfig = json.load(hConfigFile)
         hConfigFile.close()
         del hConfigFile
         for sKey in listSupportedKeys:
            if sKey in dictRepositoryConfig:
               dictConfig[sKey] = dictRepositoryConfig[sKey]
         listofdictConfig.append(dictConfig)

      # eof for sConfigFile in listConfigFiles:

      nNrOfConfigs = len(listofdictConfig)

      bSuccess = True
      sResult  = f"Configuration values collected from {nNrOfConfigs} repositories."

      return listofdictConfig, bSuccess, sResult

   # eof def __GetConfig(self, listConfigFiles=[]):

   # --------------------------------------------------------------------------------------------------------------
   #TM***

   def __PrepareOverviewFiles(self, listofdictConfig=[]):
      """Writes some overview files containing some assorted configuration values taken out of the collected repository configurations
      """

      sMethod = "CDocBuilder.__PrepareOverviewFiles"

      bSuccess = None
      sResult  = "UNKNOWN"

      # -- 1. LaTeX version

      # -- get and prepare framework bundle information (values prepared for LaTeX output)

      # BUNDLE_NAME, BUNDLE_VERSION and BUNDLE_VERSION_DATE taken from command line (and not from any config file or source file)

      BUNDLE_NAME         = self.__dictMainDocConfig['BUNDLE_NAME'].replace('_',r'\_') # LaTeX requires this masking
      BUNDLE_VERSION      = self.__dictMainDocConfig['BUNDLE_VERSION'].replace('_',r'\_') # LaTeX requires this masking
      BUNDLE_VERSION_DATE = self.__dictMainDocConfig['BUNDLE_VERSION_DATE'].replace('_',r'\_') # LaTeX requires this masking

      sExternalDocFolder = self.__dictMainDocConfig['EXTERNALDOCFOLDER']
      sOverviewFileName_tex = "library_doc_overview.tex"
      sOverviewFile_tex = f"{sExternalDocFolder}/{sOverviewFileName_tex}"
      self.__dictMainDocConfig['OVERVIEWFILE_TEX'] = sOverviewFile_tex
      oOverviewFile_tex = CFile(sOverviewFile_tex)
      oOverviewFile_tex.Write(f"% Generated at {self.__dictMainDocConfig['NOW']}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\chapter{Library documentation}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(f"The following sections contain the documentation of additional libraries that are part of the {BUNDLE_NAME}.")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\vspace{2ex}")
      oOverviewFile_tex.Write()

      oOverviewFile_tex.Write(r"\begin{center}")

      # -- print bundle information at the top of the list of package informations

      oOverviewFile_tex.Write(r"{\Large\textbf{" + f"{BUNDLE_NAME}" + " bundle}}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\vspace{2ex}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\begin{tabular}{| m{44em} |}\hline")
      oOverviewFile_tex.Write(f"   Version {BUNDLE_VERSION} (from {BUNDLE_VERSION_DATE})" + r"\\ \hline")
      oOverviewFile_tex.Write(r"\end{tabular}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\vspace{2ex}")
      oOverviewFile_tex.Write()

      # -- print information about underlying Robot Framework (core)

      ROBFWVERSION = self.__dictMainDocConfig['ROBFWVERSION']

      oOverviewFile_tex.Write(r"\vspace{2ex}")

      oOverviewFile_tex.Write(r"{\Large\textbf{Underlying Robot Framework (core)}}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\vspace{2ex}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\begin{tabular}{| m{44em} |}\hline")
      oOverviewFile_tex.Write(f"{ROBFWVERSION}" + r"\\ \hline")
      oOverviewFile_tex.Write(r"\end{tabular}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\vspace{2ex}")
      oOverviewFile_tex.Write()

      # -- print information about included packages

      oOverviewFile_tex.Write(r"\vspace{2ex}")

      oOverviewFile_tex.Write(r"{\Large\textbf{Included libraries}}")
      oOverviewFile_tex.Write()
      oOverviewFile_tex.Write(r"\vspace{2ex}")
      oOverviewFile_tex.Write()
      for dictConfig in listofdictConfig:
         PACKAGENAME = dictConfig['PACKAGENAME'].replace('_',r'\_') # LaTeX requires this masking
         DESCRIPTION = dictConfig['DESCRIPTION'].replace('_',r'\_') # LaTeX requires this masking
         oOverviewFile_tex.Write(r"\begin{tabular}{| m{44em} |}\hline")
         oOverviewFile_tex.Write(r"   \textbf{" + PACKAGENAME + r"}\\ \hline")
         oOverviewFile_tex.Write(r"   Version " + dictConfig['PACKAGEVERSION'] + " (from " + dictConfig['PACKAGEDATE'] + r")\\ \hline")
         oOverviewFile_tex.Write(r"   " + dictConfig['URL'] + r"\\ \hline")
         oOverviewFile_tex.Write(r"   \textit{" + DESCRIPTION + r"}\\ \hline")
         oOverviewFile_tex.Write(r"\end{tabular}")
         oOverviewFile_tex.Write()
         oOverviewFile_tex.Write(r"\vspace{2ex}")
         oOverviewFile_tex.Write()
      # eof for dictConfig in listofdictConfig:

      oOverviewFile_tex.Write(r"\end{center}")
      oOverviewFile_tex.Write()

      del oOverviewFile_tex

      # -- 2. RST version

      # get framework bundle information (again, but without LaTeX masking)
      BUNDLE_NAME         = self.__dictMainDocConfig['BUNDLE_NAME']
      BUNDLE_VERSION      = self.__dictMainDocConfig['BUNDLE_VERSION']
      BUNDLE_VERSION_DATE = self.__dictMainDocConfig['BUNDLE_VERSION_DATE']

      sExternalDocFolder = self.__dictMainDocConfig['EXTERNALDOCFOLDER']
      sOverviewFileName_rst = "Components.rst"
      sOverviewFile_rst = f"{sExternalDocFolder}/{sOverviewFileName_rst}"
      self.__dictMainDocConfig['OVERVIEWFILE_RST'] = sOverviewFile_rst
      oOverviewFile_rst = CFile(sOverviewFile_rst)

      oOverviewFile_rst.Write(f"**{BUNDLE_NAME} bundle**")
      oOverviewFile_rst.Write()

      # -- print bundle information at the top of the list of package informations

      # BUNDLE_NAME, BUNDLE_VERSION and BUNDLE_VERSION_DATE taken from command line (and not from any config file or source file)

      oOverviewFile_rst.Write(f"* ``{BUNDLE_NAME}``")
      oOverviewFile_rst.Write()
      oOverviewFile_rst.Write(f"  Version: {BUNDLE_VERSION} (from {BUNDLE_VERSION_DATE})")
      oOverviewFile_rst.Write()

      # -- print information about underlying Robot Framework (core)

      ROBFWVERSION = self.__dictMainDocConfig['ROBFWVERSION']
      oOverviewFile_rst.Write(f"* Underlying ``Robot Framework`` (core)")
      oOverviewFile_rst.Write()
      oOverviewFile_rst.Write(f"  {ROBFWVERSION}")
      oOverviewFile_rst.Write()

      # -- print information about included packages

      oOverviewFile_rst.Write(f"**{BUNDLE_NAME} components listing**")
      oOverviewFile_rst.Write()

      for dictConfig in listofdictConfig:
         PACKAGENAME = dictConfig['PACKAGENAME']
         DESCRIPTION = dictConfig['DESCRIPTION']
         oOverviewFile_rst.Write(f"* ``{PACKAGENAME}``")
         oOverviewFile_rst.Write()
         oOverviewFile_rst.Write(f"  - Version: {dictConfig['PACKAGEVERSION']} (from {dictConfig['PACKAGEDATE']})")
         oOverviewFile_rst.Write(f"  - URL: {dictConfig['URL']}")
         oOverviewFile_rst.Write(f"  - *{dictConfig['DESCRIPTION']}*")
         oOverviewFile_rst.Write()
      # eof for dictConfig in listofdictConfig:

      oOverviewFile_rst.Write()

      del oOverviewFile_rst

      # -- 3. HTML version

      # get framework bundle information (again, but without LaTeX masking)
      BUNDLE_NAME         = self.__dictMainDocConfig['BUNDLE_NAME']
      BUNDLE_VERSION      = self.__dictMainDocConfig['BUNDLE_VERSION']
      BUNDLE_VERSION_DATE = self.__dictMainDocConfig['BUNDLE_VERSION_DATE']

      ROBFWVERSION = self.__dictMainDocConfig['ROBFWVERSION']

      sExternalDocFolder = self.__dictMainDocConfig['EXTERNALDOCFOLDER']
      sOverviewFileName_html = "Components.html"
      sOverviewFile_html = f"{sExternalDocFolder}/{sOverviewFileName_html}"
      self.__dictMainDocConfig['OVERVIEWFILE_HTML'] = sOverviewFile_html
      oOverviewFile_html = CFile(sOverviewFile_html)

      sHeader = """<html><head>
<meta http-equiv="content-type" content="text/html; charset=windows-1252">
   <meta name="####BUNDLE_NAME####" content="Component Overview">
   <title>####BUNDLE_NAME#### Component Overview</title>
</head>
<body vlink="#000000" text="#000000" link="#000000" bgcolor="#FFFFFF" alink="#000000">
<hr width="100%" color="#FF8C00" align="center">
<div align="center">
<font size="6" face="Arial" color="#595959">
<b>
####BUNDLE_NAME####<br>Component Overview
</b></font>
</div>
<hr width="100%" color="#FF8C00" align="center">

<div>&nbsp;</div>

<div align="center">

<table frame="box" rules="all" valign="middle" width="1100" cellspacing="0" cellpadding="6" border="1" align="center">
<colgroup>
   <col width="30%" span="1">
   <col width="70%" span="1">
</colgroup>
<tbody>
"""

      sFooter = """</tbody></table></div>
<div>&nbsp;</div>
<hr width="100%" color="#FF8C00" align="center">
<div align="center"><font size="2" color="#27408B">Generated: ####TIMESTAMP####</font></div>
<div>&nbsp;</div>
</body></html>
"""

      COL1 = "#FFA07A"
      COL2 = "#FFEFD5"
      COL3 = "#F0FFF0"
      COL4 = "#F0F8FF"

      sHeader = sHeader.replace("####BUNDLE_NAME####", BUNDLE_NAME)
      oOverviewFile_html.Write(sHeader)
      oOverviewFile_html.Write()

      oOverviewFile_html.Write(f"<tr bgcolor=\"{COL1}\"><td><font face=\"Arial\" color=\"#000000\" size=\"2\"><b>{BUNDLE_NAME} bundle</b></font></td><td><font face=\"Arial\" color=\"#000000\" size=\"2\"><b>Version: {BUNDLE_VERSION} (from {BUNDLE_VERSION_DATE})</b></font></td></tr>")
      oOverviewFile_html.Write(f"<tr bgcolor=\"{COL2}\"><td><font face=\"Arial\" color=\"#000000\" size=\"2\"><b>Robot Framework core</b></font></td><td><font face=\"Arial\" color=\"#000000\" size=\"2\">{ROBFWVERSION}</font></td></tr>")

      COL = COL3
      for dictConfig in listofdictConfig:
         PACKAGENAME    = dictConfig['PACKAGENAME']
         PACKAGEVERSION = dictConfig['PACKAGEVERSION']
         PACKAGEDATE    = dictConfig['PACKAGEDATE']
         DESCRIPTION    = dictConfig['DESCRIPTION']
         URL            = dictConfig['URL']
         oOverviewFile_html.Write(f"<tr><td rowspan=\"3\" bgcolor=\"{COL}\"><font face=\"Arial\" color=\"#000000\" size=\"2\"><b>{PACKAGENAME}</b></font></td><td bgcolor=\"{COL}\"><font face=\"Arial\" color=\"#000000\" size=\"2\">Version: {PACKAGEVERSION} (from {PACKAGEDATE})</font></td></tr>")
         oOverviewFile_html.Write(f"<tr><td bgcolor=\"{COL}\"><font face=\"Arial\" color=\"#000000\" size=\"2\"><i>{DESCRIPTION}</i></font></td></tr>")
         oOverviewFile_html.Write(f"<tr><td bgcolor=\"{COL}\"><font face=\"Arial\" color=\"#0000FF\" size=\"2\"><a href = \"{URL}\" target=\"_blank\">{URL}</a></font></td></tr>")
         oOverviewFile_html.Write()
         if COL == COL3:
            COL = COL4
         else:
            COL = COL3
      # eof for dictConfig in listofdictConfig:

      sFooter = sFooter.replace("####TIMESTAMP####", self.__dictMainDocConfig['NOW'])
      oOverviewFile_html.Write(sFooter)
      oOverviewFile_html.Write()

      del oOverviewFile_html

      bSuccess = True
      sResult  = f"Overview files written:\n* '{sOverviewFile_tex}'\n* '{sOverviewFile_rst}'\n* '{sOverviewFile_html}'"

      return bSuccess, sResult

   # eof def __PrepareOverviewFiles(self, listofdictConfig=[]):

   # --------------------------------------------------------------------------------------------------------------
   #TM***

   def Build(self):
      """
**Arguments:**

(*no arguments*)

**Returns:**

* ``bSuccess``

  / *Type*: bool /

  Indicates if the computation  was successful or not.

* ``sResult``

  / *Type*: str /

  The result of the computation.
      """

      sMethod = "CDocBuilder.Build"
      bSuccess = False
      sResult  = "UNKNOWN"

      listRepositories, bSuccess, sResult = self.__GetRepositoryList()
      if bSuccess is not True:
         return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

      sBookSourcesFolder = self.__dictMainDocConfig['BOOKSOURCES']
      if not os.path.isdir(sBookSourcesFolder):
         bSuccess = False
         sResult  = f"The input folder '{sBookSourcesFolder}' does not exist."
         return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

      # compute files and subfolders
      sMainTexFileName = self.__dictMainDocConfig['MAINTEXFILENAME']
      sMainTexFile     = f"{sBookSourcesFolder}/{sMainTexFileName}"
      if os.path.isfile(sMainTexFile) is False:
         bSuccess = False
         sResult  = f"The main tex file '{sMainTexFile}' does not exist."
         return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

      self.__dictMainDocConfig['MAINTEXFILE'] = sMainTexFile
      sExternalDocFolder = f"{sBookSourcesFolder}/externaldocs"
      self.__dictMainDocConfig['EXTERNALDOCFOLDER'] = sExternalDocFolder

      oExternalDocFolder = CFolder(sExternalDocFolder)
      bSuccess, sResult = oExternalDocFolder.Create(bOverwrite=True)
      del oExternalDocFolder
      if bSuccess is not True:
         return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

      sPython            = self.__dictMainDocConfig['PYTHON']
      bStrict            = self.__dictMainDocConfig['CONTROL']['STRICT']
      bUpdateExternalDoc = self.__dictMainDocConfig['CONTROL']['UPDATE_EXTERNAL_DOC']

      # iterate the list of repositories and call the package doc generator inside these repositories,
      # redirect the PDF destination to the output folders used to build the main documentation
      listPDFFiles = []
      listConfigFiles = []

      if bUpdateExternalDoc is True:

         # In case of someone only wants to see the outcome of changes in the manually maintained part of the tex sources,
         # the rendering of all external documents (the automatically generated part) can be suppressed
         # (with "UPDATE_EXTERNAL_DOC" : false; see maindoc_config.json). This saves time.

         for sRepository in listRepositories:

            if os.path.isdir(sRepository) is False:
               bSuccess = False
               sResult  = f"The repository folder '{sRepository}' does not exist"
               return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

            sRepositoryName = os.path.basename(sRepository)
            sDestinationFolder = f"{sExternalDocFolder}/{sRepositoryName}"
            oDestinationFolder = CFolder(sDestinationFolder)
            bSuccess, sResult = oDestinationFolder.Create(bOverwrite=True)
            del oDestinationFolder
            if bSuccess is not True:
               return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

            sDocumentationBuilder = f"{sRepository}/genpackagedoc.py"
            if os.path.isfile(sDocumentationBuilder) is False:
               bSuccess = False
               sResult  = f"The package doc generator '{sDocumentationBuilder}' does not exist"
               return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

            # create command line and execute the documentation builder
            listCmdLineParts = []
            listCmdLineParts.append(f"\"{sPython}\"")
            listCmdLineParts.append(f"\"{sDocumentationBuilder}\"")
            listCmdLineParts.append(f"--pdfdest=\"{sDestinationFolder}\"")
            listCmdLineParts.append(f"--configdest=\"{sDestinationFolder}\"")
            listCmdLineParts.append(f"--strict {bStrict}")
            if self.__dictMainDocConfig['SIMULATE_ONLY'] is True:
               listCmdLineParts.append(f"--simulateonly")
            sCmdLine = " ".join(listCmdLineParts)
            del listCmdLineParts
            listCmdLineParts = shlex.split(sCmdLine)
            # -- debug
            sCmdLine = " ".join(listCmdLineParts)
            print()
            print("Now executing command line:\n" + sCmdLine)
            print()
            nReturn = ERROR
            try:
               nReturn = subprocess.call(listCmdLineParts)
            except Exception as ex:
               bSuccess = None
               sResult  = str(ex)
               return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
            if nReturn != SUCCESS:
               bSuccess = False
               sResult  = f"Documentation builder returns error {nReturn}"
               return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

            # We need to identify the name of some output files inside sDestinationFolder:
            # - PDF file (documentation of package in current repository)
            # - JSON file (configuration values of current repository and documentation build process)
            sPDFFile = None
            sJsonFile = None
            listLocalEntries = os.listdir(sDestinationFolder)
            for sEntryName in listLocalEntries:
               if sEntryName.lower().endswith('.pdf'):
                  sPDFFile = CString.NormalizePath(os.path.join(sDestinationFolder, sEntryName))
               if sEntryName.lower().endswith('.json'):
                  sJsonFile = CString.NormalizePath(os.path.join(sDestinationFolder, sEntryName))

            # not available in simulation mode
            if self.__dictMainDocConfig['SIMULATE_ONLY'] is False:
               if sPDFFile is None:
                  bSuccess = False
                  sResult  = f"PDF file not found within '{sDestinationFolder}'"
                  return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
               listPDFFiles.append(sPDFFile)

            if sJsonFile is None:
               bSuccess = False
               sResult  = f"Json configuration file not found within '{sDestinationFolder}'"
               return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
            listConfigFiles.append(sJsonFile)
         # eof for sRepository in listRepositories:

         # get some assorted configuration values out of the configuration files collected from repositories
         listofdictConfig, bSuccess, sResult = self.__GetConfig(listConfigFiles)
         if bSuccess is not True:
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
         else:
            print(sResult)
            print()

         # prepare some overview files containing some assorted configuration values taken out of the collected repository configurations
         bSuccess, sResult = self.__PrepareOverviewFiles(listofdictConfig)
         if bSuccess is not True:
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
         else:
            print(sResult)
            print()

         # create the import tex file to import the library documentations into the main documentation
         sLibraryDocImportTexFile = f"{sExternalDocFolder}/library_doc_imports.tex"
         oLibraryDocImportTexFile = CFile(sLibraryDocImportTexFile)
         oLibraryDocImportTexFile.Write(f"% Generated at {self.__dictMainDocConfig['NOW']}")
         oLibraryDocImportTexFile.Write("%")
         oLibraryDocImportTexFile.Write("% This document imports the documentation of additional libraries into the main documentation.")
         oLibraryDocImportTexFile.Write("%")
         oLibraryDocImportTexFile.Write(r"% The split of the \includepdf for a single PDF file is a workaround to avoid a linebreak after the section heading")
         oLibraryDocImportTexFile.Write(r"% (one \newpage too much within pdfpages.sty).")
         oLibraryDocImportTexFile.Write("%")
         oLibraryDocImportTexFile.Write()
         for sPDFFile in listPDFFiles:
            if not sPDFFile.startswith(sBookSourcesFolder):
               bSuccess = False
               sResult  = f"The PDF file '{sPDFFile}' is not located within the folder structure of '{sBookSourcesFolder}'. It is not possible to compute a relative path to this PDF file."
               return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

            sHeadline = os.path.basename(sPDFFile)[:-4] # name of pdf file without extension
            # the path to the PDF file to be imported, must be relative to the position of the main tex file,
            # and this means also that the PDF must be created within a subfolder of the folder containing the main tex file
            sHeadline = sHeadline.replace('_',r'\_') # LaTeX requires this masking

            sPDFRelPath = "." + sPDFFile[len(sBookSourcesFolder):]
            oLibraryDocImportTexFile.Write(r"\includepdf[pages=1,pagecommand=\section{" + sHeadline + "}]{" + sPDFRelPath + "}")
            oLibraryDocImportTexFile.Write(r"\includepdf[width=\textwidth,frame=true,pages=2-,pagecommand={}]{" + sPDFRelPath + "}")
         # eof for sPDFFile in listPDFFiles:
         del oLibraryDocImportTexFile

      # eof if bUpdateExternalDoc is True:

      else:

         # Import of external documentation not wanted. Therefore we create two dummy files to avoid LaTeX compilation errors
         # of the main tex document.

         self.__bPDFIsComplete = False

         sOverviewFile = f"{sExternalDocFolder}/library_doc_overview.tex"
         oOverviewFile = CFile(sOverviewFile)
         oOverviewFile.Write(f"% Generated at {self.__dictMainDocConfig['NOW']}")
         oOverviewFile.Write()
         oOverviewFile.Write("\chapter{Overview not available}")
         oOverviewFile.Write()
         sOutputMessage = r"{\Large\textcolor{red}{\textbf{\textit{Overview of external documentations is deactivated}}}}"
         oOverviewFile.Write(sOutputMessage)
         oOverviewFile.Write()
         del oOverviewFile

         sLibraryDocImportTexFile = f"{sExternalDocFolder}/library_doc_imports.tex"
         oLibraryDocImportTexFile = CFile(sLibraryDocImportTexFile)
         oLibraryDocImportTexFile.Write(f"% Generated at {self.__dictMainDocConfig['NOW']}")
         oLibraryDocImportTexFile.Write()
         oLibraryDocImportTexFile.Write("\chapter{Imports not available}")
         oLibraryDocImportTexFile.Write()
         sOutputMessage = r"{\Large\textcolor{red}{\textbf{\textit{Import of external documentations is deactivated}}}}"
         oLibraryDocImportTexFile.Write(sOutputMessage)
         oLibraryDocImportTexFile.Write()
         del oLibraryDocImportTexFile

      # eof else - if bUpdateExternalDoc is True:

      # -- Create another tex file containing a list of installed Python modules

      sPythonModulesTexFile = f"{sExternalDocFolder}/python_modules_installed.tex"
      oPythonModulesTexFile = CFile(sPythonModulesTexFile)
      oPythonModulesTexFile.Write(f"% Generated at {self.__dictMainDocConfig['NOW']}")
      oPythonModulesTexFile.Write("%")
      oPythonModulesTexFile.Write(r"\chapter{Appendix}") # in case of more content is added to appendix, this headline should be moved to outside this tex file
      oPythonModulesTexFile.Write(r"\section{Installed Python Modules}")
      oPythonModulesTexFile.Write("This chapter contains a list of installed Python modules together with their version numbers.")
      oPythonModulesTexFile.Write()
      oPythonModulesTexFile.Write(r"\vspace{2ex}")
      oPythonModulesTexFile.Write()
      oPythonModulesTexFile.Write(f"Based on: Python {sys.version}")
      oPythonModulesTexFile.Write()
      oPythonModulesTexFile.Write(r"\vspace{2ex}")
      oPythonModulesTexFile.Write()
      listofTuplesPackages, bSuccess, sResult = CUtils.GetInstalledPackages()
      oPythonModulesTexFile.Write(f"{sResult}")
      if bSuccess is not True:
         self.__bPDFIsComplete = False
      else:
         oPythonModulesTexFile.Write(r"\vspace{2ex}")
         oPythonModulesTexFile.Write(r"\begin{multicols}{3}")
         for tuplePackage in listofTuplesPackages:
            sName    = tuplePackage[0]
            sName    = sName.replace('_',r'\_') # LaTeX requires this masking
            sVersion = tuplePackage[1]
            oPythonModulesTexFile.Write(f"{sName} : {sVersion}" + r"\newline")
         oPythonModulesTexFile.Write(r"\end{multicols}")
      oPythonModulesTexFile.Write()

      sAdditionalInstallationHints = """\\vspace{2ex}

Additionally required Python packages can be installed in this way:

\\vspace{2ex}

1. Windows:

\\begin{pythoncode}
"%RobotPythonPath%/python.exe" -m pip install --proxy ###PROXY### <<packagename>>
\\end{pythoncode}

\\vspace{2ex}

2. Linux:

\\begin{pythoncode}
"${RobotPythonPath}/python3" -m pip install --proxy ###PROXY### <<packagename>>
\\end{pythoncode}

\\vspace{2ex}

The full path and name of the Python interpreter is required in these command lines because the \\textbf{RobotFramework AIO} installer does not modify the environment of the computer (except the setup of some environment variables).

The proxy address is an option and depends on the conditions under which your company grants the access to the internet.

"""

      # take over the concrete proxy address defined in the genmaindoc configuration file
      PROXY = self.__dictMainDocConfig['PROXY']
      sAdditionalInstallationHints = sAdditionalInstallationHints.replace("###PROXY###", PROXY)
      oPythonModulesTexFile.Write(f"{sAdditionalInstallationHints}")

      del oPythonModulesTexFile

      # -- Create another tex file containing the version and the date of the entire framework bundle.
      #    The values are part of the bundle information (currently defined within environment variables).
      #    This new tex file is imported in the main tex file and ensures that that the main documentation
      #    contains in the title page a version number and a date that is up to date.

      BOOKSOURCES = self.__dictMainDocConfig['BOOKSOURCES']
      sBundleVersionDateTeXFile = f"{BOOKSOURCES}/BundleVersionDate.tex"
      self.__dictMainDocConfig['BUNDLEVERSIONDATETEXFILE'] = sBundleVersionDateTeXFile

      COVERSHEETSUFFIX = None # is optional
      if "COVERSHEETSUFFIX" in self.__dictMainDocConfig:
         COVERSHEETSUFFIX = self.__dictMainDocConfig['COVERSHEETSUFFIX']
         COVERSHEETSUFFIX = COVERSHEETSUFFIX.strip()
         if COVERSHEETSUFFIX == "":
            COVERSHEETSUFFIX = None

      # -- get and prepare framework bundle information (values prepared for LaTeX output)

      # BUNDLE_NAME, BUNDLE_VERSION and BUNDLE_VERSION_DATE taken from command line (and not from any config file or source file)

      BUNDLE_NAME         = self.__dictMainDocConfig['BUNDLE_NAME'].replace('_',r'\_') # LaTeX requires this masking
      BUNDLE_VERSION      = self.__dictMainDocConfig['BUNDLE_VERSION'].replace('_',r'\_') # LaTeX requires this masking
      BUNDLE_VERSION_DATE = self.__dictMainDocConfig['BUNDLE_VERSION_DATE'].replace('_',r'\_') # LaTeX requires this masking

      oBundleVersionDateTeXFile = CFile(sBundleVersionDateTeXFile)
      oBundleVersionDateTeXFile.Write(f"% Generated at {self.__dictMainDocConfig['NOW']}")
      oBundleVersionDateTeXFile.Write()
      oBundleVersionDateTeXFile.Write(r"\title{\textbf{Specification of \\")
      oBundleVersionDateTeXFile.Write(r"\vspace{2ex}")
      oBundleVersionDateTeXFile.Write(f"{BUNDLE_NAME} \\\\")
      oBundleVersionDateTeXFile.Write(r"\vspace{2ex}")

      if COVERSHEETSUFFIX is None:
         oBundleVersionDateTeXFile.Write(f"v. {BUNDLE_VERSION}" + "}}")
      else:
         oBundleVersionDateTeXFile.Write(f"v. {BUNDLE_VERSION} \\\\")
         oBundleVersionDateTeXFile.Write(r"\vspace{2ex}")
         oBundleVersionDateTeXFile.Write(f"{COVERSHEETSUFFIX}" + "}}")
         oBundleVersionDateTeXFile.Write()

      oBundleVersionDateTeXFile.Write(r"\date{\vspace{4ex}\textbf{" + BUNDLE_VERSION_DATE + "}}")
      oBundleVersionDateTeXFile.Write()
      del oBundleVersionDateTeXFile

      # derive name of expected PDF file out of the job name
      JOBNAME = self.__dictMainDocConfig['JOBNAME']
      sPDFFileName = f"{JOBNAME}.pdf"
      sPDFFileExpected = f"{sBookSourcesFolder}/{sPDFFileName}"
      self.__dictMainDocConfig['PDFFILEEXPECTED'] = sPDFFileExpected

      # PDF file will also be copied to the package folder, from there it will be installed to Python site-packages
      sPackageFolder = f"{self.__dictMainDocConfig['REFERENCEPATH']}/{self.__dictMainDocConfig['PACKAGENAME']}"
      sPDFFileDestination = f"{sPackageFolder}/{sPDFFileName}"
      self.__dictMainDocConfig['PDFFILEDESTINATION'] = sPDFFileDestination

      # create final summary about document creation
      sPDFFileName_masked = sPDFFileName.replace('_', r'\_') # LaTeX requires this masking
      sFinalSummaryFile = f"{sExternalDocFolder}/final_summary.tex"
      oFinalSummaryFile = CFile(sFinalSummaryFile)
      oFinalSummaryFile.Write(f"% Generated at {self.__dictMainDocConfig['NOW']}")
      oFinalSummaryFile.Write()
      oFinalSummaryFile.Write(r"\vfill")
      oFinalSummaryFile.Write(r"\begin{center}")
      oFinalSummaryFile.Write(r"\begin{tabular}{m{16em}}\hline")
      oFinalSummaryFile.Write(r"   \multicolumn{1}{c}{\textbf{" + f"{sPDFFileName_masked}" + r"}}\\")
      oFinalSummaryFile.Write(r"   \multicolumn{1}{c}{\textit{Created at " + self.__dictMainDocConfig['NOW'] + r"}}\\")
      oFinalSummaryFile.Write(r"   \multicolumn{1}{c}{\textit{by genmaindoc v. " + self.__dictMainDocConfig['VERSION'] + r"}}\\ \hline")
      oFinalSummaryFile.Write(r"\end{tabular}")
      oFinalSummaryFile.Write(r"\end{center}")
      oFinalSummaryFile.Write()
      del oFinalSummaryFile

      # --------------------------------------------------------------------------------------------------------------
      # The code after the following if statement only belongs to the LaTeX compiler building the PDF.
      # In simulation mode we skip this part completely.
      # --------------------------------------------------------------------------------------------------------------
      if self.__dictMainDocConfig['SIMULATE_ONLY'] is True:
         print()
         print(COLBY + "GenMainDoc is running in simulation mode.")
         print(COLBY + "Skipping call of LaTeX compiler. No new PDF output will be generated, already existing output will not be updated!")
         print(COLBY + "! This is not handled as error and also not handled as warning !")
         print()
         bSuccess = True
         sResult  = f"Generation of PDF output skipped because of simulation mode!"
         self.__bPDFIsComplete = True # not nice, but otherwise a warning will be thrown in main function; in simulation mode we do not want to have a statement about the PDF output
         return self.__bPDFIsComplete, bSuccess, sResult

      # --------------------------------------------------------------------------------------------------------------

      # convert main tex file to PDF
      sLaTeXInterpreter = self.__dictMainDocConfig['LATEXINTERPRETER']
      if os.path.isfile(sLaTeXInterpreter) is False:
         # consider strictness regarding availability of LaTeX compiler
         bStrict = self.__dictMainDocConfig['CONTROL']['STRICT']
         print()
         print(COLBR + f"Missing LaTeX compiler '{sLaTeXInterpreter}'!")
         print()
         if bStrict is True:
            bSuccess = False
            sResult  = f"Generating the documentation in PDF format not possible because of missing LaTeX compiler ('strict' mode)!"
            sResult = CString.FormatResult(sMethod, bSuccess, sResult)
         else:
            bSuccess = True
            sResult  = f"Generating the documentation in PDF format not possible because of missing LaTeX compiler ('non strict' mode)!"
         return self.__bPDFIsComplete, bSuccess, sResult

      # start the compiler
      listCmdLineParts = []
      listCmdLineParts.append(f"\"{sLaTeXInterpreter}\"")

      JOBNAME = self.__dictMainDocConfig['JOBNAME']
      listCmdLineParts.append(f"-jobname=\"{JOBNAME}\"")
      listCmdLineParts.append(f"\"{sMainTexFile}\"")

      sCmdLine = " ".join(listCmdLineParts)
      del listCmdLineParts
      listCmdLineParts = shlex.split(sCmdLine)

      # -- debug
      sCmdLine = " ".join(listCmdLineParts)
      print()
      print("Now executing command line:\n" + sCmdLine)
      print()

      for nDummy in range(2): # call LaTeX compiler 2 times to get TOC and index lists updated properly
         cwd = os.getcwd() # we have to save cwd because later we have to change
         nReturn = ERROR
         try:
            os.chdir(sBookSourcesFolder) # otherwise LaTeX compiler is not able to find files inside
            nReturn = subprocess.call(listCmdLineParts)
            print()
            print(f"LaTeX compiler returned {nReturn}")
            print()
            os.chdir(cwd) # restore original value
         except Exception as ex:
            os.chdir(cwd) # restore original value
            bSuccess = None
            sResult  = str(ex)
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
         if nReturn != SUCCESS:
            bSuccess = False
            sResult  = f"LaTeX compiler not returned expected value {SUCCESS}"
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
      # eof for nDummy in range(2):

      # -- verify the outcome
      if os.path.isfile(sPDFFileExpected) is False:
         bSuccess = False
         sResult  = f"Expected PDF file '{sPDFFileExpected}' not generated"
         return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

      oPDFFile = CFile(sPDFFileExpected)
      bSuccess, sResult = oPDFFile.CopyTo(sPDFFileDestination, bOverwrite=True)
      del oPDFFile
      if bSuccess is not True:
         return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
      print(COLBY + f"* PDF file: {sPDFFileDestination}")
      print()

      if "OVERVIEWFILE_RST" in self.__dictMainDocConfig:
         # in case of "UPDATE_EXTERNAL_DOC" is false, "OVERVIEWFILE_RST" is not available; therefore nothing to copy to the package folder
         OVERVIEWFILE_RST = self.__dictMainDocConfig['OVERVIEWFILE_RST']
         if os.path.isfile(OVERVIEWFILE_RST) is False:
            bSuccess = False
            sResult  = f"Expected overview file '{OVERVIEWFILE_RST}' not generated"
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

         sOverviewFileName = os.path.basename(OVERVIEWFILE_RST)
         sOverviewFile_dest = f"{sPackageFolder}/{sOverviewFileName}"
         oOverviewFile = CFile(OVERVIEWFILE_RST)
         bSuccess, sResult = oOverviewFile.CopyTo(sOverviewFile_dest, bOverwrite=True)
         del oOverviewFile
         if bSuccess is not True:
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
         print(COLBY + f"* Overview: {sOverviewFile_dest}")
         print()
      # eof if "OVERVIEWFILE_RST" in self.__dictMainDocConfig:

      if "OVERVIEWFILE_HTML" in self.__dictMainDocConfig:
         # in case of "UPDATE_EXTERNAL_DOC" is false, "OVERVIEWFILE_HTML" is not available; therefore nothing to copy to the package folder
         OVERVIEWFILE_HTML = self.__dictMainDocConfig['OVERVIEWFILE_HTML']
         if os.path.isfile(OVERVIEWFILE_HTML) is False:
            bSuccess = False
            sResult  = f"Expected overview file '{OVERVIEWFILE_HTML}' not generated"
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)

         sOverviewFileName = os.path.basename(OVERVIEWFILE_HTML)
         sOverviewFile_dest = f"{sPackageFolder}/{sOverviewFileName}"
         oOverviewFile = CFile(OVERVIEWFILE_HTML)
         bSuccess, sResult = oOverviewFile.CopyTo(sOverviewFile_dest, bOverwrite=True)
         del oOverviewFile
         if bSuccess is not True:
            return self.__bPDFIsComplete, bSuccess, CString.FormatResult(sMethod, bSuccess, sResult)
         print(COLBY + f"* Overview: {sOverviewFile_dest}")
         print()
      # eof if "OVERVIEWFILE_HTML" in self.__dictMainDocConfig:

      bSuccess = True

      if self.__bPDFIsComplete is True:
         sResult  = "Main documentation generated"
      else:
         sResult  = "Main documentation generated - but PDF file is incomplete"

      return self.__bPDFIsComplete, bSuccess, sResult

   # eof def Build(self):

   # --------------------------------------------------------------------------------------------------------------

# eof class CDocBuilder():

# --------------------------------------------------------------------------------------------------------------
