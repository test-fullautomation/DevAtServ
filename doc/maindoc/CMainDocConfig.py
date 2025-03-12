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
# CMainDocConfig.py
#
# XC-HWP/ESW3-Queckenstedt
#
# 22.11.2023
#
# --------------------------------------------------------------------------------------------------------------

"""
Python module containing the configuration for the RobotFramework AIO documentation.
This includes the repository configuration and command line values.
"""

# --------------------------------------------------------------------------------------------------------------

import os, sys, time, platform, json, argparse
import colorama as col

from robot.version import get_full_version

from PythonExtensionsCollection.String.CString import CString
from PythonExtensionsCollection.File.CFile import CFile
from PythonExtensionsCollection.Utils.CUtils import *

col.init(autoreset=True)
COLBR = col.Style.BRIGHT + col.Fore.RED
COLBG = col.Style.BRIGHT + col.Fore.GREEN
COLBY = col.Style.BRIGHT + col.Fore.YELLOW
COLNY = col.Style.NORMAL + col.Fore.YELLOW
COLBW = col.Style.BRIGHT + col.Fore.WHITE

SUCCESS = 0
ERROR   = 1
# --------------------------------------------------------------------------------------------------------------

def printerror(sMsg):
    sys.stderr.write(COLBR + f"Error: {sMsg}!\n")

# --------------------------------------------------------------------------------------------------------------

