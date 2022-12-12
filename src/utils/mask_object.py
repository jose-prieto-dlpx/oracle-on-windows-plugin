#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: jose Rodriguez
# Date: 09-12-2022
###########################################################

from utils import setupLogger

def mask_object(obj, param_list, mask_value = 'MASKED VALUE'):
   logger = setupLogger._setup_logger(__name__)

   for attribute in param_list:
      if hasattr(obj,attribute):
         setattr(obj, attribute, mask_value)
         logger.debug("Masking attribute: {}".format(attribute))
      else:
         logger.debug("Masking attribute {} not done. Attribute does not exist.".format(attribute))
      
   return obj
