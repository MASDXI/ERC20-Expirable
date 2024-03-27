


## Simple Summary

An expiration token extension standard interface for ERC20 tokens

## Abstract

This extenstion standard provides expiration feature.

## Motivation

An extension standard allows to create tokens with expiration date like loyalty that backward complatibitie with ERC20 interface.

## Specification

To create fungible tokens that have abilities to expiration like loyalty reward is 
challege due to the limitation of smart contract concept that every block has block gas limit how to preventing the transaction of   contract hits the block gas limit while compatible with existing ERC20 standard interface.

##### Requirement: 
- [ ] Compatible with existing ERC20 standard.
- [ ] Configuration expiration period can be change.
- [ ] Configuration block period can be change.
- [ ] Auto select nearly expiration token when transfer as default.
- [ ] Auto look back spendable balance.

#### Era and Slot

`Era` defination  
similar idea fo page in pagination

`Slot` defination
similar idea of index in each page of pagination
** frist index of slot is 0
| Number of Slot | Era cycle mapping to Slot |
|------|--------------------------|
| 1    | 0 Era cycle, 1 Slot      |
| 2    | 0 Era cycle, 2 Slot      |
| 3    | 0 Era cycle, 3 Slot      |
| 4    | 1 Era cycle, 0 Slot      | 
| 5    | 1 Era cycle, 1 Slot      | 
| 6    | 1 Era cycle, 2 Slot      | 
| 7    | 1 Era cycle, 3 Slot      |
| 8    | 2 Era cycle, 0 Slot      | 

