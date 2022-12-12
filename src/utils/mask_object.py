#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: jose Rodriguez
# Date: 09-12-2022
###########################################################

from utils import setupLogger
from copy import deepcopy

def mask_object(obj, param_list, mask_value = 'MASKED VALUE'):
   logger = setupLogger._setup_logger(__name__)

   work_obj=deepcopy(obj)

   for attribute in param_list:
      if hasattr(work_obj,attribute):
         setattr(work_obj, attribute, mask_value)
         logger.debug("Masking attribute: {}".format(attribute))
      else:
         logger.debug("Masking attribute {} not done. Attribute does not exist.".format(attribute))
      
   return work_obj
