//
//  GrowingAnalytics
//  Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#ifndef fishhook_h
#define fishhook_h

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif 


struct growing_rebinding {
  const char *name;
  void *replacement;
  void **replaced;
};


int growing_rebind_symbols(struct growing_rebinding rebindings[], size_t rebindings_nel);


int growing_rebind_symbols_image(void *header,
                                 intptr_t slide,
                                 struct growing_rebinding rebindings[],
                                 size_t rebindings_nel);

#ifdef __cplusplus
}
#endif 

#endif
