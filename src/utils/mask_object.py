#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Author: jose Rodriguez
# Date: 09-12-2022
###########################################################

def mask_object(obj, param_list):
   for f in param_list:
      setattr(obj, f, "MASKED VALUE")
   return obj