class CMainDocConfig():

   def __init__(self, oRepositoryConfig=None):
      """
Constructor of class ``CMainDocConfig``.

Responsible for:

* Take over the repository configuration
* Read the MainDoc configuration from json file
* Resolve placeholders used in MainDoc configuration
* Prepare runtime variables

* ``oRepositoryConfig``

  / *Condition*: required / *Type*: CRepositoryConfig() /

  GenMainDoc configuration containing static and dynamic configuration values (this includes the
  Repository configuration).
      """

      sMethod = "CMainDocConfig.__init__"

      self.__dictMainDocConfig = None  # self.__dictConfig

      if oRepositoryConfig is None:
         bSuccess = None
         sResult  = "oRepositoryConfig is None"
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # initialize the documentation build configuration (later containing also the repository configuration (with placeholders resolved)
      # and the command line parameters)
      self.__dictMainDocConfig = {}

      # get repository configuration
      dictRepositoryConfig = oRepositoryConfig.GetConfig()

      # take over keys and values from repository configuration
      for key, value in dictRepositoryConfig.items():
         self.__dictMainDocConfig[key] = value

      # get command line
      try:
         self.GetCmdLine()
      except Exception as reason:
         bSuccess = None
         sResult  = str(reason)
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # read the documentation build configuration from separate json file, provided in command line
      MAINDOC_CONFIGFILE = self.__dictMainDocConfig['MAINDOC_CONFIGFILE']
      if MAINDOC_CONFIGFILE is None:
         # --configfile missed in command line
         bSuccess = None
         sResult  = f"Maindoc configuration file not defined. Use '--configfile' in command line."
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # -- the absolute path that is reference for relative paths to configuration files in command line of genmaindoc.py
      sReferencePathAbs_configfile = self.__dictMainDocConfig['REFERENCEPATH'] # set initially in repository config and already normalized
      MAINDOC_CONFIGFILE = CString.NormalizePath(sPath=MAINDOC_CONFIGFILE, sReferencePathAbs=sReferencePathAbs_configfile)
      self.__dictMainDocConfig['MAINDOC_CONFIGFILE'] = MAINDOC_CONFIGFILE # update config
      if os.path.isfile(MAINDOC_CONFIGFILE) is False:
         bSuccess = None
         sResult  = f"Maindoc configuration file '{MAINDOC_CONFIGFILE}' does not exist"
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      print(COLNY + f"Maindoc configuration: '{MAINDOC_CONFIGFILE}'")
      print()

      # -- check framework bundle information (but argparse already should have prevented missing parameters)

      # BUNDLE_NAME, BUNDLE_VERSION and BUNDLE_VERSION_DATE taken from command line (and not from any config file or source file)

      BUNDLE_NAME = self.__dictMainDocConfig['BUNDLE_NAME']
      if ( (BUNDLE_NAME is None) or (BUNDLE_NAME == "") ):
         # framework bundle_name missed in command line
         bSuccess = None
         sResult  = f"Framework bundle name not defined. Use '--bundle_name' in command line."
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      BUNDLE_VERSION = self.__dictMainDocConfig['BUNDLE_VERSION']
      if ( (BUNDLE_VERSION is None) or (BUNDLE_VERSION == "") ):
         # framework bundle_version missed in command line
         bSuccess = None
         sResult  = f"Framework bundle version not defined. Use '--bundle_version' in command line."
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      BUNDLE_VERSION_DATE = self.__dictMainDocConfig['BUNDLE_VERSION_DATE']
      if ( (BUNDLE_VERSION_DATE is None) or (BUNDLE_VERSION_DATE == "") ):
         # framework bundle_version_date missed in command line
         bSuccess = None
         sResult  = f"Framework bundle version date not defined. Use '--bundle_version_date' in command line."
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # -- platform check
      sPlatformSystem = platform.system()
      if sPlatformSystem == "Windows":
         # currently nothing specific to do
         pass
      elif sPlatformSystem == "Linux":
         # currently nothing specific to do
         pass
      else:
         bSuccess = None
         sResult  = f"Platform system '{sPlatformSystem}' is not supported"
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # The json file may contain lines that are commented out by a '#' at the beginning of the line.
      # Therefore we read in this file in text format, remove the comments and parse the result with json.loads().

      oJsonFileSource = CFile(MAINDOC_CONFIGFILE)
      listLines, bSuccess, sResult = oJsonFileSource.ReadLines(bSkipBlankLines=True, sComment='#')
      del oJsonFileSource
      if bSuccess is not True:
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      dictJsonValues = None
      try:
         dictJsonValues = json.loads("\n".join(listLines))
      except Exception as reason:
         bSuccess = None
         sResult  = str(reason) + f" - while parsing JSON content of '{MAINDOC_CONFIGFILE}'"
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      if dictJsonValues is None:
         bSuccess = None
         sResult  = "dictJsonValues is None"
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # take over keys and values from maindocumentation build configuration
      for key, value in dictJsonValues.items():
         self.__dictMainDocConfig[key] = value

      # -- check mandatory parameter from genmaindoc configuration file
      listMandatoryParameters = ["CONTROL", "IMPORTS", "BOOKSOURCES", "MAINTEXFILENAME", "JOBNAME", "PROXY", "TEX"]
      for sParameter in listMandatoryParameters:
         if sParameter not in self.__dictMainDocConfig:
            bSuccess = None
            sResult  = f"Parameter '{sParameter}' is missing in configuration file '{MAINDOC_CONFIGFILE}'. Please add"
            raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # add current timestamp
      self.__dictMainDocConfig['NOW'] = time.strftime('%d.%m.%Y - %H:%M:%S')

      # For normalization of all relative paths inside JSON configuration files we need an absolute reference path.
      # The reference for all relative paths inside JSON configuration files is the position of the selected configuration file.
      sReferencePathAbs = os.path.dirname(MAINDOC_CONFIGFILE)

      # normalize paths in 'IMPORTS' section
      listImports = []
      for sImport in self.__dictMainDocConfig['IMPORTS']:
         sImport = CString.NormalizePath(sPath=sImport, sReferencePathAbs=sReferencePathAbs)
         listImports.append(sImport)
      self.__dictMainDocConfig['IMPORTS'] = listImports

      # normalize path in 'BOOKSOURCES' section
      self.__dictMainDocConfig['BOOKSOURCES'] = CString.NormalizePath(sPath=self.__dictMainDocConfig['BOOKSOURCES'], sReferencePathAbs=sReferencePathAbs)

      # -- prepare path to LaTeX interpreter
      sLaTeXInterpreter = None
      sKey = sPlatformSystem.upper()
      if sKey in self.__dictMainDocConfig['TEX']:
         sLaTeXInterpreter = CString.NormalizePath(sPath=self.__dictMainDocConfig['TEX'][sKey], sReferencePathAbs=sReferencePathAbs)
      self.__dictMainDocConfig['LATEXINTERPRETER'] = sLaTeXInterpreter

      # add version of underlying Robot Framework (core)
      self.__dictMainDocConfig['ROBFWVERSION'] = get_full_version('Robot Framework')

      # debug only
      # PrettyPrint(self.__dictMainDocConfig, sPrefix="Config")

      self.PrintConfig()

   # eof def __init__(self, oRepositoryConfig=None):

   def __del__(self):
      del self.__dictMainDocConfig

   def GetCmdLine(self):
      """
Gets command line parameter.
      """

      sMethod = "GetCmdLine"

      oCmdLineParser = argparse.ArgumentParser()
      oCmdLineParser.add_argument('--configfile', type=str, help='Path and name of maindoc configuration file')
      oCmdLineParser.add_argument('--bundle_name', type=str, help='The name of the entire framework bundle')
      oCmdLineParser.add_argument('--bundle_version', type=str, help='The version of the entire framework bundle')
      oCmdLineParser.add_argument('--bundle_version_date', type=str, help='The version date of the entire framework bundle')
      oCmdLineParser.add_argument('--simulateonly', action='store_true', help='If True, the LaTeX compiler is switched off; a syntax check only remains in this case. Default: False')

      try:
         oCmdLineArgs = oCmdLineParser.parse_args()
      except SystemExit as reason:
         # (nested exceptions here are a little bit long winded, but it's the only chance to print the argparse exception in red color to console)
         bSuccess = None
         sResult  = "Error in command line: " + str(reason) + "\n\n" + oCmdLineParser.format_help()
         raise Exception(CString.FormatResult(sMethod, bSuccess, sResult))

      # check of command line parameters will be done in constructor (where this method is called), but not here immediately

      MAINDOC_CONFIGFILE = None
      if oCmdLineArgs.configfile is not None:
         MAINDOC_CONFIGFILE = oCmdLineArgs.configfile
         MAINDOC_CONFIGFILE = MAINDOC_CONFIGFILE.strip()
      self.__dictMainDocConfig['MAINDOC_CONFIGFILE'] = MAINDOC_CONFIGFILE

      BUNDLE_NAME = None
      if oCmdLineArgs.bundle_name is not None:
         BUNDLE_NAME = oCmdLineArgs.bundle_name
         BUNDLE_NAME = BUNDLE_NAME.strip()
      self.__dictMainDocConfig['BUNDLE_NAME'] = BUNDLE_NAME

      BUNDLE_VERSION = None
      if oCmdLineArgs.bundle_version is not None:
         BUNDLE_VERSION = oCmdLineArgs.bundle_version
         BUNDLE_VERSION = BUNDLE_VERSION.strip()
      self.__dictMainDocConfig['BUNDLE_VERSION'] = BUNDLE_VERSION

      BUNDLE_VERSION_DATE = None
      if oCmdLineArgs.bundle_version_date is not None:
         BUNDLE_VERSION_DATE = oCmdLineArgs.bundle_version_date
         BUNDLE_VERSION_DATE = BUNDLE_VERSION_DATE.strip()
      self.__dictMainDocConfig['BUNDLE_VERSION_DATE'] = BUNDLE_VERSION_DATE

      SIMULATE_ONLY = False
      if oCmdLineArgs.simulateonly is not None:
         SIMULATE_ONLY = oCmdLineArgs.simulateonly
      self.__dictMainDocConfig['SIMULATE_ONLY'] = SIMULATE_ONLY

   # eof def GetCmdLine(self):

   def PrintConfigDebug(self):
      """
Prints all configuration values to console (debug with PrettyPrint).
      """
      # -- printing configuration to console
      print()
      PrettyPrint(self.__dictMainDocConfig, sPrefix="MainDocConfig")
      print()
   # eof def PrintConfigDebug(self):

   def PrintConfig(self):
      """
Prints all configuration values to console.
      """
      nJust = 30
      print()
      for sKey in self.__dictMainDocConfig:
         print(sKey.rjust(nJust, ' ') + " : " + str(self.__dictMainDocConfig[sKey]))
      print()
   # eof def PrintConfig(self):

   def PrintConfigKeys(self):
      """
Prints all configuration key names to console.
      """
      # -- printing configuration keys to console
      print()
      listKeys = self.__dictMainDocConfig.keys()
      sKeys = "[" + ", ".join(listKeys) + "]"
      print(sKeys)
      print()
   # eof def PrintConfigKeys(self):


   def Get(self, sName=None):
      """
Returns the configuration value belonging to a key name.
      """
      if ( (sName is None) or (sName not in self.__dictMainDocConfig) ):
         print()
         printerror(f"Error: Configuration parameter '{sName}' not existing!")
         # from here it's standard output:
         print("Use instead one of:")
         self.PrintConfigKeys()
         return None # returning 'None' in case of key is not existing !!!
      else:
         return self.__dictMainDocConfig[sName]
   # eof def Get(self, sName=None):


   def GetConfig(self):
      """
Returns the complete configuration dictionary.
      """
      return self.__dictMainDocConfig
   # eof def GetConfig(self):

# eof class CMainDocConfig():

# **************************************************************************************************************


