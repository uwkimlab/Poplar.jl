# Poplar

1. This branch implements maintenance respiration modules based on the PEACH model (Grossman and DeJong, 1993) in the Cropbox-Poplar model. Additionally, it incorporates Populus photosynthetic parameters as outlined by Xu et al. (2020).

2. Added switch for NPP types (1. NPP/GPP ratio; 2. Maintenance respiration rate).
```
sample_config = @config(
  Poplar.Photosynthesis =>(
      NPP_type = 2, # 1 for NPP ratio, 2 for maintenance respiration
  )
);
```

#### References
Grossman Y.L. and DeJong T.M. 1993. PEACH: A simulation model of reproductive and vegetative growth in peach trees, Tree Physiol., 14:329-345, https://doi.org/10.1093/treephys/14.4.329 

Xu Y., Shang B., Feng Z., and Tarvainen L. 2020. Effect of elevated ozone, nitrogen availability and mesophyll conductance on the temperature responses of leaf photosynthetic parameters in poplar, Tree Physiol., 40:484-497, https://doi.org/10.1093/treephys/tpaa007  

[![Build Status](https://github.com/junhyukjeon/Poplar.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/junhyukjeon/Poplar.jl/actions/workflows/CI.yml?query=branch%3Amaster)
