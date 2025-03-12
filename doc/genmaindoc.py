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
# genmaindoc.py
#
# XC-HWP/ESW3-Queckenstedt
#
# --------------------------------------------------------------------------------------------------------------
#
# 30.08.2022
#
# --------------------------------------------------------------------------------------------------------------

import os, sys

import colorama as col

from config.CRepositoryConfig import CRepositoryConfig # providing repository and environment specific information
from maindoc.CMainDocConfig import CMainDocConfig      # providing main documentation specific information
from maindoc.CDocBuilder import CDocBuilder

col.init(autoreset=True)

COLBR = col.Style.BRIGHT + col.Fore.RED
COLBY = col.Style.BRIGHT + col.Fore.YELLOW
COLBG = col.Style.BRIGHT + col.Fore.GREEN

SUCCESS = 0
ERROR   = 1
WARNING_PDF_NOT_COMPLETE = 2

# --------------------------------------------------------------------------------------------------------------

def printerror(sMsg):
    sys.stderr.write(COLBR + f"Error: {sMsg}!\n")

def printexception(sMsg):
    sys.stderr.write(COLBR + f"Exception: {sMsg}!\n")

# --------------------------------------------------------------------------------------------------------------

# -- setting up the repository configuration (relative to the path of this script)
oRepositoryConfig = None
try:
    oRepositoryConfig = CRepositoryConfig(os.path.abspath(sys.argv[0]))
except Exception as ex:
    print()
    printexception(str(ex))
    print()
    sys.exit(ERROR)

# -- setting up the maindoc configuration
oMainDocConfig = None
try:
    oMainDocConfig = CMainDocConfig(oRepositoryConfig)
except Exception as ex:
    print()
    printexception(str(ex))
    print()
    sys.exit(ERROR)

# -- setting up and calling the doc builder
try:
    oDocBuilder = CDocBuilder(oMainDocConfig)
except Exception as ex:
    print()
    printexception(str(ex))
    print()
    sys.exit(ERROR)

bPDFIsComplete, bSuccess, sResult = oDocBuilder.Build()
if bSuccess is None:
    print()
    printexception(sResult)
    print()
    sys.exit(ERROR)
elif bSuccess is False:
    print()
    printerror(sResult)
    print()
    sys.exit(ERROR)
elif bSuccess is True:
   # bSuccess is True means: PDF has been generated; but even so the PDF can be incomplete (e.g. meta information is missing)
   if bPDFIsComplete is True:
      print(COLBY + sResult)
      print()
      print(COLBG + "genmaindoc done")
      print()
      sys.exit(SUCCESS)
   else:
      print(COLBY + sResult)
      print()
      print(COLBY + "genmaindoc done - but with warnings")
      print()
      sys.exit(WARNING_PDF_NOT_COMPLETE)
else:
    print()
    printerror("Internal genmaindoc error")
    print()
    sys.exit(ERROR)


# --------------------------------------------------------------------------------------------------------------

