//
//  simd.c
//  simd
//
//  Created by Florian Kugler on 06-08-2019.
//  Copyright © 2019 Florian Kugler. All rights reserved.
//

#include "simd.h"

uint64_t cmp_mask_against_input(simd_input in, uint8_t m) {
    const __m256i mask = _mm256_set1_epi8(m);
    __m256i cmp_res_0 = _mm256_cmpeq_epi8(in.lo, mask);
    uint64_t res_0 = (uint32_t)(_mm256_movemask_epi8(cmp_res_0));
    __m256i cmp_res_1 = _mm256_cmpeq_epi8(in.hi, mask);
    uint64_t res_1 = _mm256_movemask_epi8(cmp_res_1);
    return res_0 | (res_1 << 32);
}

simd_input fill_input(const uint8_t *ptr) {
    struct simd_input in;
    in.lo = _mm256_loadu_si256((const __m256i *)(ptr + 0));
    in.hi = _mm256_loadu_si256((const __m256i *)(ptr + 32));
    return in;
}
