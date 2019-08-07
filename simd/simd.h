//
//  simd.h
//  simd
//
//  Created by Florian Kugler on 06-08-2019.
//  Copyright © 2019 Florian Kugler. All rights reserved.
//

#ifndef simd_h
#define simd_h

#include <stdio.h>
#include <x86intrin.h>

struct simd_input {
    __m256i lo;
    __m256i hi;
};
typedef struct simd_input simd_input;

simd_input fill_input(const uint8_t *ptr);
uint64_t cmp_mask_against_input(simd_input in, uint8_t m);
uint64_t carryless_multiply(uint64_t x, uint64_t y);

#endif /* simd_h */
